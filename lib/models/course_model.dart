class CourseModel {
  final int id;
  final String title;
  final String thumbnailUrl;
  final int progress;

  CourseModel({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    required this.progress,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      title: json['title']?.toString() ?? 'Untitled Course',
      thumbnailUrl: json['thumbnail_url']?.toString() ?? '',
      progress: int.tryParse(json['progress_percentage'].toString()) ?? 0,
    );
  }
}
