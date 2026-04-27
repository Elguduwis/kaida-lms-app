import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/api_config.dart';
import '../config/app_theme.dart';
import '../widgets/kaida_loader.dart';
import 'course_player_screen.dart';
import 'catalog_screen.dart';
import 'item_details_screen.dart';
import 'categories_screen.dart';
import 'instructor_profile_screen.dart';

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
  List<CatalogItem> _comingSoonCourses = [];
  Set<int> _wishlistedCourseIds = {}; // Tracks wishlists securely in RAM
  
  String _userName = "Learner"; 
  String? _userAvatar;

  List<dynamic> _banners = [];
  List<dynamic> _categories = [];
  List<dynamic> _instructors = [];

  final PageController _bannerController = PageController();
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
    _fetchCatalogData();
    _fetchWishlist();
    _startBannerTimer();
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  void _startBannerTimer() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (_bannerController.hasClients && _banners.isNotEmpty) {
        int nextIndex = _currentBannerIndex + 1;
        if (nextIndex >= _banners.length) nextIndex = 0;
        _bannerController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  Future<void> _fetchWishlist() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId == null) return;
    try {
      final response = await http.post(Uri.parse(ApiConfig.getWishlist), body: {'user_id': userId.toString()});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && mounted) {
          setState(() {
            _wishlistedCourseIds = (data['data'] as List)
                .where((item) => item['item_type'] == 'course')
                .map<int>((item) => int.tryParse(item['item_id'].toString()) ?? 0)
                .toSet();
          });
        }
      }
    } catch (e) {
      debugPrint("Wishlist fetch error: $e");
    }
  }

  Future<void> _toggleWishlist(int courseId) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in to save courses.')));
      return;
    }

    final isCurrentlyWishlisted = _wishlistedCourseIds.contains(courseId);
    
    // Optimistic UI Update for instant feedback
    setState(() {
      if (isCurrentlyWishlisted) _wishlistedCourseIds.remove(courseId);
      else _wishlistedCourseIds.add(courseId);
    });

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.toggleWishlist),
        body: {'user_id': userId.toString(), 'item_id': courseId.toString(), 'item_type': 'course'}
      );
      final data = json.decode(response.body);
      
      if (data['status'] != 'success') {
        // Revert if API failed
        setState(() {
          if (isCurrentlyWishlisted) _wishlistedCourseIds.add(courseId);
          else _wishlistedCourseIds.remove(courseId);
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Action failed.')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message']), backgroundColor: Colors.green, duration: const Duration(seconds: 1)));
      }
    } catch (e) {
      // Revert on connection error
      setState(() {
        if (isCurrentlyWishlisted) _wishlistedCourseIds.add(courseId);
        else _wishlistedCourseIds.remove(courseId);
      });
    }
  }

  Future<void> _fetchDashboardData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      final savedName = prefs.getString('full_name') ?? prefs.getString('name') ?? prefs.getString('username') ?? "Learner";
      
      if (mounted) setState(() {
        _userName = savedName;
        _userAvatar = prefs.getString('avatar_url'); 
      });
      
      if (userId == null) return;

      final response = await http.post(Uri.parse(ApiConfig.dashboardData), body: {'user_id': userId.toString()});

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && mounted) {
          setState(() {
            _dashboardData = data['data'];
            _banners = data['data']['banners'] ?? [];
            _categories = data['data']['categories'] ?? [];
            _instructors = data['data']['instructors'] ?? [];
            
            if (data['data']['user'] != null && data['data']['user']['avatar_url'] != null) {
              _userAvatar = data['data']['user']['avatar_url'];
              prefs.setString('avatar_url', _userAvatar!);
            }
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
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/catalog.php?action=courses'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          List<dynamic> list = data['data'];
          List<CatalogItem> active = [];
          List<CatalogItem> coming = [];
          DateTime now = DateTime.now();
          
          for (var item in list) {
            try {
              bool isComingSoon = false;
              if (item['release_date'] != null) {
                DateTime? release = DateTime.tryParse(item['release_date'].toString());
                if (release != null && release.isAfter(now)) isComingSoon = true;
              }
              CatalogItem parsed = CatalogItem.fromJson(item, 'courses');
              if (isComingSoon) coming.add(parsed); else active.add(parsed);
            } catch (e) {}
          }
          if (mounted) {
            setState(() {
              _activeCourses = active;
              _comingSoonCourses = coming;
              _isLoadingCatalog = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingCatalog = false);
    }
  }

  List<CatalogItem> _getSubList(List<CatalogItem> source, int startIndex, int count) {
    if (source.isEmpty) return [];
    int safeStart = startIndex % source.length;
    List<CatalogItem> result = [];
    for(int i=0; i<count; i++) {
      if (i < source.length) result.add(source[(safeStart + i) % source.length]);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackgroundColor : Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primaryColor,
          onRefresh: () async {
            await _fetchDashboardData();
            await _fetchCatalogData();
            await _fetchWishlist();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopHeader(isDark),
                
                if (_banners.isNotEmpty) _buildBannerCarousel(),

                if (_categories.isNotEmpty) _buildCategoriesRow(isDark)
                else _buildFallbackCategoriesRow(isDark), 

                const SizedBox(height: 24),

                if (_isLoadingCatalog)
                   const Center(child: Padding(padding: EdgeInsets.all(40), child: KaidaLoader()))
                else ...[
                  _buildCourseHorizontalList('Featured Courses', _getSubList(_activeCourses, 0, 4), isDark),
                  const SizedBox(height: 24),
                  
                  if (_instructors.isNotEmpty) _buildInstructorsRow(isDark)
                  else _buildFallbackInstructorsRow(isDark), 

                  const SizedBox(height: 24),
                  _buildCourseHorizontalList('Popular Now', _getSubList(_activeCourses, 2, 4), isDark),
                  
                  if (_comingSoonCourses.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildCourseHorizontalList('Coming Soon', _comingSoonCourses, isDark, isComingSoon: true),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader(bool isDark) {
    String safeAvatar = _userAvatar ?? '';
    if (safeAvatar.isNotEmpty && !safeAvatar.startsWith('http')) {
      safeAvatar = 'https://academy.kainuwa.africa/$safeAvatar';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Row(mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            backgroundImage: safeAvatar.isNotEmpty ? NetworkImage(safeAvatar) : null,
            child: safeAvatar.isEmpty ? const Icon(Icons.person_rounded, color: AppTheme.primaryColor) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_getGreeting(), style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w600)),
                Text(_userName, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade200)),
            child: const Icon(Icons.search_rounded, size: 20),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade200)),
            child: const Icon(Icons.notifications_none_rounded, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerCarousel() {
    return Stack(
      alignment: Alignment.bottomLeft,
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _bannerController,
            onPageChanged: (index) {
              setState(() => _currentBannerIndex = index);
            },
            itemCount: _banners.length,
            itemBuilder: (context, index) {
              final banner = _banners[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(image: NetworkImage(banner['image_url']), fit: BoxFit.cover),
                ),
              );
            },
          ),
        ),
        // Bottom Left Animated Dots
        Positioned(
          bottom: 12,
          left: 0, right: 0,
          child: Row(mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _banners.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(right: 6),
                height: 6,
                width: _currentBannerIndex == index ? 20 : 6,
                decoration: BoxDecoration(
                  color: _currentBannerIndex == index ? AppTheme.primaryColor : Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesRow(bool isDark) {
    return _buildCategoryTemplate(_categories, isDark);
  }

  Widget _buildFallbackCategoriesRow(bool isDark) {
    final defaultCats = [
      {'id': '1', 'name': 'Coding', 'icon': Icons.code_rounded},
      {'id': '2', 'name': 'Design', 'icon': Icons.brush_rounded},
      {'id': '3', 'name': 'Business', 'icon': Icons.business_center_rounded},
      {'id': '4', 'name': 'Marketing', 'icon': Icons.campaign_rounded},
    ];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Row(mainAxisAlignment: MainAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriesScreen())),
                child: const Text('See All', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: defaultCats.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CatalogScreen(actionType: 'category_${defaultCats[index]['id']}', title: defaultCats[index]['name'] as String))),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                        child: Icon(defaultCats[index]['icon'] as IconData, color: AppTheme.primaryColor, size: 24),
                      ),
                      const SizedBox(height: 8),
                      Text(defaultCats[index]['name'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryTemplate(List<dynamic> cats, bool isDark) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Row(mainAxisAlignment: MainAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriesScreen())),
                child: const Text('See All', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: cats.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  // Passes the category action to Catalog Screen
                  Navigator.push(context, MaterialPageRoute(builder: (_) => CatalogScreen(actionType: 'category_${cats[index]['id']}', title: cats[index]['name'])));
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.category_rounded, color: AppTheme.primaryColor, size: 24),
                      ),
                      const SizedBox(height: 8),
                      Text(cats[index]['name'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackInstructorsRow(bool isDark) {
    final defaultInstructors = ['Mal. Ibrahim', 'Osama Elguduwis', 'Ummulkhairi'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text('Top Instructors', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: defaultInstructors.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => InstructorProfileScreen(instructor: {'name': defaultInstructors[index]}))),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    children: [
                      CircleAvatar(radius: 30, backgroundColor: AppTheme.primaryColor.withOpacity(0.1), child: const Icon(Icons.person_rounded, color: AppTheme.primaryColor)),
                      const SizedBox(height: 8),
                      Text(defaultInstructors[index], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInstructorsRow(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text('Top Instructors', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _instructors.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => InstructorProfileScreen(instructor: _instructors[index]))),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 30, 
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1), 
                        backgroundImage: _instructors[index]['avatar_url'] != null ? NetworkImage(_instructors[index]['avatar_url']) : null,
                        child: _instructors[index]['avatar_url'] == null ? const Icon(Icons.person_rounded, color: AppTheme.primaryColor) : null,
                      ),
                      const SizedBox(height: 8),
                      Text(_instructors[index]['name'] ?? 'Instructor', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCourseHorizontalList(String title, List<CatalogItem> items, bool isDark, {bool isComingSoon = false}) {
    if (items.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(mainAxisAlignment: MainAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CatalogScreen(actionType: 'courses', title: 'Explore Courses'))),
                child: const Text('See All', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 260, 
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            itemBuilder: (context, index) => _buildCourseCard(items[index], isDark, isComingSoon),
          ),
        ),
      ],
    );
  }

  Widget _buildCourseCard(CatalogItem item, bool isDark, bool isComingSoon) {
    int discountPercent = 0;
    if (item.price > 0 && item.discountPrice > 0 && item.discountPrice < item.price) {
      discountPercent = (((item.price - item.discountPrice) / item.price) * 100).round();
    }
    
    bool isWishlisted = _wishlistedCourseIds.contains(item.id);

    return GestureDetector(
      onTap: () {
        if (!isComingSoon) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => ItemDetailsScreen(item: item)));
        }
      },
      child: Container(
        width: 220, 
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurfaceColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: isDark ? Colors.black12 : Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail & Overlays
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: item.thumbnailUrl.isNotEmpty
                      ? CachedNetworkImage(imageUrl: item.thumbnailUrl, height: 120, width: double.infinity, fit: BoxFit.cover)
                      : Container(height: 120, color: AppTheme.primaryColor.withOpacity(0.2), child: const Icon(Icons.school_rounded, size: 40, color: AppTheme.primaryColor)),
                ),
                
                // Discount Badge (Top Left)
                if (discountPercent > 0 && !isComingSoon)
                  Positioned(
                    top: 10, left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(8)),
                      child: Text('-$discountPercent%', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  
                // Wishlist Button (Top Right)
                if (!isComingSoon)
                  Positioned(
                    top: 8, right: 8,
                    child: GestureDetector(
                      onTap: () => _toggleWishlist(item.id),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black54 : Colors.white.withOpacity(0.9), 
                          shape: BoxShape.circle
                        ),
                        child: Icon(
                          isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isWishlisted ? Colors.redAccent : Colors.grey.shade600,
                          size: 18,
                        ),
                      ),
                    ),
                  ),

                if (isComingSoon)
                  Container(height: 120, color: Colors.black54, child: const Center(child: Icon(Icons.lock_clock_rounded, color: Colors.white, size: 30))),
              ],
            ),
            
            // Content Body
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(item.categoryName.toUpperCase(), style: const TextStyle(color: AppTheme.primaryColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5), overflow: TextOverflow.ellipsis)),
                      // Language Label moved from Thumbnail to Card Body
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                        child: Text(item.language.toUpperCase(), style: const TextStyle(color: AppTheme.primaryColor, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(item.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  
                  Row(
                    children: [
                      const Icon(Icons.person_rounded, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(child: Text(item.instructorName, style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  if (isComingSoon)
                    const Text('COMING SOON', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13))
                  else if (item.isFree || (item.price == 0 && item.discountPrice == 0))
                    const Text('FREE', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14))
                  else if (item.discountPrice > 0 && item.discountPrice < item.price)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('₦${item.discountPrice.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.primaryColor)),
                        const SizedBox(width: 6),
                        Text('₦${item.price.toStringAsFixed(0)}', style: TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey.shade400, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    )
                  else
                    Text('₦${item.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.primaryColor)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
