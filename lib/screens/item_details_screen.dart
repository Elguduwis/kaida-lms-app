import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/api_config.dart';
import '../config/app_theme.dart';
import '../widgets/kaida_loader.dart';
import 'catalog_screen.dart';

class ItemDetailsScreen extends StatefulWidget {
  final CatalogItem item;
  const ItemDetailsScreen({Key? key, required this.item}) : super(key: key);

  @override
  _ItemDetailsScreenState createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _isEnrolled = false;
  bool _isWishlisted = false;
  Map<String, dynamic>? _details;
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/course_details.php?slug=${widget.item.slug}&user_id=${userId ?? 0}'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          if (mounted) {
            setState(() {
              _details = data['data'];
              _isEnrolled = data['data']['is_enrolled'] == true;
              _isWishlisted = data['data']['is_wishlisted'] == true;
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleWishlist() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in to save courses.')));
      return;
    }

    setState(() => _isWishlisted = !_isWishlisted);

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.toggleWishlist),
        body: {'user_id': userId.toString(), 'item_id': widget.item.id.toString(), 'item_type': 'course'}
      );
      final data = json.decode(response.body);
      
      if (data['status'] != 'success') {
        setState(() => _isWishlisted = !_isWishlisted); // Revert
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Failed to update wishlist')));
      }
    } catch (e) {
      setState(() => _isWishlisted = !_isWishlisted); // Revert
    }
  }

  Widget _buildStatCard(IconData icon, String value, String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceColor : AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.grey.shade800 : AppTheme.primaryColor.withOpacity(0.1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 24),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Price Formatting
    String priceText = 'Free';
    if (!widget.item.isFree) {
       priceText = widget.item.discountPrice > 0 
           ? '₦${widget.item.discountPrice.toStringAsFixed(0)}' 
           : '₦${widget.item.price.toStringAsFixed(0)}';
    }

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackgroundColor : Colors.white,
      body: _isLoading
          ? const Center(child: KaidaLoader())
          : Stack(
              children: [
                NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      // Image & Header Elements
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top Image Stack
                            Stack(
                              children: [
                                Container(
                                  height: 250,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      image: CachedNetworkImageProvider(widget.item.thumbnailUrl),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                // Back Button
                                Positioned(
                                  top: MediaQuery.of(context).padding.top + 10,
                                  left: 16,
                                  child: GestureDetector(
                                    onTap: () => Navigator.pop(context),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: isDark ? Colors.black54 : Colors.white, shape: BoxShape.circle),
                                      child: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : Colors.black),
                                    ),
                                  ),
                                ),
                                // Wishlist Button
                                Positioned(
                                  top: MediaQuery.of(context).padding.top + 10,
                                  right: 16,
                                  child: GestureDetector(
                                    onTap: _toggleWishlist,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: isDark ? Colors.black54 : Colors.white, shape: BoxShape.circle),
                                      child: Icon(
                                        _isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded, 
                                        color: _isWishlisted ? Colors.redAccent : Colors.grey.shade600
                                      ),
                                    ),
                                  ),
                                ),
                                // Price Badge
                                Positioned(
                                  bottom: 16,
                                  right: 16,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(color: AppTheme.primaryColor, borderRadius: BorderRadius.circular(20)),
                                    child: Text(priceText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                  ),
                                ),
                              ],
                            ),
                            
                            // Info Section
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(widget.item.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.2)),
                                  const SizedBox(height: 12),
                                  
                                  Row(
                                    children: [
                                      const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                                      const SizedBox(width: 4),
                                      Text(_details?['review_summary']?['avg_rating']?.toString() ?? '4.5', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      const SizedBox(width: 4),
                                      Text('(${_details?['review_summary']?['total_reviews'] ?? '0'} reviews)', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                                      const SizedBox(width: 12),
                                      Container(height: 14, width: 1, color: Colors.grey.shade300),
                                      const SizedBox(width: 12),
                                      Text(widget.item.categoryName, style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 14)),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 24),
                                  
                                  // Stats Grid
                                  Row(
                                    children: [
                                      Expanded(child: _buildStatCard(Icons.people_alt_rounded, _details?['student_count']?.toString() ?? '0', 'Students', isDark)),
                                      const SizedBox(width: 12),
                                      Expanded(child: _buildStatCard(Icons.access_time_rounded, '25 hours', 'Duration', isDark)), // Mock duration if not in API
                                      const SizedBox(width: 12),
                                      Expanded(child: _buildStatCard(Icons.play_lesson_rounded, _details?['sections']?.length.toString() ?? '0', 'Modules', isDark)),
                                      const SizedBox(width: 12),
                                      Expanded(child: _buildStatCard(Icons.workspace_premium_rounded, 'Yes', 'Certificate', isDark)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // TabBar Header (Sticks to top when scrolling)
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _SliverAppBarDelegate(
                          TabBar(
                            controller: _tabController,
                            labelColor: AppTheme.primaryColor,
                            unselectedLabelColor: Colors.grey.shade500,
                            indicatorColor: AppTheme.primaryColor,
                            indicatorWeight: 3,
                            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            tabs: const [
                              Tab(text: 'About'),
                              Tab(text: 'Lessons'),
                              Tab(text: 'Reviews'),
                            ],
                          ),
                          isDark ? AppTheme.darkBackgroundColor : Colors.white,
                        ),
                      ),
                    ];
                  },
                  
                  // Tab Views
                  body: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAboutTab(isDark),
                      _buildLessonsTab(isDark),
                      _buildReviewsTab(isDark),
                    ],
                  ),
                ),
                
                // Bottom Fixed Enroll Button
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkBackgroundColor : Colors.white,
                      border: Border(top: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200)),
                    ),
                    child: SafeArea(
                      top: false,
                      child: SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: widget.item.isComingSoon ? null : () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          child: Text(
                            widget.item.isComingSoon ? 'Coming Soon' : (_isEnrolled ? 'Start Course' : 'Enroll Course $priceText'),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // --- ABOUT TAB ---
  Widget _buildAboutTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Instructor
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              radius: 25,
              backgroundImage: CachedNetworkImageProvider(_details?['course']?['instructor_avatar'] ?? ''),
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            ),
            title: Text(widget.item.instructorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Text(_details?['course']?['instructor_headline'] ?? 'Professional Instructor', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          ),
          const SizedBox(height: 24),
          const Text('About Course', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(
            _details?['course']?['description']?.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), '') ?? 'No description available.',
            style: TextStyle(color: isDark ? Colors.grey.shade300 : Colors.grey.shade700, height: 1.5, fontSize: 15),
          ),
        ],
      ),
    );
  }

  // --- LESSONS TAB ---
  Widget _buildLessonsTab(bool isDark) {
    // Mock parsing if exact structure isn't available, assumes a list of items
    List<dynamic> lessons = [];
    if (_details?['items_by_section'] != null) {
      _details!['items_by_section'].forEach((key, value) {
        lessons.addAll(value);
      });
    }

    if (lessons.isEmpty) {
      return Center(child: Text('Curriculum being updated.', style: TextStyle(color: Colors.grey.shade500)));
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      itemCount: lessons.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        var lesson = lessons[index];
        return Row(
          children: [
            // Thumbnail / Number Box
            Container(
              height: 56, width: 64,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: CachedNetworkImageProvider(widget.item.thumbnailUrl),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.6), BlendMode.darken),
                ),
              ),
              child: Center(
                child: Text(
                  (index + 1).toString().padLeft(2, '0'),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lesson['title'] ?? 'Lesson', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text('15:00 mins', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)), // Mock time
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
            ),
          ],
        );
      },
    );
  }

  // --- REVIEWS TAB ---
  Widget _buildReviewsTab(bool isDark) {
    List<dynamic> reviews = _details?['reviews'] ?? [];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rating Summary Header
          Row(
            children: [
              Column(
                children: [
                  Text(_details?['review_summary']?['avg_rating']?.toString() ?? '0.0', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
                  const Row(
                    children: [
                      Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                      Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                      Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                      Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                      Icon(Icons.star_half_rounded, color: Colors.amber, size: 16),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('(${_details?['review_summary']?['total_reviews'] ?? '0'} Reviews)', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                ],
              ),
              const SizedBox(width: 24),
              // Progress Bars
              Expanded(
                child: Column(
                  children: [5, 4, 3, 2, 1].map((star) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Text('$star', style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: star == 5 ? 0.7 : (star == 4 ? 0.2 : 0.05), // Mock distribution
                                backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                                minHeight: 6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 30),
          const Text('Reviews', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          if (reviews.isEmpty)
            Center(child: Text('No reviews yet.', style: TextStyle(color: Colors.grey.shade500))),
          
          ...reviews.map((r) => Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: CachedNetworkImageProvider(r['avatar_url'] ?? ''),
                      backgroundColor: Colors.grey.shade200,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r['full_name'] ?? 'Student', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Row(
                            children: [
                              ...List.generate(5, (i) => Icon(Icons.star_rounded, size: 14, color: i < (r['rating'] ?? 5) ? Colors.amber : Colors.grey.shade300)),
                              const SizedBox(width: 8),
                              Text('1 week ago', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)), // Mock date
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(r['review_text'] ?? '', style: TextStyle(color: isDark ? Colors.grey.shade300 : Colors.grey.shade700, fontSize: 14)),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }
}

// Utility class for pinning the TabBar
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  final Color _color;

  _SliverAppBarDelegate(this._tabBar, this._color);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: _color,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
