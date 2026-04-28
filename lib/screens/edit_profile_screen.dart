import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackgroundColor : Colors.white,
      appBar: AppBar(title: const Text('Edit Profile', style: TextStyle(color: Colors.white, fontSize: 16)), backgroundColor: AppTheme.primaryColor, iconTheme: const IconThemeData(color: Colors.white)),
      body: const Center(child: Text('Edit Profile Interface Coming Soon')),
    );
  }
}
