import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/app_theme.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();
  
  // Flag to check if onboarding has been shown
  final bool isFirstTime = prefs.getBool('first_time_user') ?? true;
  
  // Flag to check if user is logged in (relying on existing auth logic)
  final String? token = prefs.getString('auth_token');

  Widget initialScreen;
  
  if (isFirstTime) {
    initialScreen = const OnboardingScreen();
  } else if (token != null && token.isNotEmpty) {
    initialScreen = const MainLayout();
  } else {
    initialScreen = const LoginScreen();
  }

  runApp(KaidaApp(initialScreen: initialScreen));
}

class KaidaApp extends StatelessWidget {
  final Widget initialScreen;
  
  const KaidaApp({Key? key, required this.initialScreen}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kaida Learn',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Respect system theme settings
      home: initialScreen,
    );
  }
}
