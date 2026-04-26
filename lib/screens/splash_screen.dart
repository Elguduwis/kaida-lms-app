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
  // MASTER VERSION CONTROL: Bump this number when releasing a new update
  static const String CURRENT_APP_VERSION = "1.0.0";

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // 1. Fetch Server Settings for Version Guard
    try {
      final response = await http.get(Uri.parse(ApiConfig.appSettings)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          String latestVersion = data['data']['latest_app_version'] ?? '1.0.0';
          bool forceUpdate = data['data']['force_update'] == '1';

          if (_isUpdateRequired(CURRENT_APP_VERSION, latestVersion)) {
            _showUpdateDialog(forceUpdate, data['data']['share_url']);
            if (forceUpdate) return; // Completely halt app execution if forced
          }
        }
      }
    } catch (e) {
      debugPrint("Version check bypassed due to offline mode: $e");
    }

    // 2. Seamlessly route user via cached auth
    _routeUser();
  }

  bool _isUpdateRequired(String currentVersion, String serverVersion) {
    List<String> currentParts = currentVersion.split('.');
    List<String> serverParts = serverVersion.split('.');
    
    for (int i = 0; i < serverParts.length; i++) {
      int serverPart = int.tryParse(serverParts[i]) ?? 0;
      int currentPart = i < currentParts.length ? (int.tryParse(currentParts[i]) ?? 0) : 0;
      
      if (serverPart > currentPart) return true;
      if (serverPart < currentPart) return false;
    }
    return false;
  }

  void _showUpdateDialog(bool isForced, String? storeUrl) {
    String url = storeUrl ?? "https://play.google.com/store/apps/details?id=com.kainuwa.academy";
    
    showDialog(
      context: context,
      barrierDismissible: !isForced, 
      builder: (context) {
        return WillPopScope(
          onWillPop: () async => !isForced, // Lock Android back button if forced
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            title: Row(
              children: const [
                Icon(Icons.system_update, color: AppTheme.primaryColor),
                SizedBox(width: 10),
                Text('Update Available', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: Text(
              isForced 
                ? 'A critical update is required to continue using Kaida Learn. Please update to the latest version to ensure peak performance and security.'
                : 'A new version of Kaida Learn is available with new features and improvements. Would you like to update now?',
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
            actions: [
              if (!isForced)
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _routeUser(); // Allow user to bypass and continue to app
                  },
                  child: const Text('Later', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  final uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                child: const Text('Update Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
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
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Image.asset('assets/images/app_icon.png', width: 80, height: 80),
            ),
            const SizedBox(height: 24),
            const Text('Kaida Learn', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
            const SizedBox(height: 40),
            const SizedBox(
              width: 30, height: 30,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
            ),
          ],
        ),
      ),
    );
  }
}
