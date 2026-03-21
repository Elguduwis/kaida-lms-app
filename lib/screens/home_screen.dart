import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../config/app_theme.dart';
import 'course_player_screen.dart';
import 'catalog_screen.dart';
import 'item_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoadingDashboard = true;
  bool _isLoadingCatalog = true;
  Map<String, dynamic>? _dashboardData;
  
  List<CatalogItem> _activeCourses = [];
  String _userName = "Osama"; // You can later sync this dynamically from SharedPreferences

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
    _fetchCatalogData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      if (userId == null) return;

      final response = await http.post(
        Uri.parse(ApiConfig.dashboardData),
        body: {'user_id': userId.toString()},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && mounted) {
          setState(() {
            _dashboardData = data['data'];
            _isLoadingDashboard = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingDashboard = false);
    }
  }

  Future<void> _fetchCatalogData() async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.courses}?action=courses'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && mounted) {
          final List<dynamic> coursesJson = data['data'];
          setState(() {
            _activeCourses = coursesJson
                .map((json) => CatalogItem.fromJson(json, 'courses'))
                .where((item) => !item.isComingSoon)
                .toList();
            _isLoadingCatalog = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingCatalog = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Detect if we are currently in Dark Mode
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // 2. Define dynamic text colors based on the mode
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Scaffold(
      // The Scaffold background color is now controlled automatically by app_theme.dart!
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Let the scaffold color show through
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hello, $_userName 👋', style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold)),
            Text('Ready to learn something new today?', style: TextStyle(color: subtitleColor, fontSize: 12)),
          ],
        ),
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryColor,
        onRefresh: () async {
          await _fetchDashboardData();
          await _fetchCatalogData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatsCard(),
              const SizedBox(height: 24),
              
              if (_dashboardData != null && _dashboardData!['recent_course'] != null) ...[
                Text('Continue Learning', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildRecentCourseCard(_dashboardData!['recent_course'], isDark),
                const SizedBox(height: 24),
              ],
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recommended for you', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {
                      // Handled by BottomNavigationBar natively
                    },
                    child: const Text('See All', style: TextStyle(color: AppTheme.primaryColor)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              _isLoadingCatalog
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                  : _buildRecommendedCourses(isDark, textColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    if (_isLoadingDashboard) return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
    
    final balance = _dashboardData?['wallet_balance']?.toString() ?? '0.00';
    final enrolled = _dashboardData?['total_enrolled']?.toString() ?? '0';
    final completed = _dashboardData?['total_completed']?.toString() ?? '0';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor, // Keeps its vibrant purple branding in both modes
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('KAIDA Wallet Balance', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text('₦$balance', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('Enrolled', enrolled),
              _buildStatItem('Completed', completed),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildRecentCourseCard(Map<String, dynamic> course, bool isDark) {
    String rawThumb = course['thumbnail_url']?.toString() ?? '';
    if (rawThumb.isNotEmpty && !rawThumb.startsWith('http')) {
      rawThumb = 'https://academy.kainuwa.africa/$rawThumb';
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      // Card automatically uses Theme.of(context).cardColor from our app_theme.dart!
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => CoursePlayerScreen(courseId: int.parse(course['id'].toString()), courseTitle: course['title'])));
        },
        child: Row(
          children: [
            rawThumb.isNotEmpty
                ? Image.network(rawThumb, height: 100, width: 100, fit: BoxFit.cover)
                : Container(height: 100, width: 100, color: AppTheme.primaryColor, child: const Icon(Icons.play_circle_fill, color: Colors.white, size: 40)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course['title'], 
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87), 
                      maxLines: 2, 
                      overflow: TextOverflow.ellipsis
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: double.parse(course['progress_percentage'].toString()) / 100,
                      backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey[200],
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${course['progress_percentage']}% Complete', 
                      style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey[600], fontSize: 11)
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendedCourses(bool isDark, Color textColor) {
    if (_activeCourses.isEmpty) {
      return const Text('No courses available right now.', style: TextStyle(color: Colors.grey));
    }

    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _activeCourses.length > 5 ? 5 : _activeCourses.length,
        itemBuilder: (context, index) {
          final course = _activeCourses[index];
          return Container(
            width: 160,
            margin: const EdgeInsets.only(right: 16),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ItemDetailsScreen(item: course)));
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    course.thumbnailUrl.isNotEmpty
                        ? Image.network(course.thumbnailUrl, height: 100, width: double.infinity, fit: BoxFit.cover)
                        : Container(height: 100, width: double.infinity, color: AppTheme.primaryColor, child: const Icon(Icons.image, color: Colors.white)),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course.title, 
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor), 
                            maxLines: 2, 
                            overflow: TextOverflow.ellipsis
                          ),
                          const SizedBox(height: 8),
                          Text('₦${course.price.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
