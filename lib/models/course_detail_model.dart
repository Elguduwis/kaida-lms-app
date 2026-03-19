class LessonModel {
  final int id;
  final String title;
  final String contentType; 
  final String videoSource;
  final String content;

  LessonModel({required this.id, required this.title, required this.contentType, required this.videoSource, required this.content});

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    return LessonModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      title: json['title']?.toString() ?? 'Untitled Lesson',
      contentType: json['content_type']?.toString() ?? 'text',
      videoSource: json['video_source']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
    );
  }
}

class SectionModel {
  final int id;
  final String title;
  final List<LessonModel> lessons;

  SectionModel({required this.id, required this.title, required this.lessons});

  factory SectionModel.fromJson(Map<String, dynamic> json) {
    var list = json['lessons'] as List? ?? [];
    List<LessonModel> lessonsList = list.map((i) => LessonModel.fromJson(i)).toList();
    return SectionModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      title: json['title']?.toString() ?? 'Untitled Section',
      lessons: lessonsList,
    );
  }
}
