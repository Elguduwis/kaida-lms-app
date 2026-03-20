import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../config/app_theme.dart';
import 'course_player_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  bool _isOffline = false;
  List<dynamic> _myCourses = [];

  @override
  void initState() {
    super.initState();
    _fetchMyCourses();
  }

  Future<void> _fetchMyCourses() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId == null) return;

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.myCourses),
        body: {'user_id': userId.toString()},
      ).timeout(const Duration(seconds: 10)); // 10 second timeout

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          // SAVE TO OFFLINE CACHE!
          prefs.setString('cached_my_courses', json.encode(data['data']));
          if (mounted) {
            setState(() {
              _myCourses = data['data'];
              _isOffline = false;
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      // OFFLINE SURVIVAL MODE KICKS IN
      debugPrint("Network Error, loading from cache...");
      final cachedData = prefs.getString('cached_my_courses');
      if (cachedData != null) {
        if (mounted) {
          setState(() {
            _myCourses = json.decode(cachedData);
            _isOffline = true;
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offline Mode: Showing saved courses'), backgroundColor: Colors.orange));
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('My Learning', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (_isOffline) const Padding(padding: EdgeInsets.all(16.0), child: Icon(Icons.cloud_off, color: Colors.orange)),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
        : RefreshIndicator(
            onRefresh: _fetchMyCourses,
            child: _myCourses.isEmpty
              ? const Center(child: Text('You are not enrolled in any courses yet.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _myCourses.length,
                  itemBuilder: (context, index) {
                    final course = _myCourses[index];
                    String rawThumb = course['thumbnail_url']?.toString() ?? '';
                    if (rawThumb.isNotEmpty && !rawThumb.startsWith('http')) rawThumb = 'https://academy.kainuwa.africa/' + rawThumb;

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => CoursePlayerScreen(courseId: int.parse(course['id'].toString()), courseTitle: course['title'])));
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            rawThumb.isNotEmpty 
                                ? Image.network(rawThumb, height: 160, width: double.infinity, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(height: 160, color: Colors.grey))
                                : Container(height: 160, color: AppTheme.primaryColor, child: const Icon(Icons.school, size: 50, color: Colors.white)),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(course['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 12),
                                  LinearProgressIndicator(
                                    value: double.parse(course['progress_percentage'].toString()) / 100,
                                    backgroundColor: Colors.grey[200],
                                    color: AppTheme.primaryColor,
                                    minHeight: 8,
                                  ),
                                  const SizedBox(height: 8),
                                  Text('${course['progress_percentage']}% Complete', style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ),
    );
  }
}
