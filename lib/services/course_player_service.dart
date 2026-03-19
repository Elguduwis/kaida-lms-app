import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class CoursePlayerService {
  Future<Map<String, dynamic>?> getCourseDetails(int courseId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');

      if (userId == null) return null;

      final response = await http.post(
        Uri.parse(ApiConfig.courseLessons),
        body: {
          'course_id': courseId.toString(),
          'user_id': userId.toString()
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return data['data'];
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // NEW: Save progress silently to the server
  Future<void> saveVideoProgress(int lessonId, double timestamp) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');

      if (userId == null) return;

      await http.post(
        Uri.parse(ApiConfig.saveProgress),
        body: {
          'user_id': userId.toString(),
          'lesson_id': lessonId.toString(),
          'timestamp': timestamp.toString()
        },
      );
    } catch (e) {
      // Fail silently, no need to interrupt the user's video
    }
  }
}
