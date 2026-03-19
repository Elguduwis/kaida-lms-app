import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../config/app_theme.dart';
import '../models/course_detail_model.dart';
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
  List<SectionModel> _sections = [];
  LessonModel? _currentLesson;
  
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  Timer? _progressTimer;

  List<LessonModel> get _allLessons => _sections.expand((s) => s.lessons).toList();

  @override
  void initState() {
    super.initState();
    _loadCourseData();
  }

  void _loadCourseData() async {
    final data = await _service.getCourseDetails(widget.courseId);
    if (data != null && data['sections'] != null) {
      List<dynamic> secList = data['sections'];
      _sections = secList.map((s) => SectionModel.fromJson(s)).toList();
      
      if (_sections.isNotEmpty && _sections.first.lessons.isNotEmpty) {
        _playLesson(_sections.first.lessons.first);
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  bool _isYoutubeOrVimeo(String url) {
    String lowerUrl = url.toLowerCase();
    return lowerUrl.contains('youtube.com') || 
           lowerUrl.contains('youtu.be') || 
           lowerUrl.contains('vimeo.com');
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();
    // Silently save progress to the server every 10 seconds
    _progressTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_currentLesson != null && _videoController != null && _videoController!.value.isPlaying) {
        _service.saveVideoProgress(
          _currentLesson!.id, 
          _videoController!.value.position.inSeconds.toDouble()
        );
      }
    });
  }

  void _playLesson(LessonModel lesson) async {
    // Save progress of the outgoing lesson before switching
    if (_currentLesson != null && _videoController != null) {
      _service.saveVideoProgress(_currentLesson!.id, _videoController!.value.position.inSeconds.toDouble());
    }

    _progressTimer?.cancel();

    setState(() {
      _currentLesson = lesson;
      if (_chewieController != null) {
        _chewieController!.dispose();
        _chewieController = null;
      }
      if (_videoController != null) {
        _videoController!.dispose();
        _videoController = null;
      }
    });

    if (lesson.contentType == 'video' && lesson.content.isNotEmpty) {
      String url = lesson.content;
      
      if (!_isYoutubeOrVimeo(url)) {
        if (!url.startsWith('http')) {
          url = 'https://academy.kainuwa.africa/' + url;
        }
        
        _videoController = VideoPlayerController.network(url);
        await _videoController!.initialize();

        _chewieController = ChewieController(
          videoPlayerController: _videoController!,
          autoPlay: true,
          looping: false,
          allowPlaybackSpeedChanging: true,
          allowMuting: true,
          materialProgressColors: ChewieProgressColors(
            playedColor: AppTheme.primaryColor,
            handleColor: AppTheme.primaryColor,
            backgroundColor: Colors.grey.shade800,
            bufferedColor: Colors.grey.shade400,
          ),
        );

        _startProgressTimer();

        // Auto-Next Logic
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
    final currentIndex = _allLessons.indexOf(_currentLesson!);
    if (currentIndex >= 0 && currentIndex < _allLessons.length - 1) {
      _playLesson(_allLessons[currentIndex + 1]);
    }
  }

  void _playPrevLesson() {
    if (_currentLesson == null) return;
    final currentIndex = _allLessons.indexOf(_currentLesson!);
    if (currentIndex > 0) {
      _playLesson(_allLessons[currentIndex - 1]);
    }
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    if (_currentLesson != null && _videoController != null) {
      _service.saveVideoProgress(_currentLesson!.id, _videoController!.value.position.inSeconds.toDouble());
    }
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(widget.courseTitle, style: const TextStyle(fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  height: 230,
                  color: Colors.black,
                  child: _currentLesson == null
                      ? const Center(child: Text('Select a lesson', style: TextStyle(color: Colors.white)))
                      : _buildPlayerArea(),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Text(
                    _currentLesson?.title ?? '',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(height: 1, thickness: 1),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        icon: Icon(Icons.skip_previous, color: (_currentLesson != null && _allLessons.indexOf(_currentLesson!) > 0) ? AppTheme.primaryColor : Colors.grey),
                        label: Text('Previous', style: TextStyle(color: (_currentLesson != null && _allLessons.indexOf(_currentLesson!) > 0) ? AppTheme.primaryColor : Colors.grey, fontWeight: FontWeight.bold)),
                        onPressed: (_currentLesson != null && _allLessons.indexOf(_currentLesson!) > 0) ? _playPrevLesson : null,
                      ),
                      TextButton(
                        onPressed: (_currentLesson != null && _allLessons.indexOf(_currentLesson!) < _allLessons.length - 1) ? _playNextLesson : null,
                        child: Row(
                          children: [
                            Text('Next', style: TextStyle(color: (_currentLesson != null && _allLessons.indexOf(_currentLesson!) < _allLessons.length - 1) ? AppTheme.primaryColor : Colors.grey, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Icon(Icons.skip_next, color: (_currentLesson != null && _allLessons.indexOf(_currentLesson!) < _allLessons.length - 1) ? AppTheme.primaryColor : Colors.grey),
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
                      return ExpansionTile(
                        initiallyExpanded: _currentLesson != null ? section.lessons.any((l) => l.id == _currentLesson!.id) : index == 0,
                        title: Text(section.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        children: section.lessons.map((lesson) {
                          final isPlaying = _currentLesson?.id == lesson.id;
                          return ListTile(
                            tileColor: isPlaying ? AppTheme.primaryColor.withOpacity(0.1) : null,
                            leading: Icon(
                              lesson.contentType == 'video' ? Icons.play_circle_fill : Icons.article,
                              color: isPlaying ? AppTheme.primaryColor : Colors.grey,
                            ),
                            title: Text(
                              lesson.title,
                              style: TextStyle(
                                color: isPlaying ? AppTheme.primaryColor : Colors.black87,
                                fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            onTap: () => _playLesson(lesson),
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
    if (_currentLesson!.contentType == 'video') {
      if (_isYoutubeOrVimeo(_currentLesson!.content)) {
        return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text('This is a YouTube/Vimeo video. Native playback requires advanced plugins which will be added in Phase 2.', style: TextStyle(color: Colors.white70, fontSize: 14), textAlign: TextAlign.center)));
      }
      if (_chewieController != null && _chewieController!.videoPlayerController.value.isInitialized) {
        return Chewie(controller: _chewieController!);
      }
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    } else {
      return const Center(child: Icon(Icons.article, size: 60, color: Colors.white54));
    }
  }
}
