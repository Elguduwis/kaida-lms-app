import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/api_config.dart';
import '../config/app_theme.dart';
import 'login_screen.dart';
import 'main_layout.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const String CURRENT_APP_VERSION = "1.0.0";

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.appSettings)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          String latestVersion = data['data']['latest_app_version'] ?? '1.0.0';
          bool forceUpdate = data['data']['force_update'] == '1';
          String updateUrl = data['data']['share_url'] ?? "https://play.google.com/store/apps/details?id=com.kainuwa.academy";

          if (_isUpdateRequired(CURRENT_APP_VERSION, latestVersion)) {
            _showUpdateDialog(forceUpdate, updateUrl);
            return;
          }
        }
      }
    } catch (e) {
      debugPrint("Splash settings fetch error: $e");
    }
    
    // Add a slight artificial delay so the minimalist text stays on screen just long enough to be read
    await Future.delayed(const Duration(milliseconds: 1500));
    _routeUser();
  }

  bool _isUpdateRequired(String current, String latest) {
    try {
      List<int> currParts = current.split('.').map(int.parse).toList();
      List<int> latestParts = latest.split('.').map(int.parse).toList();
      for (int i = 0; i < 3; i++) {
        if (latestParts[i] > currParts[i]) return true;
        if (latestParts[i] < currParts[i]) return false;
      }
    } catch (e) {
      return false;
    }
    return false;
  }

  void _showUpdateDialog(bool forceUpdate, String url) {
    showDialog(
      context: context,
      barrierDismissible: !forceUpdate,
      builder: (context) => WillPopScope(
        onWillPop: () async => !forceUpdate,
        child: AlertDialog(
          title: const Text('Update Required'),
          content: const Text('A new version of Kainuwa Academy is available. Please update to continue learning.'),
          actions: [
            if (!forceUpdate)
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _routeUser();
                },
                child: const Text('Later'),
              ),
            ElevatedButton(
              onPressed: () async {
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: const Text('Update Now'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _routeUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final userId = prefs.getInt('user_id');

    if (!mounted) return;

    if (token != null && userId != null) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const MainLayout()));
    } else {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: Text(
          'Kainuwa Academy', 
          style: TextStyle(
            fontSize: 32, 
            fontWeight: FontWeight.w900, 
            color: Colors.white, 
            letterSpacing: -0.5
          )
        ),
      ),
    );
  }
}
