import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
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
    setState(() => _isLoading = false);
  }

  void _playLesson(LessonModel lesson) {
    setState(() => _currentLesson = lesson);
    
    if (_videoController != null) {
      _videoController!.dispose();
      _videoController = null;
    }

    if (lesson.contentType == 'video' && lesson.videoSource == 'mp4' && lesson.content.isNotEmpty) {
      String url = lesson.content;
      if (!url.startsWith('http')) {
        url = 'https://academy.kainuwa.africa/' + url;
      }
      _videoController = VideoPlayerController.network(url)
        ..initialize().then((_) {
          setState(() {});
          _videoController!.play();
        });
    }
  }

  @override
  void dispose() {
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
                // Top: Video Player Area
                Container(
                  width: double.infinity,
                  height: 230,
                  color: Colors.black,
                  child: _currentLesson == null
                      ? const Center(child: Text('Select a lesson', style: TextStyle(color: Colors.white)))
                      : _buildPlayerArea(),
                ),
                
                // Title Area
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
                
                // Bottom: Curriculum List
                Expanded(
                  child: ListView.builder(
                    itemCount: _sections.length,
                    itemBuilder: (context, index) {
                      final section = _sections[index];
                      return ExpansionTile(
                        initiallyExpanded: index == 0,
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
      if (_currentLesson!.videoSource != 'mp4') {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'This is a YouTube/Vimeo video. Native playback requires advanced plugins which will be added in Phase 2.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        );
      }
      if (_videoController != null && _videoController!.value.isInitialized) {
        return AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              VideoPlayer(_videoController!),
              VideoProgressIndicator(_videoController!, allowScrubbing: true, colors: VideoProgressColors(playedColor: AppTheme.primaryColor)),
              Align(
                alignment: Alignment.center,
                child: IconButton(
                  iconSize: 50,
                  color: Colors.white.withOpacity(0.9),
                  icon: Icon(_videoController!.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill),
                  onPressed: () {
                    setState(() {
                      _videoController!.value.isPlaying ? _videoController!.pause() : _videoController!.play();
                    });
                  },
                ),
              ),
            ],
          ),
        );
      }
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    } else {
      return const Center(
        child: Icon(Icons.article, size: 60, color: Colors.white54),
      );
    }
  }
}
