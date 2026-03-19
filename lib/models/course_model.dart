class CourseModel {
  final int id;
  final String title;
  final String thumbnailUrl;
  final String instructorName;
  final int progress;

  CourseModel({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    required this.instructorName,
    required this.progress,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    String rawThumb = json['thumbnail_url']?.toString() ?? '';
    
    // Automatically add your domain if the database only gave a partial link!
    if (rawThumb.isNotEmpty && !rawThumb.startsWith('http')) {
      rawThumb = 'https://academy.kainuwa.africa/$rawThumb';
    }

    return CourseModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      title: json['title']?.toString() ?? 'Untitled Course',
      thumbnailUrl: rawThumb,
      instructorName: json['instructor_name']?.toString() ?? 'Kainuwa Instructor',
      progress: int.tryParse(json['progress_percentage'].toString()) ?? 0,
    );
  }
}
