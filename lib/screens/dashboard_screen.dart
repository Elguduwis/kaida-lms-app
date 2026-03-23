import '../widgets/kaida_loader.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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
  final TextEditingController _searchController = TextEditingController();

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
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          prefs.setString('cached_my_courses', json.encode(data['data']));
          if (mounted) {
            setState(() {
              _myCourses = data['data'];
              _filterCourses(_searchQuery); // re-apply search if exists
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterCourses(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredCourses = _myCourses;
      } else {
        _filteredCourses = _myCourses.where((course) {
          final title = course['title'].toString().toLowerCase();
          final instructor = course['instructor_name'].toString().toLowerCase();
          final searchLower = query.toLowerCase();
          return title.contains(searchLower) || instructor.contains(searchLower);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic Theme Detectors
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Learning'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildSearchBar(isDark, textColor, subTextColor),
          Expanded(
            child: _isLoading 
              ? const Center(child: KaidaLoader())
              : RefreshIndicator(
                  color: AppTheme.primaryColor,
                  onRefresh: _fetchMyCourses,
                  child: _filteredCourses.isEmpty
                      ? _buildEmptyState(textColor)
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _filteredCourses.length,
                          itemBuilder: (context, index) {
                            return _buildCourseCard(_filteredCourses[index], isDark, textColor, subTextColor);
                          },
                        ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark, Color textColor, Color subTextColor) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade800 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300)
        ),
        child: TextField(
          controller: _searchController,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: 'Search my courses...',
            hintStyle: TextStyle(color: subTextColor),
            prefixIcon: Icon(Icons.search, color: subTextColor),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: subTextColor),
                    onPressed: () {
                      _searchController.clear();
                      _filterCourses('');
                      FocusScope.of(context).unfocus();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          onChanged: _filterCourses,
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color textColor) {
    bool hasNoCoursesAtAll = _myCourses.isEmpty && _searchQuery.isEmpty;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasNoCoursesAtAll ? Icons.school_outlined : Icons.search_off, 
            size: 64, 
            color: Colors.grey.shade400
          ),
          const SizedBox(height: 16),
          Text(
            hasNoCoursesAtAll ? 'You haven\'t enrolled yet' : 'No courses found', 
            style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 8),
          Text(
            hasNoCoursesAtAll ? 'Start your learning journey today!' : 'Try a different search term', 
            style: TextStyle(color: Colors.grey.shade500)
          ),
          const SizedBox(height: 24),
          if (hasNoCoursesAtAll)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                // Route to catalog tab
                Navigator.pushReplacement(
                  context, 
                  MaterialPageRoute(builder: (context) => const CatalogScreen(actionType: 'courses', title: 'Explore Courses'))
                );
              },
              child: const Text('Explore Courses', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course, bool isDark, Color textColor, Color subTextColor) {
    String rawThumb = course['thumbnail_url']?.toString() ?? '';
    if (rawThumb.isNotEmpty && !rawThumb.startsWith('http')) {
      rawThumb = 'https://academy.kainuwa.africa/$rawThumb';
    }

    int progress = int.tryParse(course['progress_percentage']?.toString() ?? '0') ?? 0;
    bool isCompleted = progress >= 100;
    bool hasStarted = progress > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      // Card color is handled by our app_theme.dart!
      child: InkWell(
        onTap: () {
          Navigator.push(
            context, 
            MaterialPageRoute(
              builder: (context) => CoursePlayerScreen(
                courseId: int.parse(course['id'].toString()), 
                courseTitle: course['title']
              )
            )
          ).then((value) => _fetchMyCourses()); // Refresh progress when returning
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            SizedBox(
              height: 110,
              width: 110,
              child: rawThumb.isNotEmpty
                  ? Image.network(rawThumb, fit: BoxFit.cover)
                  : Container(color: AppTheme.primaryColor, child: const Icon(Icons.play_circle_fill, color: Colors.white, size: 40)),
            ),
            
            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course['title'], 
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor), 
                      maxLines: 2, 
                      overflow: TextOverflow.ellipsis
                    ),
                    const SizedBox(height: 4),
                    Text(
                      course['instructor_name'], 
                      style: TextStyle(color: subTextColor, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                              backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey[200],
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
                        color: isCompleted 
                            ? Colors.green.withOpacity(isDark ? 0.2 : 0.1) 
                            : (hasStarted ? AppTheme.primaryColor.withOpacity(isDark ? 0.2 : 0.1) : (isDark ? Colors.grey.shade800 : Colors.grey.shade100)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isCompleted ? 'Completed' : (hasStarted ? 'Continue Learning' : 'Start Course'),
                        style: TextStyle(
                          color: isCompleted 
                              ? (isDark ? Colors.green.shade400 : Colors.green) 
                              : (hasStarted ? (isDark ? Colors.purple.shade300 : AppTheme.primaryColor) : subTextColor),
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
