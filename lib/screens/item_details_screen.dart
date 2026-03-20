import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../config/api_config.dart';
import '../config/app_theme.dart';
import 'catalog_screen.dart';
import 'profile_screen.dart';

class ItemDetailsScreen extends StatefulWidget {
  final CatalogItem item;
  const ItemDetailsScreen({Key? key, required this.item}) : super(key: key);

  @override
  _ItemDetailsScreenState createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _extraDetails;
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    if (widget.item.type == 'course') {
      _fetchExtraDetails();
    } else {
      _isLoading = false; 
    }
  }

  Future<void> _fetchExtraDetails() async {
    try {
      final response = await http.get(Uri.parse('https://academy.kainuwa.africa/api/mobile/course_details.php?slug=${widget.item.slug}'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          if (mounted) {
            setState(() {
              _extraDetails = data['data'];
              _isLoading = false;
            });
            _initializeVideo(data['data']['course']['intro_video_url']);
          }
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _initializeVideo(String? url) {
    if (url == null || url.isEmpty || url.contains('youtube') || url.contains('vimeo')) return;
    
    String finalUrl = url.startsWith('http') ? url : 'https://academy.kainuwa.africa/' + url;
    _videoController = VideoPlayerController.network(finalUrl)..initialize().then((_) {
      if (mounted) {
        setState(() {
          _chewieController = ChewieController(
            videoPlayerController: _videoController!,
            autoPlay: false,
            looping: false,
            aspectRatio: _videoController!.value.aspectRatio,
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  void _processCheckout(BuildContext context, String actionType) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId == null) return;
    
    final redirect = widget.item.type == 'course' ? '/view_course.php?slug=${widget.item.slug}' : '/view_product.php?slug=${widget.item.slug}';
    final authUrl = 'https://academy.kainuwa.africa/api/mobile/webview_auth.php?user_id=$userId&redirect=$redirect';
    
    Navigator.push(context, MaterialPageRoute(builder: (context) => WebDashboardScreen(url: authUrl, title: widget.item.title)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: _chewieController != null ? 250.0 : 200.0,
            floating: false,
            pinned: true,
            backgroundColor: Colors.black,
            flexibleSpace: FlexibleSpaceBar(
              background: _chewieController != null
                  ? Chewie(controller: _chewieController!)
                  : (widget.item.thumbnailUrl.isNotEmpty
                      ? Image.network(widget.item.thumbnailUrl, fit: BoxFit.cover)
                      : Container(color: AppTheme.primaryColor, child: const Icon(Icons.school, size: 80, color: Colors.white))),
            ),
          ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.item.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.3)),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Icon(widget.item.type == 'course' ? Icons.person : Icons.inventory_2, color: Colors.grey, size: 20),
                      const SizedBox(width: 8),
                      Text(widget.item.type == 'course' ? 'Instructor: ${widget.item.instructorName}' : 'Kainuwa Product', style: TextStyle(color: Colors.grey[700], fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Checkout Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                    child: Column(
                      children: [
                        _buildPriceDisplay(),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity, height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            onPressed: () => _processCheckout(context, 'enroll'),
                            child: Text(widget.item.type == 'course' ? 'Enroll Now' : 'Buy Now', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Curriculum and Instructor Details
                  if (_isLoading)
                     const Padding(padding: EdgeInsets.all(40.0), child: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))),
                  
                  if (_extraDetails != null) ...[
                    const SizedBox(height: 30),
                    const Text('About This Course', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text(_extraDetails!['course']['description'] ?? 'No description available.', style: TextStyle(color: Colors.grey[800], height: 1.5)),
                    
                    const SizedBox(height: 30),
                    const Text('Curriculum', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    ...(_extraDetails!['curriculum'] as List).map((section) {
                      return ExpansionTile(
                        title: Text(section['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        children: (section['items'] as List).map((lesson) {
                          return ListTile(
                            leading: Icon(lesson['type'] == 'lesson' ? Icons.play_circle_outline : Icons.assignment, color: Colors.grey),
                            title: Text(lesson['title'], style: const TextStyle(fontSize: 14)),
                          );
                        }).toList(),
                      );
                    }).toList(),

                    const SizedBox(height: 30),
                    const Text('Instructor', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 30,
                        backgroundImage: NetworkImage('https://academy.kainuwa.africa/' + (_extraDetails!['instructor']['avatar_url'] ?? '')),
                        onBackgroundImageError: (e, s) => const Icon(Icons.person),
                      ),
                      title: Text(_extraDetails!['instructor']['full_name'] ?? _extraDetails!['instructor']['username'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(_extraDetails!['instructor']['headline'] ?? 'Kainuwa Instructor'),
                    ),
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceDisplay() {
    if (widget.item.isFree || (widget.item.price == 0 && widget.item.discountPrice == 0)) {
      return const Text('FREE', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 28));
    }
    if (widget.item.discountPrice > 0 && widget.item.discountPrice < widget.item.price) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('₦${widget.item.discountPrice.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 28, color: AppTheme.primaryColor)),
          const SizedBox(width: 8),
          Text('₦${widget.item.price.toStringAsFixed(0)}', style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey, fontSize: 16)),
        ],
      );
    }
    return Text('₦${widget.item.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 28, color: AppTheme.primaryColor));
  }
}
