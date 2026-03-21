import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_theme.dart';
import '../services/course_player_service.dart';

class CoursePlayerScreen extends StatefulWidget {
  final int courseId;
  final String courseTitle;

  const CoursePlayerScreen({Key? key, required this.courseId, required this.courseTitle}) : super(key: key);

  @override
  _CoursePlayerScreenState createState() => _CoursePlayerScreenState();
}

class _CoursePlayerScreenState extends State<CoursePlayerScreen> {
  final CoursePlayerService _service = CoursePlayerService();
  bool _isLoading = true;
  
  List<dynamic> _sections = [];
  Map<String, dynamic>? _currentLesson;
  
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  Timer? _progressTimer;

  Map<String, String> _downloadedLessons = {};
  Map<String, double> _downloadProgress = {};
  final Map<String, CancelToken> _cancelTokens = {};

  List<dynamic> get _allLessons {
    List<dynamic> list = [];
    for (var s in _sections) {
      list.addAll(s['lessons'] ?? []);
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    _checkDownloadedFiles();
    _fetchCurriculum();
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _videoController?.dispose();
    _chewieController?.dispose();
    for (var token in _cancelTokens.values) {
      token.cancel();
    }
    super.dispose();
  }

  Future<void> _checkDownloadedFiles() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    Map<String, String> downloads = {};
    for (var key in keys) {
      if (key.startsWith('offline_lesson_')) {
        final lessonId = key.replaceFirst('offline_lesson_', '');
        downloads[lessonId] = prefs.getString(key)!;
      }
    }
    if (mounted) setState(() => _downloadedLessons = downloads);
  }

  Future<void> _fetchCurriculum() async {
    final data = await _service.getCourseDetails(widget.courseId);
    if (mounted) {
      setState(() {
        _sections = data ?? [];
        _isLoading = false;
        if (_allLessons.isNotEmpty) {
          _playLesson(_allLessons.first);
        }
      });
    }
  }

  bool _isYoutubeOrVimeo(String url) {
    return url.contains('youtube.com') || url.contains('youtu.be') || url.contains('vimeo.com');
  }

  Future<void> _playLesson(Map<String, dynamic> lesson) async {
    _progressTimer?.cancel();
    _videoController?.pause();
    _videoController?.dispose();
    _chewieController?.dispose();
    
    setState(() {
      _currentLesson = lesson;
      _videoController = null;
      _chewieController = null;
    });

    String type = lesson['content_type']?.toString() ?? lesson['lesson_type']?.toString() ?? 'video';
    String url = lesson['content']?.toString() ?? lesson['video_url']?.toString() ?? '';
    String lessonIdStr = lesson['id'].toString();

    if (type == 'video' && url.isNotEmpty && !_isYoutubeOrVimeo(url)) {
      // Offline Playback Logic
      if (_downloadedLessons.containsKey(lessonIdStr)) {
        final file = File(_downloadedLessons[lessonIdStr]!);
        if (await file.exists()) {
          _videoController = VideoPlayerController.file(file);
        } else {
          _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
        }
      } else {
        _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
      }

      await _videoController!.initialize();
      
      // Resume from last watched position
      int startSeconds = int.tryParse(lesson['seconds_watched']?.toString() ?? '0') ?? 0;
      if (startSeconds > 0 && startSeconds < _videoController!.value.duration.inSeconds) {
        await _videoController!.seekTo(Duration(seconds: startSeconds));
      }

      setState(() {
        _chewieController = ChewieController(
          videoPlayerController: _videoController!,
          autoPlay: true,
          looping: false,
          allowPlaybackSpeedChanging: true,
          errorBuilder: (context, errorMessage) {
            return Center(child: Text(errorMessage, style: const TextStyle(color: Colors.white)));
          },
        );
      });

      // Background Progress Sync
      _progressTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
        if (_videoController != null && _videoController!.value.isPlaying) {
          _service.saveVideoProgress(
            int.parse(lessonIdStr), 
            _videoController!.value.position.inSeconds.toDouble()
          );
        }
      });
      
      // Auto-Next Logic
      _videoController!.addListener(() {
        if (_videoController!.value.position == _videoController!.value.duration) {
          _playNextLesson();
        }
      });
    }
  }

  void _playNextLesson() {
    if (_currentLesson == null) return;
    final lessons = _allLessons;
    final currentIndex = lessons.indexWhere((l) => l['id'] == _currentLesson!['id']);
    if (currentIndex != -1 && currentIndex < lessons.length - 1) {
      _playLesson(lessons[currentIndex + 1]);
    }
  }

  Future<void> _startDownload(Map<String, dynamic> lesson) async {
    String url = lesson['content']?.toString() ?? lesson['video_url']?.toString() ?? '';
    String lessonIdStr = lesson['id'].toString();
    
    if (url.isEmpty || _isYoutubeOrVimeo(url)) return;

    final dir = await getApplicationDocumentsDirectory();
    final savePath = '${dir.path}/lesson_$lessonIdStr.mp4';
    final cancelToken = CancelToken();

    setState(() {
      _downloadProgress[lessonIdStr] = 0.01;
      _cancelTokens[lessonIdStr] = cancelToken;
    });

    try {
      await Dio().download(
        url,
        savePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _downloadProgress[lessonIdStr] = received / total;
            });
          }
        },
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('offline_lesson_$lessonIdStr', savePath);

      setState(() {
        _downloadProgress.remove(lessonIdStr);
        _cancelTokens.remove(lessonIdStr);
        _downloadedLessons[lessonIdStr] = savePath;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Download Complete'), backgroundColor: Colors.green));
    } catch (e) {
      setState(() {
        _downloadProgress.remove(lessonIdStr);
        _cancelTokens.remove(lessonIdStr);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic Theme Detectors
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final cardColor = isDark ? AppTheme.darkSurfaceColor : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.courseTitle, style: const TextStyle(fontSize: 16)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : Column(
              children: [
                // 1. Player Area (Always Dark)
                Container(
                  width: double.infinity,
                  height: 230,
                  color: Colors.black,
                  child: _buildPlayerArea(),
                ),
                
                // 2. Current Lesson Info
                if (_currentLesson != null)
                  Container(
                    width: double.infinity,
                    color: isDark ? AppTheme.darkBackgroundColor : Colors.white,
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_currentLesson!['title'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                        const SizedBox(height: 4),
                        Text('Now Playing', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600, fontSize: 12)),
                      ],
                    ),
                  ),
                
                Divider(height: 1, color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                
                // 3. Curriculum List
                Expanded(
                  child: Container(
                    color: isDark ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor,
                    child: _buildCurriculum(isDark, textColor, subTextColor, cardColor),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPlayerArea() {
    String type = _currentLesson?['content_type']?.toString() ?? _currentLesson?['lesson_type']?.toString() ?? 'video';
    String url = _currentLesson?['content']?.toString() ?? _currentLesson?['video_url']?.toString() ?? '';
    
    if (type == 'video') {
      if (_isYoutubeOrVimeo(url)) {
        return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text('YouTube/Vimeo playback requires advanced plugins.', style: TextStyle(color: Colors.white70), textAlign: TextAlign.center)));
      }
      if (_chewieController != null && _chewieController!.videoPlayerController.value.isInitialized) {
        return Chewie(controller: _chewieController!);
      }
      if (_videoController != null && _videoController!.value.hasError) {
         return const Center(child: Text('Error loading video. Please check your connection.', style: TextStyle(color: Colors.red)));
      }
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
    } else {
      return const Center(child: Icon(Icons.article, size: 60, color: Colors.white54));
    }
  }

  Widget _buildCurriculum(bool isDark, Color textColor, Color subTextColor, Color cardColor) {
    if (_sections.isEmpty) return Center(child: Text('No curriculum found.', style: TextStyle(color: subTextColor)));

    return ListView.builder(
      itemCount: _sections.length,
      itemBuilder: (context, index) {
        final section = _sections[index];
        final lessons = section['lessons'] as List<dynamic>? ?? [];

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          color: cardColor,
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            initiallyExpanded: index == 0,
            backgroundColor: Colors.transparent,
            collapsedBackgroundColor: Colors.transparent,
            title: Text(section['title'] ?? 'Section', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
            collapsedIconColor: subTextColor,
            iconColor: AppTheme.primaryColor,
            children: lessons.map((lesson) {
              final isPlaying = _currentLesson != null && _currentLesson!['id'] == lesson['id'];
              final isCompleted = lesson['is_completed'] == 1;
              final lessonIdStr = lesson['id'].toString();
              final isDownloaded = _downloadedLessons.containsKey(lessonIdStr);
              final progress = _downloadProgress[lessonIdStr];

              return Container(
                color: isPlaying ? AppTheme.primaryColor.withOpacity(isDark ? 0.2 : 0.1) : Colors.transparent,
                child: ListTile(
                  leading: Icon(
                    isCompleted ? Icons.check_circle : (isPlaying ? Icons.pause_circle_filled : Icons.play_circle_outline),
                    color: isCompleted ? Colors.green : (isPlaying ? AppTheme.primaryColor : subTextColor),
                  ),
                  title: Text(
                    lesson['title'],
                    style: TextStyle(
                      color: isPlaying ? AppTheme.primaryColor : textColor,
                      fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: _buildDownloadTrailing(lesson, isDownloaded, progress, subTextColor),
                  onTap: () => _playLesson(lesson),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget? _buildDownloadTrailing(Map<String, dynamic> lesson, bool isDownloaded, double? progress, Color subTextColor) {
    String type = lesson['content_type']?.toString() ?? lesson['lesson_type']?.toString() ?? 'video';
    String url = lesson['content']?.toString() ?? lesson['video_url']?.toString() ?? '';
    String lessonIdStr = lesson['id'].toString();

    if (type != 'video' || url.isEmpty || _isYoutubeOrVimeo(url)) return null;

    if (isDownloaded) {
      return const Icon(Icons.offline_pin, color: Colors.green, size: 20);
    } else if (progress != null) {
      return SizedBox(
        width: 24, height: 24,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(value: progress, strokeWidth: 2, color: AppTheme.primaryColor),
            IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.close, size: 12, color: Colors.red),
              onPressed: () {
                _cancelTokens[lessonIdStr]?.cancel();
                setState(() => _downloadProgress.remove(lessonIdStr));
              },
            )
          ],
        ),
      );
    } else {
      return IconButton(
        icon: Icon(Icons.download_for_offline, color: subTextColor, size: 24),
        onPressed: () => _startDownload(lesson),
      );
    }
  }
}
