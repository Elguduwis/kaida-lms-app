import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/api_config.dart';
import '../config/app_theme.dart';
import '../widgets/kaida_loader.dart';
import '../utils/kaida_alert.dart';
import 'course_player_screen.dart';
import 'main_layout.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  List<dynamic> _notifications = [];
  int? _userId;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt('user_id');
    
    if (_userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/notifications_api.php'),
        body: {'action': 'get', 'user_id': _userId.toString()}
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && mounted) {
          setState(() {
            _notifications = data['data'];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsReadAndRoute(Map<String, dynamic> notif) async {
    if (_userId == null) return;
    
    int notifId = int.tryParse(notif['id'].toString()) ?? 0;
    bool isRead = notif['is_read'] == 1 || notif['is_read'] == '1';

    // Optimistic UI Update
    if (!isRead) {
      setState(() {
        notif['is_read'] = 1;
      });
      http.post(
        Uri.parse('${ApiConfig.baseUrl}/notifications_api.php'),
        body: {'action': 'mark_read', 'user_id': _userId.toString(), 'notification_id': notifId.toString()}
      );
    }

    // Handle Action Routing
    String actionType = notif['action_type']?.toString() ?? 'open_app';
    
    if (actionType == 'open_course') {
      int courseId = int.tryParse(notif['course_id']?.toString() ?? '0') ?? 0;
      if (courseId > 0) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => CoursePlayerScreen(courseId: courseId, courseTitle: notif['title'])));
      }
    } else if (actionType == 'open_dashboard') {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const MainLayout(initialIndex: 3)), (route) => false);
    } else if (actionType == 'open_store') {
      final url = Uri.parse("market://details?id=com.kainuwa.academy"); // Update with your actual package name
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    }
  }

  Future<void> _markAllAsRead() async {
    if (_userId == null || _notifications.isEmpty) return;
    
    setState(() {
      for (var n in _notifications) { n['is_read'] = 1; }
    });

    try {
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/notifications_api.php'),
        body: {'action': 'mark_all_read', 'user_id': _userId.toString()}
      );
      KaidaAlert.showModal(context: context, title: 'Cleared', message: 'All notifications marked as read.', isError: false);
    } catch (e) {
      // Silent fail
    }
  }

  String _formatTime(String timestamp) {
    DateTime dt = DateTime.tryParse(timestamp) ?? DateTime.now();
    Duration diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackgroundColor : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black, size: 20),
          onPressed: () => Navigator.pop(context, true), // Returns true so Home knows to refresh the badge
        ),
        title: Text('Notifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              icon: Icon(Icons.done_all_rounded, color: AppTheme.primaryColor, size: 24),
              onPressed: _markAllAsRead,
              tooltip: 'Mark all as read',
            ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: KaidaLoader())
        : _notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_rounded, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('All Caught Up!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                  const SizedBox(height: 8),
                  Text('You have no new notifications.', style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            )
          : RefreshIndicator(
              color: AppTheme.primaryColor,
              onRefresh: _fetchNotifications,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _notifications.length,
                separatorBuilder: (context, index) => Divider(height: 1, color: isDark ? Colors.grey.shade800 : Colors.grey.shade100),
                itemBuilder: (context, index) {
                  final notif = _notifications[index];
                  bool isRead = notif['is_read'] == 1 || notif['is_read'] == '1';
                  String imageUrl = notif['image_url']?.toString() ?? '';

                  return InkWell(
                    onTap: () => _markAsReadAndRoute(notif),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      color: isRead ? Colors.transparent : (isDark ? AppTheme.primaryColor.withOpacity(0.1) : AppTheme.primaryColor.withOpacity(0.05)),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon or Image
                          Container(
                            width: 50, height: 50,
                            decoration: BoxDecoration(
                              color: isRead ? (isDark ? Colors.grey.shade800 : Colors.grey.shade200) : AppTheme.primaryColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: imageUrl.isNotEmpty
                              ? ClipRRect(borderRadius: BorderRadius.circular(12), child: CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover))
                              : Icon(Icons.notifications_active_rounded, color: isRead ? Colors.grey : AppTheme.primaryColor, size: 24),
                          ),
                          const SizedBox(width: 16),
                          // Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        notif['title'] ?? 'Notification',
                                        style: TextStyle(fontWeight: isRead ? FontWeight.w600 : FontWeight.w800, fontSize: 15, color: isDark ? Colors.white : Colors.black87),
                                      ),
                                    ),
                                    if (!isRead)
                                      Container(width: 8, height: 8, margin: const EdgeInsets.only(left: 8), decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  notif['message'] ?? '',
                                  style: TextStyle(color: isRead ? Colors.grey.shade500 : (isDark ? Colors.grey.shade300 : Colors.black54), fontSize: 14, height: 1.4),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _formatTime(notif['created_at']?.toString() ?? ''),
                                  style: TextStyle(color: AppTheme.primaryColor, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
