import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn();

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

  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      // FIX: Force sign out first so the Google Account Picker ALWAYS shows up
      await _googleSignIn.signOut();
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return {'success': false, 'message': 'Sign-in aborted'};

      final response = await http.post(
        Uri.parse(ApiConfig.googleAuth),
        body: {
          'email': googleUser.email,
          'full_name': googleUser.displayName ?? '',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          await _saveUserData(data['token'], data['user_id']);
          return {'success': true, 'message': 'Login successful'};
        } else if (data['status'] == 'not_found') {
          return {
            'success': false, 
            'needs_registration': true, 
            'email': googleUser.email, 
            'name': googleUser.displayName ?? ''
          };
        } else {
          await _googleSignIn.signOut();
          return {'success': false, 'message': data['message'] ?? 'Error verifying Google account'};
        }
      }
      await _googleSignIn.signOut();
      return {'success': false, 'message': 'Server error communicating with API'};
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> register(Map<String, String> userData) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.registerNative),
        body: userData,
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
