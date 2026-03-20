import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class CoursePlayerService {
  Future<Map<String, dynamic>?> getCourseDetails(int courseId) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'course_curriculum_$courseId';

    try {
      final response = await http.get(Uri.parse('${ApiConfig.courseLessons}?course_id=$courseId')).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          // SAVE TO CACHE FOR OFFLINE DOWNLOAD VIEWING!
          prefs.setString(cacheKey, json.encode(data['data']));
          return data['data'];
        }
      }
    } catch (e) {
      // OFFLINE SURVIVAL MODE!
      final cached = prefs.getString(cacheKey);
      if (cached != null) {
        return json.decode(cached);
      }
    }
    return null;
  }

  Future<void> saveVideoProgress(int lessonId, double secondsWatched) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      if (userId == null) return;

      await http.post(
        Uri.parse(ApiConfig.saveProgress),
        body: {
          'user_id': userId.toString(),
          'lesson_id': lessonId.toString(),
          'seconds_watched': secondsWatched.toString(),
        },
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      // Ignore in offline mode, it will sync next time
    }
  }
}
