import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class FcmService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initNotifications() async {
    // Request permission (Required for iOS, good practice for Android 13+)
    NotificationSettings settings = await _firebaseMessaging.requestPermission();
    
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Get the unique device token
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _saveTokenToServer(token);
      }

      // Listen for token refreshes if it changes later
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _saveTokenToServer(newToken);
      });
    }
  }

  Future<void> _saveTokenToServer(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    
    if (userId != null) {
      try {
        await http.post(
          Uri.parse(ApiConfig.saveFcmToken),
          body: {
            'user_id': userId.toString(),
            'token': token,
          },
        );
      } catch (e) {
        // Silent fail for background sync
      }
    }
  }
}
