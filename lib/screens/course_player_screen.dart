import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../services/course_player_service.dart';
import '../config/app_theme.dart';

class CoursePlayerScreen extends StatefulWidget {
  final int courseId;
  final String courseTitle;

  const CoursePlayerScreen({Key? key, required this.courseId, required this.courseTitle}) : super(key: key);

  @override
  _CoursePlayerScreenState createState() => _CoursePlayerScreenState();
}

class _CoursePlayerScreenState extends State<CoursePlayerScreen> {
  bool _isLoading = true;
  List<dynamic> _sections = [];
  Map<String, dynamic>? _currentLesson;
  
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    _loadCurriculum();
  }

  Future<void> _loadCurriculum() async {
    final data = await CoursePlayerService().getCourseDetails(widget.courseId);
    if (data != null) {
      List<dynamic> parsedSections = [];
      // Safely handles whatever structure the server sends back
      if (data is List) {
        parsedSections = data;
      } else if (data is Map && data.containsKey('sections')) {
        parsedSections = data['sections'];
      } else if (data is Map && data.containsKey('data')) {
        parsedSections = data['data'];
      }

      if (mounted) {
        setState(() {
          _sections = parsedSections;
          _isLoading = false;
        });
        _playFirstAvailableLesson();
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _playFirstAvailableLesson() {
    for (var section in _sections) {
      for (var lesson in section['lessons']) {
        if (lesson['lesson_type'] == 'video' || lesson['video_url'] != null) {
          _playLesson(lesson);
          return;
        }
      }
    }
  }

  void _playLesson(dynamic lesson) {
    if (lesson['video_url'] == null || lesson['video_url'].toString().isEmpty) return;
    
    setState(() {
      _currentLesson = Map<String, dynamic>.from(lesson);
    });
    
    _initializePlayer(lesson['video_url'].toString());
  }

  void _initializePlayer(String videoUrl) {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    _progressTimer?.cancel();

    _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _chewieController = ChewieController(
              videoPlayerController: _videoPlayerController!,
              autoPlay: true,
              looping: false,
              aspectRatio: _videoPlayerController!.value.aspectRatio,
              errorBuilder: (context, errorMessage) {
                return Center(child: Text('Video format not supported or URL invalid.', style: const TextStyle(color: Colors.white)));
              },
            );
          });
          _startProgressTracking();
        }
      }).catchError((error) {
         debugPrint("Video Player Error: $error");
      });
  }

  void _startProgressTracking() {
    _progressTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_videoPlayerController != null && _videoPlayerController!.value.isPlaying && _currentLesson != null) {
        CoursePlayerService().saveVideoProgress(
          int.parse(_currentLesson!['id'].toString()),
          _videoPlayerController!.value.position.inSeconds.toDouble()
        );
      }
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: Text(widget.courseTitle, style: const TextStyle(fontSize: 16))),
      body: Column(
        children: [
          // Native Video Player Area
          Container(
            width: double.infinity,
            height: 250,
            color: Colors.black,
            child: _chewieController != null 
              ? Chewie(controller: _chewieController!)
              : const Center(child: Text('Loading video...', style: TextStyle(color: Colors.white))),
          ),
          
          // Curriculum List Area
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
              : _sections.isEmpty
                ? const Center(child: Text('No lessons found for this course.'))
                : ListView.builder(
                    itemCount: _sections.length,
                    itemBuilder: (context, index) {
                      final section = _sections[index];
                      return ExpansionTile(
                        title: Text(section['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        initiallyExpanded: true,
                        children: (section['lessons'] as List).map((lesson) {
                          bool isPlaying = _currentLesson?['id'] == lesson['id'];
                          bool hasVideo = lesson['video_url'] != null && lesson['video_url'].toString().isNotEmpty;
                          
                          return ListTile(
                            leading: Icon(
                              isPlaying ? Icons.pause_circle_filled : (hasVideo ? Icons.play_circle_outline : Icons.article),
                              color: isPlaying ? AppTheme.primaryColor : Colors.grey,
                            ),
                            title: Text(lesson['title'], style: TextStyle(
                              fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                              color: isPlaying ? AppTheme.primaryColor : Colors.black87
                            )),
                            onTap: hasVideo ? () => _playLesson(lesson) : null,
                          );
                        }).toList(),
                      );
                    }
                )
          )
        ],
      )
    );
  }
}
