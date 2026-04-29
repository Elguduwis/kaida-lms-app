import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import '../config/api_config.dart';
import '../config/app_theme.dart';
import '../widgets/kaida_loader.dart';
import 'catalog_screen.dart';
import 'item_details_screen.dart';

class InstructorProfileScreen extends StatefulWidget {
  final Map<String, dynamic> instructor;
  const InstructorProfileScreen({Key? key, required this.instructor}) : super(key: key);

  @override
  _InstructorProfileScreenState createState() => _InstructorProfileScreenState();
}

class _InstructorProfileScreenState extends State<InstructorProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _fullDetails;
  List<CatalogItem> _courses = [];

  @override
  void initState() {
    super.initState();
    _fetchInstructorData();
  }

  Future<void> _fetchInstructorData() async {
    final instructorId = widget.instructor['id']?.toString() ?? '0';
    if (instructorId == '0') {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await http.get(Uri.parse('${ApiConfig.getInstructor}?id=$instructorId'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && mounted) {
          setState(() {
            _fullDetails = data['data']['instructor'];
            List<dynamic> coursesJson = data['data']['courses'] ?? [];
            _courses = coursesJson.map((c) => CatalogItem.fromJson(c, 'courses')).toList();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Instructor fetch error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty) return '';
    return rawUrl.startsWith('http') ? rawUrl : 'https://academy.kainuwa.africa/$rawUrl';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    String avatarUrl = _formatUrl(widget.instructor['avatar_url']);
    String name = widget.instructor['name'] ?? 'Instructor';
    String coverUrl = '';
    String headline = '';
    String bio = '';
    bool isVerified = false;
    int totalStudents = 0;
    int totalReviews = 0;
    int totalCourses = 0;

    if (_fullDetails != null) {
      avatarUrl = _formatUrl(_fullDetails!['avatar_url']);
      coverUrl = _formatUrl(_fullDetails!['cover_photo_url']);
      name = _fullDetails!['full_name'] ?? _fullDetails!['username'] ?? name;
      headline = _fullDetails!['headline'] ?? '';
      bio = _fullDetails!['bio'] ?? '';
      isVerified = _fullDetails!['is_verified_instructor'] == 1 || _fullDetails!['is_verified_instructor'] == '1';
      totalStudents = int.tryParse(_fullDetails!['total_students']?.toString() ?? '0') ?? 0;
      totalReviews = int.tryParse(_fullDetails!['total_reviews']?.toString() ?? '0') ?? 0;
      totalCourses = int.tryParse(_fullDetails!['total_courses']?.toString() ?? '0') ?? 0;
    }

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackgroundColor : Colors.white,
      body: _isLoading 
        ? const Center(child: KaidaLoader())
        : SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // --- FIXED COVER & AVATAR STACK ---
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    // Cover Photo
                    Container(
                      height: 220,
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 60), // Space for overlapping avatar
                      decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.2)),
                      child: coverUrl.isNotEmpty
                          ? CachedNetworkImage(imageUrl: coverUrl, fit: BoxFit.cover)
                          : const Center(child: Icon(Icons.image, size: 60, color: Colors.white54)),
                    ),
                    // Back Button (Safe Area)
                    Positioned(
                      top: 40,
                      left: 16,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                    // Overlapping Avatar Guaranteed on Top
                    Positioned(
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: isDark ? AppTheme.darkBackgroundColor : Colors.white, shape: BoxShape.circle),
                        child: CircleAvatar(
                          radius: 55,
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                          backgroundImage: avatarUrl.isNotEmpty ? CachedNetworkImageProvider(avatarUrl) : null,
                          child: avatarUrl.isEmpty ? const Icon(Icons.person_rounded, size: 55, color: AppTheme.primaryColor) : null,
                        ),
                      ),
                    ),
                  ],
                ),
                
                // --- INSTRUCTOR INFO & STATS ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(name, textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                          ),
                          if (isVerified) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.verified, color: AppTheme.primaryColor, size: 22),
                          ]
                        ],
                      ),
                      const SizedBox(height: 6),
                      
                      if (headline.isNotEmpty)
                        Text(headline, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600, fontSize: 15)),
                      
                      const SizedBox(height: 24),
                      
                      // STATS ROW
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem(totalStudents.toString(), 'Students', isDark),
                          _buildStatDivider(isDark),
                          _buildStatItem(totalReviews.toString(), 'Reviews', isDark),
                          _buildStatDivider(isDark),
                          _buildStatItem(totalCourses.toString(), 'Courses', isDark),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      if (bio.isNotEmpty)
                        Text(bio, textAlign: TextAlign.center, style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, height: 1.6, fontSize: 14)),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                Divider(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200, thickness: 8),
                const SizedBox(height: 20),

                // --- COURSES LIST ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Instructor Courses', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                  ),
                ),
                const SizedBox(height: 16),
                
                if (_courses.isEmpty)
                  Padding(padding: const EdgeInsets.all(20), child: Center(child: Text("No active courses yet.", style: TextStyle(color: Colors.grey.shade500))))
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _courses.length,
                    itemBuilder: (context, index) {
                      return _buildCatalogStyleCourseCard(_courses[index], isDark, context);
                    },
                  ),
                  
                const SizedBox(height: 40),
              ],
            ),
          ),
    );
  }

  Widget _buildStatItem(String value, String label, bool isDark) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildStatDivider(bool isDark) {
    return Container(
      height: 30, width: 1,
      color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
    );
  }

  // EXACT REPLICA OF THE CATALOG/HOME SCREEN CARD
  Widget _buildCatalogStyleCourseCard(CatalogItem item, bool isDark, BuildContext context) {
    int discountPercent = 0;
    if (item.price > 0 && item.discountPrice > 0 && item.discountPrice < item.price) {
      discountPercent = (((item.price - item.discountPrice) / item.price) * 100).round();
    }

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ItemDetailsScreen(item: item))),
      child: Container(
        width: double.infinity, 
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurfaceColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: isDark ? Colors.black12 : Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: item.thumbnailUrl.isNotEmpty
                      ? CachedNetworkImage(imageUrl: item.thumbnailUrl, height: 160, width: double.infinity, fit: BoxFit.cover)
                      : Container(height: 160, color: AppTheme.primaryColor.withOpacity(0.2), child: const Icon(Icons.school_rounded, size: 40, color: AppTheme.primaryColor)),
                ),
                if (discountPercent > 0)
                  Positioned(
                    top: 10, left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(8)),
                      child: Text('-$discountPercent%', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(item.categoryName.toUpperCase(), style: const TextStyle(color: AppTheme.primaryColor, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5), overflow: TextOverflow.ellipsis)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                        child: Text(item.language.toUpperCase(), style: const TextStyle(color: AppTheme.primaryColor, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(item.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1.3, color: isDark ? Colors.white : Colors.black), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.person_rounded, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(child: Text(item.instructorName, style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (item.isFree || (item.price == 0 && item.discountPrice == 0))
                    const Text('FREE', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16))
                  else if (item.discountPrice > 0 && item.discountPrice < item.price)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('₦${item.discountPrice.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.primaryColor)),
                        const SizedBox(width: 8),
                        Text('₦${item.price.toStringAsFixed(0)}', style: TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey.shade400, fontSize: 14, fontWeight: FontWeight.w600)),
                      ],
                    )
                  else
                    Text('₦${item.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.primaryColor)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
