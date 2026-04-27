import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class InstructorProfileScreen extends StatelessWidget {
  final Map<String, dynamic> instructor;
  
  const InstructorProfileScreen({Key? key, required this.instructor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackgroundColor : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              backgroundImage: instructor['avatar'] != null ? NetworkImage(instructor['avatar']) : null,
              child: instructor['avatar'] == null ? const Icon(Icons.person_rounded, size: 60, color: AppTheme.primaryColor) : null,
            ),
            const SizedBox(height: 16),
            Text(instructor['name'] ?? 'Instructor', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Professional Instructor', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Instructor Courses', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
            const Center(child: Text('Courses loading...')),
          ],
        ),
      ),
    );
  }
}
