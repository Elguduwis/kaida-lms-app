import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/api_config.dart';
import '../config/app_theme.dart';
import 'course_player_screen.dart';
import 'catalog_screen.dart'; // To route them to explore if empty

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  List<dynamic> _myCourses = [];
  List<dynamic> _filteredCourses = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchMyCourses();
  }

  Future<void> _fetchMyCourses() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId == null) return;

    // 1. Instant Offline Load
    final cached = prefs.getString('cached_my_courses');
    if (cached != null) {
      final data = json.decode(cached);
      if (mounted) {
        setState(() {
          _myCourses = data;
          _filteredCourses = data;
          _isLoading = false;
        });
      }
    }

    // 2. Background Sync
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.myCourses),
        body: {'user_id': userId.toString()},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          prefs.setString('cached_my_courses', json.encode(data['data']));
          if (mounted) {
            setState(() {
              _myCourses = data['data'];
              _filterCourses(_searchQuery); // Re-apply search to fresh data
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      debugPrint("MyCourses Sync Error: $e");
      if (mounted && _myCourses.isEmpty) {
         setState(() => _isLoading = false);
      }
    }
  }

  void _filterCourses(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredCourses = _myCourses;
      } else {
        _filteredCourses = _myCourses.where((course) {
          final title = course['title']?.toString().toLowerCase() ?? '';
          final instructor = course['instructor_name']?.toString().toLowerCase() ?? '';
          final searchLower = query.toLowerCase();
          return title.contains(searchLower) || instructor.contains(searchLower);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // 1. Sleek App Bar
          const SliverAppBar(
            backgroundColor: AppTheme.primaryColor,
            elevation: 0,
            pinned: true,
            title: Text('My Learning', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
            centerTitle: true,
          ),

          // 2. Search Bar Section
          SliverToBoxAdapter(
            child: Container(
              color: AppTheme.primaryColor,
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
                ),
                child: TextField(
                  onChanged: _filterCourses,
                  decoration: InputDecoration(
                    hintText: 'Search my courses...',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              FocusScope.of(context).unfocus();
                              _filterCourses('');
                            },
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ),

          // 3. States (Loading, Empty, or List)
          if (_isLoading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)))
          else if (_myCourses.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.video_library_outlined, size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('No courses yet.', style: TextStyle(fontSize: 20, color: Colors.grey.shade800, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Enroll in a course to start your learning journey!', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        ),
                        onPressed: () {
                          // Jump to Explore screen
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const CatalogScreen(actionType: 'courses', title: 'Explore Courses')));
                        },
                        child: const Text('Explore Courses', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                ),
              ),
            )
          else if (_filteredCourses.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 60, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text('No matches found.', style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildCourseCard(_filteredCourses[index]),
                  childCount: _filteredCourses.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course) {
    String rawThumb = course['thumbnail_url']?.toString() ?? '';
    if (rawThumb.isNotEmpty && !rawThumb.startsWith('http')) {
      rawThumb = 'https://academy.kainuwa.africa/$rawThumb';
    }

    double progressRaw = double.tryParse(course['progress_percentage'].toString()) ?? 0.0;
    int progress = progressRaw.toInt();
    bool isCompleted = progress >= 100;
    bool hasStarted = progress > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.12), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(
            builder: (context) => CoursePlayerScreen(courseId: int.parse(course['id'].toString()), courseTitle: course['title'])
          ));
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail with Play Icon Overlay
            SizedBox(
              width: 120,
              height: 130,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  rawThumb.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: rawThumb,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Container(color: AppTheme.primaryColor, child: const Icon(Icons.school, color: Colors.white)),
                        )
                      : Container(color: AppTheme.primaryColor, child: const Icon(Icons.school, size: 40, color: Colors.white)),
                  Container(color: Colors.black.withOpacity(0.2)),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle),
                      child: Icon(isCompleted ? Icons.replay : Icons.play_arrow, color: AppTheme.primaryColor, size: 24),
                    ),
                  )
                ],
              ),
            ),

            // Details Section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course['title']?.toString() ?? 'Untitled', 
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, height: 1.2), 
                      maxLines: 2, 
                      overflow: TextOverflow.ellipsis
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.person, size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Expanded(child: Text(course['instructor_name']?.toString() ?? 'Kainuwa', style: TextStyle(color: Colors.grey.shade600, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Progress Bar
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress / 100,
                              backgroundColor: Colors.grey.shade200,
                              color: isCompleted ? Colors.green : AppTheme.primaryColor,
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('$progress%', style: TextStyle(color: isCompleted ? Colors.green : AppTheme.primaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isCompleted ? Colors.green.withOpacity(0.1) : (hasStarted ? AppTheme.primaryColor.withOpacity(0.1) : Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isCompleted ? 'Completed' : (hasStarted ? 'Continue Learning' : 'Start Course'),
                        style: TextStyle(
                          color: isCompleted ? Colors.green : (hasStarted ? AppTheme.primaryColor : Colors.grey.shade700),
                          fontSize: 10,
                          fontWeight: FontWeight.bold
                        ),
                      ),
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
}
