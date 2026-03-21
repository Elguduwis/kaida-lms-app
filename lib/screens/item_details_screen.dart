import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
  bool _isEnrolled = false;
  int? _userId;
  Map<String, dynamic>? _extraDetails;
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _initializeUserAndData();
  }

  Future<void> _initializeUserAndData() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt('user_id');
    
    await _checkEnrollmentStatus(prefs);
    
    if (widget.item.type == 'courses') {
      await _fetchExtraDetails();
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _checkEnrollmentStatus(SharedPreferences prefs) async {
    final cached = prefs.getString('cached_my_courses');
    if (cached != null) {
      List myCourses = json.decode(cached);
      if (myCourses.any((c) => c['id'].toString() == widget.item.id.toString())) {
        if (mounted) setState(() => _isEnrolled = true);
      }
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
            _initializeVideoPlayer();
          }
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _initializeVideoPlayer() {
    String introUrl = _extraDetails?['course']?['intro_video_url']?.toString() ?? '';
    if (introUrl.isNotEmpty) {
      if (!introUrl.startsWith('http')) introUrl = 'https://academy.kainuwa.africa/' + introUrl;
      
      _videoController = VideoPlayerController.network(introUrl)
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
              _chewieController = ChewieController(
                videoPlayerController: _videoController!,
                autoPlay: false,
                looping: false,
                aspectRatio: _videoController!.value.aspectRatio,
                materialProgressColors: ChewieProgressColors(
                  playedColor: AppTheme.primaryColor,
                  handleColor: AppTheme.primaryColor,
                  backgroundColor: Colors.grey,
                ),
              );
            });
          }
        });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  void _handlePrimaryAction() {
    if (_isEnrolled && widget.item.type == 'courses') {
      // Direct Native Navigation to the Course Player
      Navigator.push(context, MaterialPageRoute(
        builder: (context) => CoursePlayerScreen(courseId: widget.item.id, courseTitle: widget.item.title)
      ));
    } else {
      // PRECISE WEBVIEW ROUTING
      // Determine exactly which page they should land on
      String targetPath = widget.item.type == 'courses' 
          ? '/view_course.php?slug=${widget.item.slug}' 
          : '/view_product.php?slug=${widget.item.slug}';
      
      // We must URL Encode the target path so the "?" and "=" don't break the auth bridge
      String encodedRedirect = Uri.encodeComponent(targetPath);
      
      String authBridgeUrl = 'https://academy.kainuwa.africa/api/mobile/webview_auth.php?user_id=$_userId&redirect=$encodedRedirect';

      Navigator.push(context, MaterialPageRoute(builder: (context) => CheckoutWebViewScreen(
        title: widget.item.type == 'courses' ? 'Enroll Course' : 'Buy Product',
        url: authBridgeUrl,
      )));
    }
  }

  String? _getInstructorAvatar() {
    String? avatarUrl;
    if (_extraDetails != null && _extraDetails!['instructor'] != null) {
      avatarUrl = _extraDetails!['instructor']['avatar_url']?.toString();
    }
    
    if (avatarUrl != null && avatarUrl.isNotEmpty && !avatarUrl.startsWith('http')) {
      if (!avatarUrl.startsWith('/')) avatarUrl = '/' + avatarUrl;
      avatarUrl = 'https://academy.kainuwa.africa' + avatarUrl;
    }
    return avatarUrl;
  }

  @override
  Widget build(BuildContext context) {
    String? instructorAvatar = _getInstructorAvatar();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 250.0,
                  pinned: true,
                  iconTheme: const IconThemeData(color: Colors.white),
                  backgroundColor: AppTheme.primaryColor,
                  flexibleSpace: FlexibleSpaceBar(
                    background: _buildMediaHeader(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: Text(widget.item.categoryName.toUpperCase(), style: const TextStyle(color: AppTheme.primaryColor, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 12),
                        Text(widget.item.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.3)),
                        const SizedBox(height: 12),
                        
                        // UPDATED INSTRUCTOR AVATAR ROW
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16, 
                              backgroundColor: Colors.grey.shade300, 
                              backgroundImage: (instructorAvatar != null && instructorAvatar.isNotEmpty) 
                                  ? CachedNetworkImageProvider(instructorAvatar) 
                                  : null,
                              child: (instructorAvatar == null || instructorAvatar.isEmpty) 
                                  ? const Icon(Icons.person, size: 16, color: Colors.white) 
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Text(widget.item.instructorName, style: TextStyle(fontSize: 14, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        
                        const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider()),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _buildPriceDisplay(),
                            if (widget.item.type == 'courses') _buildKaidaPointsDisplay(),
                          ],
                        ),
                        
                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 2,
                            ),
                            onPressed: _handlePrimaryAction,
                            child: Text(
                              _isEnrolled && widget.item.type == 'courses' ? 'START LEARNING' : (widget.item.type == 'courses' ? 'ENROLL NOW' : 'BUY NOW'),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1),
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),
                        
                        if (widget.item.type == 'courses') ...[
                          const Text('About This Course', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Text(
                            _extraDetails?['course']?['description']?.toString().replaceAll(RegExp(r'<[^>]*>'), '') ?? 'No description available.',
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.6),
                          ),
                          const SizedBox(height: 30),
                          const Text('Curriculum', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          _buildCurriculumList(),
                        ]
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMediaHeader() {
    if (_chewieController != null) {
      return Container(color: Colors.black, child: Chewie(controller: _chewieController!));
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.item.thumbnailUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: widget.item.thumbnailUrl, 
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Container(color: AppTheme.primaryColor, child: const Icon(Icons.image, color: Colors.white)),
              )
            : Container(color: AppTheme.primaryColor, child: const Icon(Icons.school, size: 60, color: Colors.white)),
        Container(color: Colors.black.withOpacity(0.3)),
        if (widget.item.type == 'courses')
           const Center(child: Icon(Icons.play_circle_fill, color: Colors.white70, size: 60)),
      ],
    );
  }

  Widget _buildPriceDisplay() {
    if (widget.item.isFree || (widget.item.price == 0 && widget.item.discountPrice == 0)) {
      return const Text('FREE', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 24));
    }
    if (widget.item.discountPrice > 0 && widget.item.discountPrice < widget.item.price) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('₦${widget.item.price.toStringAsFixed(0)}', style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey, fontSize: 14)),
          Text('₦${widget.item.discountPrice.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 28, color: AppTheme.primaryColor)),
        ],
      );
    }
    return Text('₦${widget.item.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 28, color: AppTheme.primaryColor));
  }

  Widget _buildKaidaPointsDisplay() {
    int pointsPrice = int.tryParse(_extraDetails?['course']?['points_price']?.toString() ?? '0') ?? 0;
    int pointsReward = int.tryParse(_extraDetails?['course']?['points_reward']?.toString() ?? '0') ?? 0;

    if (pointsPrice == 0 && pointsReward == 0) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (pointsPrice > 0)
          Row(
            children: [
              const Icon(Icons.stars, color: Colors.orange, size: 16),
              const SizedBox(width: 4),
              Text('$pointsPrice KAIDA', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 14)),
            ],
          ),
        if (pointsReward > 0)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
            child: Text('+$pointsReward Points Reward', style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }

  Widget _buildCurriculumList() {
    List<dynamic> curriculum = _extraDetails?['curriculum'] ?? [];
    if (curriculum.isEmpty) return const Text('Syllabus is being updated.', style: TextStyle(color: Colors.grey));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: curriculum.length,
      itemBuilder: (context, index) {
        final section = curriculum[index];
        List items = section['items'] ?? [];
        return ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Text(section['title'] ?? 'Section', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          children: items.map((lesson) {
            String type = lesson['type']?.toString() ?? 'lesson';
            return ListTile(
              contentPadding: const EdgeInsets.only(left: 16, right: 0),
              leading: Icon(type == 'quiz' ? Icons.help_outline : (type == 'assignment' ? Icons.assignment : Icons.play_circle_outline), size: 20, color: Colors.grey.shade500),
              title: Text(lesson['title'] ?? 'Lesson', style: TextStyle(fontSize: 14, color: Colors.grey.shade800)),
            );
          }).toList(),
        );
      },
    );
  }
}

// Dedicated WebView specifically for checkouts and details routing
class CheckoutWebViewScreen extends StatefulWidget {
  final String title;
  final String url;
  const CheckoutWebViewScreen({Key? key, required this.title, required this.url}) : super(key: key);

  @override
  _CheckoutWebViewScreenState createState() => _CheckoutWebViewScreenState();
}

class _CheckoutWebViewScreenState extends State<CheckoutWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppTheme.backgroundColor)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) { if (mounted) setState(() => _isLoading = true); },
          onPageFinished: (String url) { if (mounted) setState(() => _isLoading = false); },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  Future<bool> _goBack() async {
    if (await _controller.canGoBack()) {
      _controller.goBack();
      return Future.value(false);
    }
    return Future.value(true);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _goBack,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title, style: const TextStyle(fontSize: 16, color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: () => _controller.reload()),
          ],
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading) const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
          ],
        ),
      ),
    );
  }
}
