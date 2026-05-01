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
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // CRITICAL FIX: Force heads-up banners even when the app is open in the foreground
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true, 
        badge: true, 
        sound: true,
      );

      String? token = await _firebaseMessaging.getToken();
      if (token != null) await _saveTokenToServer(token);

      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _saveTokenToServer(newToken);
      });

      // Handle Background Clicks
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _routeFromNotification(navigatorKey, message.data);
      });

      // Handle Terminated Clicks
      RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        Future.delayed(const Duration(seconds: 3), () {
          _routeFromNotification(navigatorKey, initialMessage.data);
        });
      }
    }
  }

  void _routeFromNotification(GlobalKey<NavigatorState> navigatorKey, Map<String, dynamic> data) {
    if (navigatorKey.currentState == null) return;
    
    final action = data['action'] ?? '';
    
    switch (action) {
      case 'open_course':
        final courseId = int.tryParse(data['course_id']?.toString() ?? '0') ?? 0;
        final courseTitle = data['course_title']?.toString() ?? 'Course';
        
        if (courseId > 0) {
          CatalogItem dummy = CatalogItem(id: courseId, title: courseTitle, slug: data['course_slug']?.toString() ?? '', thumbnailUrl: '', price: 0, discountPrice: 0, isFree: true, instructorName: 'Loading...', categoryName: 'Course', language: 'EN', type: 'courses', productType: 'digital'); navigatorKey.currentState!.push(MaterialPageRoute(builder: (context) => ItemDetailsScreen(item: dummy)));//
            MaterialPageRoute(
              builder: (context) => CoursePlayerScreen(courseId: courseId, courseTitle: courseTitle),
            ),
          );
        }
        break;
        
      case 'open_dashboard':
        navigatorKey.currentState!.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainLayout(initialIndex: 3)),
          (Route<dynamic> route) => false, 
        );
        break;
        
      default:
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
