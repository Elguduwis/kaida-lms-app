import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';

class AuthService {
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.login),
        body: {'email': email, 'password': password},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final user = UserModel.fromJson(data);
          await _saveUserData(user.token, user.id);
          return {'success': true, 'message': 'Login successful'};
        } else {
          return {'success': false, 'message': data['message'] ?? 'Login failed'};
        }
      }
      return {'success': false, 'message': 'Server error'};
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> register(String fullName, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.registerNative),
        body: {'full_name': fullName, 'email': email, 'password': password},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': data['status'] == 'success', 'message': data['message'] ?? 'Error'};
      }
      return {'success': false, 'message': 'Server error'};
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.verifyOtp),
        body: {'email': email, 'otp': otp},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': data['status'] == 'success', 'message': data['message'] ?? 'Error'};
      }
      return {'success': false, 'message': 'Server error'};
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<void> _saveUserData(String token, int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setInt('user_id', userId);
  }
}
