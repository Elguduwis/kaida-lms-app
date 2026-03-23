import '../widgets/kaida_loader.dart';
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
      list.addAll(s['lessons'] ?? s['items'] ?? []);
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadCourseData();
  }

  void _loadPreferences() async {
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
      if (data is List) parsedSections = data;
      else if (data is Map && data.containsKey('sections')) parsedSections = data['sections'];
      else if (data is Map && data.containsKey('curriculum')) parsedSections = data['curriculum'];
      else if (data is Map && data.containsKey('data')) parsedSections = data['data'];

      if (mounted) {
        setState(() {
          _sections = parsedSections;
          _isLoading = false;
        });
        if (_allLessons.isNotEmpty) _playLesson(_allLessons.first);
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

  Future<void> _downloadLesson(dynamic lesson) async {
    String id = lesson['id'].toString();
    String url = lesson['content']?.toString() ?? lesson['video_url']?.toString() ?? '';
    String type = lesson['content_type']?.toString() ?? lesson['lesson_type']?.toString() ?? 'video';
    
    if (type != 'video' || url.isEmpty || _isYoutubeOrVimeo(url)) return;
    if (_downloadedLessons.containsKey(id) || _downloadProgress.containsKey(id)) return;

    setState(() => _downloadProgress[id] = 0.01);
    CancelToken cancelToken = CancelToken();
    _cancelTokens[id] = cancelToken;

    try {
      if (!url.startsWith('http')) url = 'https://academy.kainuwa.africa/' + url;

      final dir = await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/lesson_$id.mp4';

      final dio = Dio();
      await dio.download(
        url, savePath,
        cancelToken: cancelToken,
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
        setState(() {
          _downloadProgress.remove(id);
          _cancelTokens.remove(id);
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${lesson['title']} downloaded!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        debugPrint("Download cancelled by user.");
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Download failed.'), backgroundColor: Colors.red));
      }
      
      if (mounted) {
        setState(() {
          _downloadProgress.remove(id);
          _cancelTokens.remove(id);
        });
      }
    }
  }

  void _cancelDownload(String id) {
    if (_cancelTokens.containsKey(id)) {
      _cancelTokens[id]?.cancel();
      _cancelTokens.remove(id);
      setState(() => _downloadProgress.remove(id));
    }
  }

  void _downloadSection(dynamic section) {
    List items = section['lessons'] ?? section['items'] ?? [];
    for (var lesson in items) {
      _downloadLesson(lesson);
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Section added to download queue!'), backgroundColor: AppTheme.primaryColor));
  }

  void _downloadEntireCourse() {
    for (var sec in _sections) {
      _downloadSection(sec);
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Entire course added to download queue!'), backgroundColor: AppTheme.primaryColor));
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

        _startProgressTimer();

        _videoController!.addListener(() {
          if (_videoController!.value.isInitialized && 
              !_videoController!.value.isPlaying &&
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
      if (_chewieController != null && _chewieController!.isFullScreen) {
        _chewieController!.exitFullScreen();
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _playLesson(_allLessons[currentIndex + 1]);
        });
      } else {
        _playLesson(_allLessons[currentIndex + 1]);
      }
    }
  }

  void _playPrevLesson() {
    if (_currentLesson == null) return;
    final currentIndex = _allLessons.indexWhere((l) => l['id'].toString() == _currentLesson!['id'].toString());
    if (currentIndex > 0) {
      if (_chewieController != null && _chewieController!.isFullScreen) {
        _chewieController!.exitFullScreen();
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _playLesson(_allLessons[currentIndex - 1]);
        });
      } else {
        _playLesson(_allLessons[currentIndex - 1]);
      }
    }
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _cancelTokens.forEach((key, token) => token.cancel());
    if (_currentLesson != null && _videoController != null) {
      _service.saveVideoProgress(int.parse(_currentLesson!['id'].toString()), _videoController!.value.position.inSeconds.toDouble());
    }
    _chewieController?.dispose();
    _videoController?.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  Widget _buildDownloadStateWidget(dynamic lesson, bool isDark) {
    String id = lesson['id'].toString();
    String url = lesson['content']?.toString() ?? lesson['video_url']?.toString() ?? '';
    String type = lesson['content_type']?.toString() ?? lesson['lesson_type']?.toString() ?? 'video';

    if (type != 'video' || url.isEmpty || _isYoutubeOrVimeo(url)) return const SizedBox();
    
    if (_downloadedLessons.containsKey(id)) {
      return const Icon(Icons.check_circle, color: Colors.green, size: 24);
    }
    
    if (_downloadProgress.containsKey(id)) {
      return GestureDetector(
        onTap: () => _cancelDownload(id),
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 28, height: 28,
              child: CircularProgressIndicator(value: _downloadProgress[id], strokeWidth: 3, color: AppTheme.primaryColor),
            ),
            const Icon(Icons.close, size: 14, color: AppTheme.primaryColor),
          ],
        ),
      );
    }
    
    return IconButton(
      icon: Icon(Icons.cloud_download_outlined, color: isDark ? Colors.grey.shade400 : Colors.grey),
      onPressed: () => _downloadLesson(lesson),
      tooltip: 'Download Lesson',
    );
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic theme checks to preserve layout while supporting dark mode
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final surfaceColor = isDark ? AppTheme.darkSurfaceColor : Colors.white;

    return Scaffold(
      // Using AppTheme.backgroundColor directly looks bad in Dark Mode, letting Scaffold handle it based on Theme
      body: _isLoading
          ? Center(child: KaidaLoader())
          : Column(
              children: [
                Container(
                  padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                  width: double.infinity, 
                  height: 250 + MediaQuery.of(context).padding.top, 
                  color: Colors.black, // Player area always black
                  child: Stack(
                    children: [
                      _currentLesson == null
                          ? const Center(child: Text('Select a lesson', style: TextStyle(color: Colors.white)))
                          : _buildPlayerArea(),
                      Positioned(
                        top: 10, left: 10,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, shadows: [Shadow(blurRadius: 10, color: Colors.black)]),
                          onPressed: () => Navigator.pop(context),
                        ),
                      )
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: surfaceColor, // Dynamic card color
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), blurRadius: 10, offset: const Offset(0, 5))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_currentLesson?['title'] ?? widget.courseTitle, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1.3, color: textColor)),
                              const SizedBox(height: 16),
                              
                              // NEW: Prev and Next Buttons Row
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppTheme.primaryColor,
                                        side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.5)),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                                      ),
                                      icon: const Icon(Icons.skip_previous, size: 20),
                                      label: const Text('Prev', style: TextStyle(fontWeight: FontWeight.bold)),
                                      onPressed: _playPrevLesson,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppTheme.primaryColor,
                                        side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.5)),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                                      ),
                                      onPressed: _playNextLesson,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: const [
                                          Text('Next', style: TextStyle(fontWeight: FontWeight.bold)),
                                          SizedBox(width: 4),
                                          Icon(Icons.skip_next, size: 20),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Download Entire Course Button
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.primaryColor,
                                    side: const BorderSide(color: AppTheme.primaryColor, width: 2),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                                  ),
                                  icon: const Icon(Icons.download_for_offline),
                                  label: const Text('Download Entire Course', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                  onPressed: _downloadEntireCourse,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text('Curriculum', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                        ),
                        const SizedBox(height: 8),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _sections.length,
                          itemBuilder: (context, index) {
                            final section = _sections[index];
                            List items = section['lessons'] ?? section['items'] ?? [];
                            
                            return Theme(
                              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                initiallyExpanded: index == 0,
                                title: Row(
                                  children: [
                                    Expanded(child: Text(section['title'] ?? 'Section', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor))),
                                    IconButton(
                                      icon: const Icon(Icons.drive_file_move_outline, color: AppTheme.primaryColor),
                                      tooltip: 'Download Section',
                                      onPressed: () => _downloadSection(section),
                                    ),
                                  ],
                                ),
                                children: items.map((lesson) {
                                  final isPlaying = _currentLesson?['id'].toString() == lesson['id'].toString();
                                  String type = lesson['content_type']?.toString() ?? lesson['lesson_type']?.toString() ?? 'video';
                                  String url = lesson['content']?.toString() ?? lesson['video_url']?.toString() ?? '';
                                  bool hasAccess = url.isNotEmpty;

                                  return Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    decoration: BoxDecoration(
                                      // Dynamic container color for Dark Mode
                                      color: isPlaying ? AppTheme.primaryColor.withOpacity(isDark ? 0.2 : 0.08) : surfaceColor,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: isPlaying ? AppTheme.primaryColor.withOpacity(0.5) : (isDark ? Colors.grey.shade700 : Colors.grey.shade200)),
                                    ),
                                    child: ListTile(
                                      leading: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          // Dynamic icon background
                                          color: isPlaying ? AppTheme.primaryColor : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          isPlaying ? Icons.pause : (!hasAccess ? Icons.lock : (type == 'video' ? Icons.play_arrow : Icons.article)),
                                          // Dynamic icon color
                                          color: isPlaying ? Colors.white : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                          size: 16,
                                        ),
                                      ),
                                      title: Text(
                                        lesson['title'] ?? 'Lesson',
                                        style: TextStyle(color: isPlaying ? AppTheme.primaryColor : textColor, fontWeight: isPlaying ? FontWeight.bold : FontWeight.w600, fontSize: 13),
                                      ),
                                      trailing: hasAccess ? _buildDownloadStateWidget(lesson, isDark) : null,
                                      onTap: hasAccess ? () => _playLesson(lesson) : () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enroll to view this lesson.'), backgroundColor: Colors.orange)),
                                    ),
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
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
      return Center(child: KaidaLoader());
    } else {
      return const Center(child: Icon(Icons.article, size: 60, color: Colors.white54));
    }
  }
}
