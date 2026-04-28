import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackgroundColor : Colors.white,
      appBar: AppBar(title: const Text('Help Center', style: TextStyle(color: Colors.white, fontSize: 16)), backgroundColor: AppTheme.primaryColor, iconTheme: const IconThemeData(color: Colors.white)),
      body: const Center(child: Text('Help Center Interface Coming Soon')),
    );
  }
}
