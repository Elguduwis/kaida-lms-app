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
  List<CatalogItem> _allCourses = [];
  
  // Using your exact name as requested
  final String _userName = "Osama"; 

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
      final response = await http.get(
        Uri.parse('https://academy.kainuwa.africa/api/mobile/catalog.php?action=courses'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          List<dynamic> list = data['data'];
          List<CatalogItem> parsedItems = [];
          for (var item in list) {
            try {
              parsedItems.add(CatalogItem.fromJson(item, 'courses'));
            } catch (e) {
              debugPrint("Parse error: $e");
            }
          }
          if (mounted) {
            setState(() {
              _allCourses = parsedItems;
              _isLoadingCatalog = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingCatalog = false);
    }
  }

  // Safely partitions the single catalog list into dynamic horizontal sections
  List<CatalogItem> _getSubList(int startIndex, int count) {
    if (_allCourses.isEmpty) return [];
    int safeStart = startIndex % _allCourses.length;
    List<CatalogItem> result = [];
    for(int i=0; i<count; i++) {
      if (i < _allCourses.length) {
         result.add(_allCourses[(safeStart + i) % _allCourses.length]);
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Kainuwa Academy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {}),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryColor,
        onRefresh: () async {
          await _fetchDashboardData();
          await _fetchCatalogData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Hero Header & Wallet
              _buildHeaderSection(),
              const SizedBox(height: 24),

              // 2. Categories Horizontal Chips
              _buildCategories(),
              const SizedBox(height: 24),

              // 3. Jump Back In (If user has a pending course)
              if (_dashboardData?['recent_course'] != null) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('Jump Back In', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildRecentCourseCard(_dashboardData!['recent_course']),
                ),
                const SizedBox(height: 30),
              ],

              // 4. Dynamic Horizontal Scroll Sections (The "Grid" views)
              if (_isLoadingCatalog)
                 const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: AppTheme.primaryColor)))
              else ...[
                _buildHorizontalSection('Featured Courses', _getSubList(0, 4), badgeText: 'FEATURED', badgeColor: Colors.orange),
                const SizedBox(height: 30),

                _buildHorizontalSection('Top Rated Courses', _getSubList(2, 5)),
                const SizedBox(height: 30),

                _buildHorizontalSection('Popular Now', _getSubList(1, 4), badgeText: 'HOT', badgeColor: Colors.redAccent),
                const SizedBox(height: 30),

                _buildHorizontalSection('Coming Soon', _getSubList(3, 2), isComingSoon: true),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Welcome Back, $_userName! 👋', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.account_balance_wallet, color: AppTheme.primaryColor, size: 20),
                        SizedBox(width: 8),
                        Text('My Wallet', style: TextStyle(color: Colors.black54, fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _isLoadingDashboard 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor))
                      : Text('${_dashboardData?['wallet_balance'] ?? '0'} KAIDA', style: const TextStyle(color: Colors.black87, fontSize: 26, fontWeight: FontWeight.bold)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: const Text('Top Up', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    final categories = ['Development', 'Design', 'Business', 'Marketing', 'Photography'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text('Top Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(categories[index], style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.w600)),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalSection(String title, List<CatalogItem> items, {String? badgeText, Color? badgeColor, bool isComingSoon = false}) {
    if (items.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Text('See All', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 250, // Height of the horizontal scroll area
          child: ListView.builder(
            scrollDirection: Axis.horizontal, // Enables left/right scrolling
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return _buildHorizontalCard(items[index], badgeText, badgeColor, isComingSoon);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalCard(CatalogItem item, String? badgeText, Color? badgeColor, bool isComingSoon) {
    return Container(
      width: 200, // Width of each individual card
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (!isComingSoon) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => ItemDetailsScreen(item: item)));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This course is launching soon!')));
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                item.thumbnailUrl.isNotEmpty
                    ? Image.network(item.thumbnailUrl, height: 110, width: double.infinity, fit: BoxFit.cover)
                    : Container(height: 110, color: AppTheme.primaryColor, child: const Icon(Icons.school, size: 40, color: Colors.white)),
                if (badgeText != null)
                  Positioned(
                    top: 8, left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(8)),
                      child: Text(badgeText, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                if (isComingSoon)
                  Container(
                    height: 110, width: double.infinity,
                    color: Colors.black.withOpacity(0.6),
                    child: const Center(child: Icon(Icons.lock_clock, color: Colors.white, size: 30)),
                  )
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.categoryName.toUpperCase(), style: const TextStyle(color: AppTheme.primaryColor, fontSize: 9, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(item.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.person, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(child: Text(item.instructorName, style: TextStyle(color: Colors.grey[600], fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildPriceDisplay(item, isComingSoon),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceDisplay(CatalogItem item, bool isComingSoon) {
    if (isComingSoon) return const Text('Coming Soon', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13));
    
    if (item.isFree || (item.price == 0 && item.discountPrice == 0)) {
      return const Text('FREE', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13));
    }
    if (item.discountPrice > 0 && item.discountPrice < item.price) {
      return Row(
        children: [
          Text('₦${item.discountPrice.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryColor)),
          const SizedBox(width: 4),
          Text('₦${item.price.toStringAsFixed(0)}', style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey, fontSize: 10)),
        ],
      );
    }
    return Text('₦${item.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryColor));
  }

  Widget _buildRecentCourseCard(Map<String, dynamic> course) {
    String rawThumb = course['thumbnail_url']?.toString() ?? '';
    if (rawThumb.isNotEmpty && !rawThumb.startsWith('http')) {
      rawThumb = 'https://academy.kainuwa.africa/$rawThumb';
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
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
                    Text(course['title'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: double.parse(course['progress_percentage'].toString()) / 100,
                      backgroundColor: Colors.grey[200],
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(height: 4),
                    Text('${course['progress_percentage']}% Complete', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
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
