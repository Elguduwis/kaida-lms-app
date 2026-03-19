import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/course_model.dart';

class CourseService {
  Future<List<CourseModel>> getMyCourses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');

      if (userId == null) return [];

      final response = await http.post(
        Uri.parse(ApiConfig.myCourses),
        body: {'user_id': userId.toString()},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          List<dynamic> coursesJson = data['data'];
          return coursesJson.map((json) => CourseModel.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
