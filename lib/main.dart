import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/app_theme.dart';
import 'config/theme_provider.dart';
import 'screens/onboarding_screen.dart';
import 'screens/main_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();
  final String? token = prefs.getString('auth_token');

  Widget initialScreen;
  if (token != null && token.isNotEmpty) {
    initialScreen = const MainLayout();
  } else {
    initialScreen = const OnboardingScreen();
  }

  // CRITICAL FIX: Restored ChangeNotifierProvider so ProfileScreen can access the Theme
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: KaidaApp(initialScreen: initialScreen),
    ),
  );
}

class KaidaApp extends StatelessWidget {
  final Widget initialScreen;
  
  const KaidaApp({Key? key, required this.initialScreen}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return MaterialApp(
      title: 'Kainuwa Academy',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode, // Actively listens to the Dark Mode toggle
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: initialScreen,
    );
  }
}
