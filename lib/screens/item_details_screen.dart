import '../widgets/kaida_loader.dart';
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
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in first.')));
      return;
    }

    if (_isEnrolled && widget.item.type == 'courses') {
      Navigator.push(context, MaterialPageRoute(
        builder: (context) => CoursePlayerScreen(courseId: widget.item.id, courseTitle: widget.item.title)
      ));
    } else {
      // UPGRADED ROUTING: Courses go directly to enroll.php, Products go to view_product.php
      String targetPath = widget.item.type == 'courses'
          ? '/enroll.php?course_id=${widget.item.id}'
          : '/view_product.php?slug=${widget.item.slug}';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final surfaceColor = isDark ? AppTheme.darkSurfaceColor : Colors.white;

    String? instructorAvatar = _getInstructorAvatar();

    return Scaffold(
      body: _isLoading
        ? Center(child: KaidaLoader())
        : CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 250.0,
                pinned: true,
                backgroundColor: isDark ? AppTheme.darkSurfaceColor : AppTheme.primaryColor,
                iconTheme: const IconThemeData(color: Colors.white),
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

                      Text(widget.item.title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                            backgroundImage: (instructorAvatar != null && instructorAvatar.isNotEmpty)
                                ? CachedNetworkImageProvider(instructorAvatar)
                                : null,
                            child: (instructorAvatar == null || instructorAvatar.isEmpty)
                                ? const Icon(Icons.person, size: 16, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Icon(widget.item.type == 'courses' ? Icons.school : Icons.store, size: 14, color: subTextColor),
                          const SizedBox(width: 4),
                          Text('By ${widget.item.instructorName}', style: TextStyle(color: subTextColor, fontSize: 14, fontWeight: FontWeight.w600)),
                        ],
                      ),

                      const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider()),

                      if (widget.item.type == 'courses') ...[
                        _buildKaidaPointsDisplay(),
                        const SizedBox(height: 20),
                      ],

                      Text('About this ${widget.item.type == 'courses' ? 'Course' : 'Product'}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                      const SizedBox(height: 12),

                      Text(
                        _extraDetails?['course']?['description']?.toString().replaceAll(RegExp(r'<[^>]*>'), '') ?? 'No description provided for this item yet. Check back soon for more details!',
                        style: TextStyle(color: subTextColor, fontSize: 14, height: 1.5),
                      ),

                      const SizedBox(height: 30),

                      if (widget.item.type == 'courses') ...[
                        Text('Curriculum', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                        const SizedBox(height: 12),
                        _buildCurriculumList(isDark, textColor, subTextColor),
                      ],
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
      bottomNavigationBar: _isLoading ? const SizedBox.shrink() : Container(
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

              SizedBox(
                width: 160,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.item.isComingSoon ? Colors.grey : AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: widget.item.isComingSoon ? null : _handlePrimaryAction,
                  child: Text(
                    // FIXED: Now displays ENROLL explicitly for all courses
                    _isEnrolled && widget.item.type == 'courses' ? 'START' : (widget.item.type == 'courses' ? 'ENROLL' : 'BUY NOW'),
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

        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black.withOpacity(0.6), Colors.transparent, Colors.black.withOpacity(0.6)],
            ),
          ),
        ),

        if (widget.item.type == 'courses')
           const Center(child: Icon(Icons.play_circle_fill, color: Colors.white70, size: 60)),
      ],
    );
  }

  Widget _buildKaidaPointsDisplay() {
    int pointsPrice = int.tryParse(_extraDetails?['course']?['points_price']?.toString() ?? '0') ?? 0;
    int pointsReward = int.tryParse(_extraDetails?['course']?['points_reward']?.toString() ?? '0') ?? 0;

    if (pointsPrice == 0 && pointsReward == 0) return const SizedBox.shrink();

    return Row(
      children: [
        if (pointsPrice > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                const Icon(Icons.stars, color: Colors.orange, size: 16),
                const SizedBox(width: 4),
                Text('$pointsPrice KAIDA', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 12)),
              ],
            ),
          ),
        if (pointsPrice > 0 && pointsReward > 0) const SizedBox(width: 12),
        if (pointsReward > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                const Icon(Icons.card_giftcard, color: Colors.green, size: 16),
                const SizedBox(width: 4),
                Text('Earn $pointsReward Points', style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCurriculumList(bool isDark, Color textColor, Color subTextColor) {
    List<dynamic> curriculum = _extraDetails?['curriculum'] ?? [];
    if (curriculum.isEmpty) return Text('Syllabus is being updated.', style: TextStyle(color: subTextColor));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: curriculum.length,
      itemBuilder: (context, index) {
        final section = curriculum[index];
        List items = section['items'] ?? [];
        return Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            iconColor: AppTheme.primaryColor,
            collapsedIconColor: subTextColor,
            title: Text(section['title'] ?? 'Section', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
            children: items.map((lesson) {
              String type = lesson['type']?.toString() ?? 'lesson';
              return ListTile(
                contentPadding: const EdgeInsets.only(left: 16, right: 0),
                leading: Icon(
                  type == 'quiz' ? Icons.help_outline : (type == 'assignment' ? Icons.assignment : Icons.play_circle_outline),
                  size: 20,
                  color: isDark ? AppTheme.primaryColor.withOpacity(0.7) : Colors.grey.shade500
                ),
                title: Text(lesson['title'] ?? 'Lesson', style: TextStyle(fontSize: 14, color: isDark ? Colors.grey.shade300 : Colors.grey.shade800)),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// SECURE OFFLINE-PROTECTED CHECKOUT WEBVIEW
// -----------------------------------------------------------------------------
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
  bool _hasError = false; // GLOBALLY TRACKS CONNECTION ERRORS

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppTheme.backgroundColor)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) { 
            if (mounted) setState(() { _isLoading = true; _hasError = false; }); 
          },
          onPageFinished: (String url) { 
            if (mounted) setState(() => _isLoading = false); 
          },
          // INTERCEPTS THE NETWORK ERROR BEFORE IT SHOWS IN THE BROWSER
          onWebResourceError: (WebResourceError error) {
            if (mounted) setState(() { _isLoading = false; _hasError = true; });
          },
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
            IconButton(
              icon: const Icon(Icons.refresh), 
              onPressed: () {
                setState(() { _hasError = false; _isLoading = true; });
                _controller.reload();
              }
            ),
          ],
        ),
        body: Stack(
          children: [
            if (_hasError)
              // BEAUTIFUL NATIVE ERROR SCREEN
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off_rounded, size: 80, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('Connection Failed', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Please check your internet connection.', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                      onPressed: () {
                        setState(() { _hasError = false; _isLoading = true; });
                        _controller.reload();
                      },
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      label: const Text('Try Again', style: TextStyle(color: Colors.white)),
                    )
                  ],
                ),
              )
            else
              WebViewWidget(controller: _controller),
              
            if (_isLoading && !_hasError) Center(child: KaidaLoader()),
          ],
        ),
      ),
    );
  }
}
