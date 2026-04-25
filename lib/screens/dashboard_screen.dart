import '../widgets/kaida_loader.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../config/app_theme.dart';
import 'course_player_screen.dart';
import 'catalog_screen.dart';

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
    final textColor = isDark ? Colors.white : AppTheme.secondaryColor;
    final subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final bgColor = isDark ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Modern Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
              child: Text(
                'My Learning', 
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: textColor, letterSpacing: -0.5)
              ),
            ),
            
            _buildSearchBar(isDark, textColor, subTextColor),
            
            Expanded(
              child: _isLoading 
                ? const Center(child: KaidaLoader())
                : RefreshIndicator(
                    color: AppTheme.primaryColor,
                    backgroundColor: isDark ? AppTheme.darkSurfaceColor : Colors.white,
                    onRefresh: _fetchMyCourses,
                    child: _filteredCourses.isEmpty
                        ? _buildEmptyState(textColor)
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            itemCount: _filteredCourses.length,
                            itemBuilder: (context, index) {
                              return _buildModernCourseCard(_filteredCourses[index], isDark, textColor, subTextColor);
                            },
                          ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark, Color textColor, Color subTextColor) {
    final inputFillColor = isDark ? Colors.grey.shade900 : Colors.white;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Container(
        decoration: BoxDecoration(
          color: inputFillColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.08), 
              blurRadius: 15, 
              offset: const Offset(0, 5)
            )
          ],
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.transparent)
        ),
        child: TextField(
          controller: _searchController,
          style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: 'Search my courses...',
            hintStyle: TextStyle(color: subTextColor.withOpacity(0.6), fontSize: 15, fontWeight: FontWeight.w500),
            prefixIcon: Icon(Icons.search_rounded, color: subTextColor, size: 22),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear_rounded, color: subTextColor, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      _filterCourses('');
                      FocusScope.of(context).unfocus();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
          onChanged: _filterCourses,
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color textColor) {
    bool hasNoCoursesAtAll = _myCourses.isEmpty && _searchQuery.isEmpty;
    
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasNoCoursesAtAll ? Icons.school_rounded : Icons.search_off_rounded, 
                size: 60, 
                color: AppTheme.primaryColor
              ),
            ),
            const SizedBox(height: 24),
            Text(
              hasNoCoursesAtAll ? 'Ready to start learning?' : 'No courses found', 
              style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.w800)
            ),
            const SizedBox(height: 8),
            Text(
              hasNoCoursesAtAll ? 'Explore the catalog to find your first course.' : 'Try adjusting your search terms.', 
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14, fontWeight: FontWeight.w500)
            ),
            const SizedBox(height: 32),
            if (hasNoCoursesAtAll)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  shadowColor: AppTheme.primaryColor.withOpacity(0.4),
                ),
                onPressed: () {
                  Navigator.pushReplacement(
                    context, 
                    MaterialPageRoute(builder: (context) => const CatalogScreen(actionType: 'courses', title: 'Explore Courses'))
                  );
                },
                child: const Text('Explore Courses', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernCourseCard(Map<String, dynamic> course, bool isDark, Color textColor, Color subTextColor) {
    String rawThumb = course['thumbnail_url']?.toString() ?? '';
    if (rawThumb.isNotEmpty && !rawThumb.startsWith('http')) {
      rawThumb = 'https://academy.kainuwa.africa/$rawThumb';
    }

    int progress = int.tryParse(course['progress_percentage']?.toString() ?? '0') ?? 0;
    bool isCompleted = progress >= 100;
    bool hasStarted = progress > 0;

    final cardColor = isDark ? AppTheme.darkSurfaceColor : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.4) : Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
          width: 1.5
        )
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            Navigator.push(
              context, 
              MaterialPageRoute(
                builder: (context) => CoursePlayerScreen(
                  courseId: int.parse(course['id'].toString()), 
                  courseTitle: course['title']
                )
              )
            ).then((value) => _fetchMyCourses()); 
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // PERFECTLY CONTAINED THUMBNAIL (Solves the clipping issue)
                Container(
                  height: 110,
                  width: 100,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    image: rawThumb.isNotEmpty ? DecorationImage(
                      image: NetworkImage(rawThumb),
                      fit: BoxFit.cover,
                    ) : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 2)
                      )
                    ]
                  ),
                  child: rawThumb.isEmpty 
                    ? const Icon(Icons.play_circle_fill, color: AppTheme.primaryColor, size: 40) 
                    : null,
                ),
                
                const SizedBox(width: 16),
                
                // COURSE DETAILS
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        course['title'], 
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor, height: 1.2), 
                        maxLines: 2, 
                        overflow: TextOverflow.ellipsis
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.person, size: 12, color: subTextColor),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              course['instructor_name'], 
                              style: TextStyle(color: subTextColor, fontSize: 12, fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      
                      // MODERN THICK PROGRESS BAR
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: progress / 100,
                                backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                                color: isCompleted ? Colors.green.shade500 : AppTheme.primaryColor,
                                minHeight: 8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '$progress%', 
                            style: TextStyle(
                              color: isCompleted ? Colors.green.shade500 : AppTheme.primaryColor, 
                              fontSize: 13, 
                              fontWeight: FontWeight.w900
                            )
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // SLEEK ACTION BADGE
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isCompleted 
                              ? Colors.green.withOpacity(isDark ? 0.15 : 0.1) 
                              : (hasStarted ? AppTheme.primaryColor.withOpacity(isDark ? 0.15 : 0.1) : Colors.grey.withOpacity(isDark ? 0.2 : 0.1)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isCompleted ? 'Completed' : (hasStarted ? 'Continue Learning' : 'Start Course'),
                          style: TextStyle(
                            color: isCompleted 
                                ? (isDark ? Colors.green.shade400 : Colors.green.shade700) 
                                : (hasStarted ? (isDark ? Colors.purple.shade300 : AppTheme.primaryColor) : subTextColor),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
