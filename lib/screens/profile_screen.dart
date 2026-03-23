import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../config/api_config.dart';
import '../config/app_theme.dart';
import '../config/theme_provider.dart';
import '../widgets/kaida_loader.dart';
import 'login_screen.dart';
import 'downloads_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int? _userId;
  bool _isLoading = true;
  bool _isUploadingAvatar = false;
  
  String _name = "Loading...";
  String _email = "";
  String _role = "student";
  String? _avatarUrl;
  String _walletBalance = "0.00";

  // Dynamic Settings
  String _facebookUrl = "";
  String _twitterUrl = "";
  String _instagramUrl = "";
  String _shareMessage = "Join me on Kainuwa Academy! Learn high-income digital skills today.";
  String _shareUrl = "https://play.google.com/store/apps/details?id=com.kainuwa.academy";

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId == null) return;
    setState(() => _userId = userId);

    try {
      // 1. Fetch Profile Data
      final profileRes = await http.post(Uri.parse(ApiConfig.userProfile), body: {'user_id': userId.toString()});
      if (profileRes.statusCode == 200) {
        final data = json.decode(profileRes.body);
        if (data['status'] == 'success') {
          _name = data['data']['name'] ?? 'User';
          _email = data['data']['email'] ?? '';
          _role = data['data']['role'] ?? 'student';
          _avatarUrl = data['data']['avatar_url'];
          _walletBalance = data['data']['kaida_points']?.toString() ?? "0.00";
        }
      }

      // 2. Fetch App Settings & Socials
      final settingsRes = await http.get(Uri.parse(ApiConfig.appSettings));
      if (settingsRes.statusCode == 200) {
        final set_data = json.decode(settingsRes.body);
        if (set_data['status'] == 'success') {
          _facebookUrl = set_data['data']['facebook'] ?? '';
          _twitterUrl = set_data['data']['twitter'] ?? '';
          _instagramUrl = set_data['data']['instagram'] ?? '';
          if (set_data['data']['share_message'] != null) _shareMessage = set_data['data']['share_message'];
          if (set_data['data']['share_url'] != null) _shareUrl = set_data['data']['share_url'];
        }
      }
    } catch (e) {
      debugPrint("Error fetching data: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _shareApp() {
    Share.share('$_shareMessage\n\n$_shareUrl');
  }

  Future<void> _launchSocial(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final textColor = isDark ? Colors.white : Colors.black87;

    if (_isLoading) {
      return const Scaffold(body: KaidaLoader());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, color: Colors.white),
            onPressed: () => themeProvider.toggleTheme(!isDark),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              color: AppTheme.primaryColor,
              padding: const EdgeInsets.only(bottom: 30, top: 20),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        backgroundImage: _avatarUrl != null && _avatarUrl!.isNotEmpty 
                            ? CachedNetworkImageProvider(_avatarUrl!) 
                            : null,
                        child: (_avatarUrl == null || _avatarUrl!.isEmpty) 
                            ? const Icon(Icons.person, size: 50, color: Colors.grey) 
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(_name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text(_email, style: const TextStyle(fontSize: 14, color: Colors.white70)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                    child: Text("Wallet: ₦$_walletBalance", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Menu Items
            if (_role == 'instructor' || _role == 'admin')
              _buildMenuTile(Icons.dashboard, "Instructor Dashboard", isDark, () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => WebDashboardScreen(title: "Instructor Portal", url: "https://academy.kainuwa.africa/api/mobile/webview_auth.php?user_id=$_userId&redirect=/instructor/dashboard.php")));
              }),
            
            if (_role == 'affiliate' || _role == 'admin')
              _buildMenuTile(Icons.campaign, "Affiliate Dashboard", isDark, () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => WebDashboardScreen(title: "Affiliate Portal", url: "https://academy.kainuwa.africa/api/mobile/webview_auth.php?user_id=$_userId&redirect=/affiliate/dashboard.php")));
              }),

            _buildMenuTile(Icons.download, "My Digital Downloads", isDark, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const DownloadsScreen()));
            }),

            _buildMenuTile(Icons.settings, "Account Settings", isDark, () {
               Navigator.push(context, MaterialPageRoute(builder: (context) => WebDashboardScreen(title: "Settings", url: "https://academy.kainuwa.africa/api/mobile/webview_auth.php?user_id=$_userId&redirect=/student/profile.php"))).then((_) => _fetchData());
            }),

            _buildMenuTile(Icons.share, "Share App", isDark, _shareApp),
            _buildMenuTile(Icons.logout, "Logout", isDark, _logout, color: Colors.red),

            const SizedBox(height: 30),
            
            // Social Media Footer
            const Text("Connect with us", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_facebookUrl.isNotEmpty)
                  IconButton(icon: const FaIcon(FontAwesomeIcons.facebook, color: Colors.blue, size: 30), onPressed: () => _launchSocial(_facebookUrl)),
                if (_twitterUrl.isNotEmpty)
                  IconButton(icon: const FaIcon(FontAwesomeIcons.xTwitter, color: Colors.grey, size: 30), onPressed: () => _launchSocial(_twitterUrl)),
                if (_instagramUrl.isNotEmpty)
                  IconButton(icon: const FaIcon(FontAwesomeIcons.instagram, color: Colors.pink, size: 30), onPressed: () => _launchSocial(_instagramUrl)),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile(IconData icon, String title, bool isDark, VoidCallback onTap, {Color? color}) {
    final textColor = color ?? (isDark ? Colors.white : Colors.black87);
    final iconColor = color ?? AppTheme.primaryColor;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(color: isDark ? AppTheme.darkSurfaceColor : Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))]),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
        trailing: Icon(Icons.arrow_forward_ios, size: 14, color: isDark ? Colors.grey.shade600 : Colors.grey),
        onTap: onTap,
      ),
    );
  }
}

class WebDashboardScreen extends StatefulWidget {
  final String title;
  final String url;
  const WebDashboardScreen({Key? key, required this.title, required this.url}) : super(key: key);
  @override
  _WebDashboardScreenState createState() => _WebDashboardScreenState();
}

class _WebDashboardScreenState extends State<WebDashboardScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) { if (mounted) setState(() => _isLoading = true); },
          onPageFinished: (String url) { if (mounted) setState(() => _isLoading = false); },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title, style: const TextStyle(fontSize: 16, color: Colors.white)), iconTheme: const IconThemeData(color: Colors.white)),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const Center(child: KaidaLoader()), // Using the new loader here too!
        ],
      ),
    );
  }
}
