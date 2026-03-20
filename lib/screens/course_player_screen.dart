import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
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
  
  // DYNAMIC Parsing prevents crashes!
  List<dynamic> _sections = [];
  Map<String, dynamic>? _currentLesson;
  
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  Timer? _progressTimer;

  // Offline Download Tracking
  Map<String, String> _downloadedLessons = {};
  Map<String, double> _downloadProgress = {};

  List<dynamic> get _allLessons {
    List<dynamic> list = [];
    for (var s in _sections) {
      list.addAll(s['lessons'] ?? s['items'] ?? []);
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    _loadDownloadedLessons();
    _loadCourseData();
  }

  void _loadDownloadedLessons() async {
    final prefs = await SharedPreferences.getInstance();
    final String? downloadsJson = prefs.getString('offline_downloads');
    if (downloadsJson != null) {
      if (mounted) {
        setState(() {
          Map<String, dynamic> decoded = json.decode(downloadsJson);
          _downloadedLessons = decoded.map((key, value) => MapEntry(key, value.toString()));
        });
      }
    }
  }

  void _loadCourseData() async {
    final data = await _service.getCourseDetails(widget.courseId);
    if (data != null) {
      List<dynamic> parsedSections = [];
      if (data is List) {
        parsedSections = data;
      } else if (data is Map && data.containsKey('sections')) {
        parsedSections = data['sections'];
      } else if (data is Map && data.containsKey('curriculum')) {
        parsedSections = data['curriculum'];
      } else if (data is Map && data.containsKey('data')) {
        parsedSections = data['data'];
      }

      if (mounted) {
        setState(() {
          _sections = parsedSections;
          _isLoading = false;
        });
        if (_allLessons.isNotEmpty) {
          _playLesson(_allLessons.first);
        }
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _isYoutubeOrVimeo(String url) {
    String lowerUrl = url.toLowerCase();
    return lowerUrl.contains('youtube.com') || lowerUrl.contains('youtu.be') || lowerUrl.contains('vimeo.com');
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_currentLesson != null && _videoController != null && _videoController!.value.isPlaying) {
        _service.saveVideoProgress(
          int.parse(_currentLesson!['id'].toString()), 
          _videoController!.value.position.inSeconds.toDouble()
        );
      }
    });
  }

  // --- DOWNLOAD LOGIC RESTORED ---
  void _downloadLesson(dynamic lesson) async {
    String id = lesson['id'].toString();
    String url = lesson['content']?.toString() ?? lesson['video_url']?.toString() ?? '';
    String type = lesson['content_type']?.toString() ?? lesson['lesson_type']?.toString() ?? 'video';
    
    if (type != 'video' || url.isEmpty || _isYoutubeOrVimeo(url)) return;

    setState(() => _downloadProgress[id] = 0.01);

    try {
      if (!url.startsWith('http')) url = 'https://academy.kainuwa.africa/' + url;

      final dir = await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/lesson_$id.mp4';

      final dio = Dio();
      await dio.download(
        url, savePath,
        onReceiveProgress: (received, total) {
          if (total != -1 && mounted) {
            setState(() => _downloadProgress[id] = received / total);
          }
        },
      );

      final prefs = await SharedPreferences.getInstance();
      _downloadedLessons[id] = savePath;
      await prefs.setString('offline_downloads', json.encode(_downloadedLessons));

      if (mounted) {
        setState(() => _downloadProgress.remove(id));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${lesson['title']} downloaded!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _downloadProgress.remove(id));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Download failed.'), backgroundColor: Colors.red));
      }
    }
  }

  void _playLesson(dynamic lesson) async {
    if (_currentLesson != null && _videoController != null) {
      _service.saveVideoProgress(int.parse(_currentLesson!['id'].toString()), _videoController!.value.position.inSeconds.toDouble());
    }

    _progressTimer?.cancel();
    String id = lesson['id'].toString();
    String url = lesson['content']?.toString() ?? lesson['video_url']?.toString() ?? '';
    String type = lesson['content_type']?.toString() ?? lesson['lesson_type']?.toString() ?? 'video';

    setState(() {
      _currentLesson = Map<String, dynamic>.from(lesson);
      if (_chewieController != null) {
        _chewieController!.dispose();
        _chewieController = null;
      }
      if (_videoController != null) {
        _videoController!.dispose();
        _videoController = null;
      }
    });

    if (type == 'video' && url.isNotEmpty) {
      if (!_isYoutubeOrVimeo(url)) {
        
        // CHECK OFFLINE MEMORY FIRST
        if (_downloadedLessons.containsKey(id)) {
          File localFile = File(_downloadedLessons[id]!);
          if (await localFile.exists()) {
             _videoController = VideoPlayerController.file(localFile);
          } else {
             _downloadedLessons.remove(id);
             if (!url.startsWith('http')) url = 'https://academy.kainuwa.africa/' + url;
             _videoController = VideoPlayerController.network(url);
          }
        } else {
          if (!url.startsWith('http')) url = 'https://academy.kainuwa.africa/' + url;
          _videoController = VideoPlayerController.network(url);
        }

        await _videoController!.initialize();

        _chewieController = ChewieController(
          videoPlayerController: _videoController!,
          autoPlay: true,
          looping: false,
          materialProgressColors: ChewieProgressColors(
            playedColor: AppTheme.primaryColor,
            handleColor: AppTheme.primaryColor,
            backgroundColor: Colors.grey.shade800,
            bufferedColor: Colors.grey.shade400,
          ),
        );

        _startProgressTracking();

        _videoController!.addListener(() {
          if (_videoController!.value.isInitialized && !_videoController!.value.isPlaying &&
              _videoController!.value.position >= _videoController!.value.duration && 
              _videoController!.value.position > Duration.zero) {
            _playNextLesson();
          }
        });

        if (mounted) setState(() {});
      }
    }
  }

  void _playNextLesson() {
    if (_currentLesson == null) return;
    final currentIndex = _allLessons.indexWhere((l) => l['id'].toString() == _currentLesson!['id'].toString());
    if (currentIndex >= 0 && currentIndex < _allLessons.length - 1) {
      _playLesson(_allLessons[currentIndex + 1]);
    }
  }

  void _playPrevLesson() {
    if (_currentLesson == null) return;
    final currentIndex = _allLessons.indexWhere((l) => l['id'].toString() == _currentLesson!['id'].toString());
    if (currentIndex > 0) {
      _playLesson(_allLessons[currentIndex - 1]);
    }
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    if (_currentLesson != null && _videoController != null) {
      _service.saveVideoProgress(int.parse(_currentLesson!['id'].toString()), _videoController!.value.position.inSeconds.toDouble());
    }
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Widget _buildDownloadButton(dynamic lesson) {
    String id = lesson['id'].toString();
    String url = lesson['content']?.toString() ?? lesson['video_url']?.toString() ?? '';
    String type = lesson['content_type']?.toString() ?? lesson['lesson_type']?.toString() ?? 'video';

    if (type != 'video' || url.isEmpty || _isYoutubeOrVimeo(url)) return const SizedBox();
    
    if (_downloadedLessons.containsKey(id)) {
      return const Icon(Icons.offline_pin, color: Colors.green);
    }
    
    if (_downloadProgress.containsKey(id)) {
      return SizedBox(
        width: 24, height: 24,
        child: CircularProgressIndicator(value: _downloadProgress[id], strokeWidth: 3, color: AppTheme.primaryColor),
      );
    }
    
    return IconButton(
      icon: const Icon(Icons.download, color: Colors.grey),
      onPressed: () => _downloadLesson(lesson),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: Text(widget.courseTitle, style: const TextStyle(fontSize: 16))),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : Column(
              children: [
                Container(
                  width: double.infinity, height: 230, color: Colors.black,
                  child: _currentLesson == null
                      ? const Center(child: Text('Select a lesson', style: TextStyle(color: Colors.white)))
                      : _buildPlayerArea(),
                ),
                Container(
                  width: double.infinity, padding: const EdgeInsets.all(16), color: Colors.white,
                  child: Text(_currentLesson?['title'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const Divider(height: 1, thickness: 1),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.skip_previous, color: Colors.grey),
                        label: const Text('Previous', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                        onPressed: _playPrevLesson,
                      ),
                      TextButton(
                        onPressed: _playNextLesson,
                        child: Row(
                          children: const [
                            Text('Next', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                            SizedBox(width: 8),
                            Icon(Icons.skip_next, color: Colors.grey),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1),
                Expanded(
                  child: ListView.builder(
                    itemCount: _sections.length,
                    itemBuilder: (context, index) {
                      final section = _sections[index];
                      List items = section['lessons'] ?? section['items'] ?? [];
                      
                      return ExpansionTile(
                        initiallyExpanded: true,
                        title: Text(section['title'] ?? 'Section', style: const TextStyle(fontWeight: FontWeight.bold)),
                        children: items.map((lesson) {
                          final isPlaying = _currentLesson?['id'].toString() == lesson['id'].toString();
                          String type = lesson['content_type']?.toString() ?? lesson['lesson_type']?.toString() ?? 'video';
                          String url = lesson['content']?.toString() ?? lesson['video_url']?.toString() ?? '';
                          bool hasAccess = url.isNotEmpty;

                          return ListTile(
                            tileColor: isPlaying ? AppTheme.primaryColor.withOpacity(0.1) : null,
                            leading: Icon(
                              isPlaying ? Icons.pause_circle_filled : (!hasAccess ? Icons.lock : (type == 'video' ? Icons.play_circle_outline : Icons.article)),
                              color: isPlaying ? AppTheme.primaryColor : Colors.grey,
                            ),
                            title: Text(
                              lesson['title'] ?? 'Lesson',
                              style: TextStyle(color: isPlaying ? AppTheme.primaryColor : Colors.black87, fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal),
                            ),
                            trailing: hasAccess ? _buildDownloadButton(lesson) : null,
                            onTap: hasAccess ? () => _playLesson(lesson) : () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enroll to view this lesson.'), backgroundColor: Colors.orange)),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPlayerArea() {
    String type = _currentLesson!['content_type']?.toString() ?? _currentLesson!['lesson_type']?.toString() ?? 'video';
    String url = _currentLesson!['content']?.toString() ?? _currentLesson!['video_url']?.toString() ?? '';
    
    if (type == 'video') {
      if (_isYoutubeOrVimeo(url)) {
        return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text('YouTube/Vimeo playback requires advanced plugins (Phase 2).', style: TextStyle(color: Colors.white70), textAlign: TextAlign.center)));
      }
      if (_chewieController != null && _chewieController!.videoPlayerController.value.isInitialized) {
        return Chewie(controller: _chewieController!);
      }
      if (_videoController != null && _videoController!.value.hasError) {
         return const Center(child: Text('Error loading video. Please check your connection.', style: TextStyle(color: Colors.red)));
      }
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    } else {
      return const Center(child: Icon(Icons.article, size: 60, color: Colors.white54));
    }
  }
}
