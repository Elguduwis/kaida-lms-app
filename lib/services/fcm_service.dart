import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../screens/course_player_screen.dart';
import '../screens/main_layout.dart';

class FcmService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initNotifications(GlobalKey<NavigatorState> navigatorKey) async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission();
    
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) await _saveTokenToServer(token);

      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _saveTokenToServer(newToken);
      });

      // SCENARIO 1: App is in the Background, but still running in RAM
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _routeFromNotification(navigatorKey, message.data);
      });

      // SCENARIO 2: App was completely Closed/Terminated
      RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        // Add a slight delay to let the Splash Screen finish checking login status
        Future.delayed(const Duration(seconds: 3), () {
          _routeFromNotification(navigatorKey, initialMessage.data);
        });
      }
    }
  }

  // The Dynamic Router Logic
  void _routeFromNotification(GlobalKey<NavigatorState> navigatorKey, Map<String, dynamic> data) {
    if (navigatorKey.currentState == null) return;
    
    final action = data['action'] ?? '';
    
    switch (action) {
      case 'open_course':
        final courseId = int.tryParse(data['course_id']?.toString() ?? '0') ?? 0;
        final courseTitle = data['course_title']?.toString() ?? 'Course';
        
        if (courseId > 0) {
          navigatorKey.currentState!.push(
            MaterialPageRoute(
              builder: (context) => CoursePlayerScreen(courseId: courseId, courseTitle: courseTitle),
            ),
          );
        }
        break;
        
      case 'open_dashboard':
        navigatorKey.currentState!.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainLayout()),
          (Route<dynamic> route) => false, // Clears the stack
        );
        break;
        
      default:
        // Do nothing, just let the app open normally
        break;
    }
  }

  Future<void> _saveTokenToServer(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    
    if (userId != null) {
      try {
        await http.post(
          Uri.parse(ApiConfig.saveFcmToken),
          body: {'user_id': userId.toString(), 'token': token},
        );
      } catch (e) {
        // Silent fail
      }
    }
  }
}
