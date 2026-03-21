import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../config/app_theme.dart';
import 'catalog_screen.dart';
import 'course_player_screen.dart';

class ItemDetailsScreen extends StatefulWidget {
  final CatalogItem item;

  const ItemDetailsScreen({Key? key, required this.item}) : super(key: key);

  @override
  _ItemDetailsScreenState createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen> {
  bool _isLoading = true;
  bool _isEnrolling = false;
  Map<String, dynamic>? _fullDetails;

  @override
  void initState() {
    super.initState();
    _fetchFullDetails();
  }

  Future<void> _fetchFullDetails() async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.courseDetails}${widget.item.slug}'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && mounted) {
          setState(() {
            _fullDetails = data['data'];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleEnrollment() async {
    // If it's free, auto-enroll. If paid, you would normally route to a payment gateway here.
    // For now, we will simulate a free enrollment or route to the player if they already own it.
    
    setState(() => _isEnrolling = true);
    
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    
    if (userId == null) {
      setState(() => _isEnrolling = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in to enroll.')));
      return;
    }

    // Simulate API delay
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() => _isEnrolling = false);
    
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Processing enrollment...'), backgroundColor: AppTheme.primaryColor));
    
    // Route to player
    Navigator.pushReplacement(
      context, 
      MaterialPageRoute(builder: (context) => CoursePlayerScreen(courseId: widget.item.id, courseTitle: widget.item.title))
    );
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic Theme Detectors
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final surfaceColor = isDark ? AppTheme.darkSurfaceColor : Colors.white;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 1. Collapsing Hero Header
          SliverAppBar(
            expandedHeight: 250.0,
            pinned: true,
            backgroundColor: isDark ? AppTheme.darkSurfaceColor : AppTheme.primaryColor,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  widget.item.thumbnailUrl.isNotEmpty
                      ? Image.network(widget.item.thumbnailUrl, fit: BoxFit.cover)
                      : Container(color: AppTheme.primaryColor, child: const Icon(Icons.image, size: 80, color: Colors.white)),
                  // Dark gradient overlay to make the back button visible
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black.withOpacity(0.6), Colors.transparent, Colors.black.withOpacity(0.6)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.favorite_border, color: Colors.white),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to Wishlist!')));
                },
              ),
            ],
          ),

          // 2. Content Body
          SliverToBoxAdapter(
            child: _isLoading 
              ? const Padding(padding: EdgeInsets.all(40.0), child: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)))
              : Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.item.categoryName, 
                          style: const TextStyle(color: AppTheme.primaryColor, fontSize: 12, fontWeight: FontWeight.bold)
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Title
                      Text(widget.item.title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                      const SizedBox(height: 8),
                      
                      // Instructor Info
                      Row(
                        children: [
                          Icon(widget.item.type == 'courses' ? Icons.person : Icons.store, size: 16, color: subTextColor),
                          const SizedBox(width: 6),
                          Text('By ${widget.item.instructorName}', style: TextStyle(color: subTextColor, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Description Section
                      Text('About this ${widget.item.type == 'courses' ? 'Course' : 'Product'}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                      const SizedBox(height: 12),
                      
                      // Full Description or Fallback
                      Text(
                        _fullDetails?['description'] ?? 'No description provided for this item yet. Check back soon for more details!',
                        style: TextStyle(color: subTextColor, fontSize: 14, height: 1.5),
                      ),
                      
                      const SizedBox(height: 100), // padding for bottom bar
                    ],
                  ),
                ),
          ),
        ],
      ),
      
      // 3. Persistent Bottom Action Bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: surfaceColor,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(isDark ? 0.5 : 0.05), blurRadius: 10, offset: const Offset(0, -5)),
          ],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Price Display
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.item.discountPrice > 0 && widget.item.discountPrice < widget.item.price) ...[
                    Text('₦${widget.item.price.toStringAsFixed(0)}', style: TextStyle(decoration: TextDecoration.lineThrough, color: subTextColor, fontSize: 12, fontWeight: FontWeight.bold)),
                    Text('₦${widget.item.discountPrice.toStringAsFixed(0)}', style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold)),
                  ] else if (widget.item.isFree || widget.item.price == 0) ...[
                    const Text('Total Price', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const Text('FREE', style: TextStyle(color: Colors.green, fontSize: 24, fontWeight: FontWeight.bold)),
                  ] else ...[
                    const Text('Total Price', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text('₦${widget.item.price.toStringAsFixed(0)}', style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold)),
                  ]
                ],
              ),
              
              // Enroll Button
              SizedBox(
                width: 160,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.item.isComingSoon ? Colors.grey : AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: widget.item.isComingSoon || _isEnrolling ? null : _handleEnrollment,
                  child: _isEnrolling 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                          widget.item.isComingSoon ? 'Coming Soon' : (widget.item.isFree ? 'Enroll Now' : 'Buy Now'), 
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
