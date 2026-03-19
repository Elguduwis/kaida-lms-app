import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_theme.dart';
import '../models/course_model.dart';
import '../services/course_service.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final CourseService _courseService = CourseService();
  late Future<List<CourseModel>> _myCoursesFuture;

  @override
  void initState() {
    super.initState();
    _myCoursesFuture = _courseService.getMyCourses();
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('My Learning'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: FutureBuilder<List<CourseModel>>(
        future: _myCoursesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('You are not enrolled in any courses yet.'),
            );
          }

          final courses = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: const Icon(Icons.play_circle_fill, size: 40, color: AppTheme.primaryColor),
                  title: Text(
                    course.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: course.progress / 100,
                        backgroundColor: Colors.grey[300],
                        color: Colors.green,
                      ),
                      const SizedBox(height: 4),
                      Text('${course.progress}% Completed'),
                    ],
                  ),
                  onTap: () {
                    // TODO: Navigate to Course Player Screen
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
