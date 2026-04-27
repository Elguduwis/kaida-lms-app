import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/app_theme.dart';
import 'screens/onboarding_screen.dart';
import 'screens/main_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();
  final String? token = prefs.getString('auth_token');

  // Strict Routing: If no token exists, ALWAYS start at Onboarding.
  Widget initialScreen;
  if (token != null && token.isNotEmpty) {
    initialScreen = const MainLayout();
  } else {
    initialScreen = const OnboardingScreen();
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
      themeMode: ThemeMode.system,
      home: initialScreen,
    );
  }
}
