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
    
    // Initial fallback data from previous screen
    String avatarUrl = _formatUrl(widget.instructor['avatar_url']);
    String name = widget.instructor['name'] ?? 'Instructor';
    String coverUrl = '';
    String headline = 'Professional Instructor';
    String bio = '';

    // Swap to full data once loaded
    if (_fullDetails != null) {
      avatarUrl = _formatUrl(_fullDetails!['avatar_url']);
      coverUrl = _formatUrl(_fullDetails!['cover_photo_url']);
      name = _fullDetails!['full_name'] ?? _fullDetails!['username'] ?? name;
      headline = _fullDetails!['headline'] ?? headline;
      bio = _fullDetails!['bio'] ?? '';
    }

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackgroundColor : Colors.white,
      body: _isLoading 
        ? const Center(child: KaidaLoader())
        : CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // --- CINEMATIC BANNER ---
              SliverAppBar(
                expandedHeight: 200.0,
                pinned: true,
                backgroundColor: AppTheme.primaryColor,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: coverUrl.isNotEmpty
                      ? CachedNetworkImage(imageUrl: coverUrl, fit: BoxFit.cover)
                      : Container(color: AppTheme.primaryColor),
                ),
              ),
              
              // --- INSTRUCTOR INFO ---
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -50),
                  child: Column(
                    children: [
                      // Overlapping Avatar
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkBackgroundColor : Colors.white, 
                          shape: BoxShape.circle
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                          backgroundImage: avatarUrl.isNotEmpty ? CachedNetworkImageProvider(avatarUrl) : null,
                          child: avatarUrl.isEmpty ? const Icon(Icons.person_rounded, size: 50, color: AppTheme.primaryColor) : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      Text(name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                      const SizedBox(height: 4),
                      
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(headline, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600, fontSize: 14)),
                      ),
                      
                      if (bio.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            bio, 
                            textAlign: TextAlign.center, 
                            style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, height: 1.5, fontSize: 14)
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 30),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Instructor Courses (${_courses.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // --- COURSE LIST ---
              if (_courses.isEmpty)
                SliverToBoxAdapter(
                  child: Center(child: Padding(padding: const EdgeInsets.only(top: 20), child: Text("No active courses yet.", style: TextStyle(color: Colors.grey.shade500)))),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final course = _courses[index];
                      return Transform.translate(
                        offset: const Offset(0, -50),
                        child: _buildCourseCard(course, isDark, context),
                      );
                    },
                    childCount: _courses.length,
                  ),
                ),
                
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
    );
  }

  Widget _buildCourseCard(CatalogItem item, bool isDark, BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ItemDetailsScreen(item: item))),
      child: Container(
        margin: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurfaceColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
              child: item.thumbnailUrl.isNotEmpty
                  ? CachedNetworkImage(imageUrl: item.thumbnailUrl, width: 110, height: 110, fit: BoxFit.cover)
                  : Container(width: 110, height: 110, color: AppTheme.primaryColor.withOpacity(0.1), child: const Icon(Icons.school_rounded, color: AppTheme.primaryColor)),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.categoryName.toUpperCase(), style: const TextStyle(color: AppTheme.primaryColor, fontSize: 10, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(item.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    if (item.isFree || (item.price == 0 && item.discountPrice == 0))
                      const Text('FREE', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14))
                    else if (item.discountPrice > 0 && item.discountPrice < item.price)
                      Text('₦${item.discountPrice.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppTheme.primaryColor))
                    else
                      Text('₦${item.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppTheme.primaryColor)),
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
