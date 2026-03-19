import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../config/api_config.dart';
import '../config/app_theme.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int? _userId;
  bool _isLoading = true;
  String _name = "Loading...";
  String _role = "student";
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    
    if (userId == null) return;
    setState(() => _userId = userId);

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.userProfile),
        body: {'user_id': userId.toString()},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          if (mounted) {
            setState(() {
              _name = data['data']['name'];
              _role = data['data']['role'];
              _avatarUrl = data['data']['avatar_url'];
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  void _openWebDashboard(String redirectPath, String title) {
    if (_userId == null) return;
    
    // Uses the secure auto-login bridge to load the correct web path
    final authUrl = 'https://academy.kainuwa.africa/api/mobile/webview_auth.php?user_id=$_userId&redirect=$redirectPath';
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WebDashboardScreen(url: authUrl, title: title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Smart Role Logic (Admins see everything)
    bool isInstructor = _role == 'instructor' || _role == 'admin';
    bool isAffiliate = _role == 'affiliate' || _role == 'admin';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
        : SingleChildScrollView(
        child: Column(
          children: [
            // Header Profile Section
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primaryColor, width: 2),
                      image: (_avatarUrl != null && _avatarUrl!.isNotEmpty) 
                        ? DecorationImage(
                            image: NetworkImage(_avatarUrl!),
                            fit: BoxFit.cover,
                          ) 
                        : null,
                    ),
                    child: (_avatarUrl == null || _avatarUrl!.isEmpty)
                      ? const Icon(Icons.person, size: 50, color: AppTheme.primaryColor)
                      : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _name,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20)
                    ),
                    child: Text(
                      _role.toUpperCase(),
                      style: const TextStyle(color: AppTheme.primaryColor, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Role Switching Section (Conditionally Rendered!)
            if (isInstructor || isAffiliate)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Creator & Partner Hub', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 10),
                    
                    if (isInstructor)
                      _buildMenuCard(
                        title: 'Instructor Dashboard',
                        subtitle: 'Manage courses, lessons, and students',
                        icon: Icons.school,
                        color: Colors.blue,
                        onTap: () => _openWebDashboard('/switch_view.php?view=instructor', 'Instructor Panel'),
                      ),
                      
                    if (isInstructor && isAffiliate) const SizedBox(height: 10),
                    
                    if (isAffiliate)
                      _buildMenuCard(
                        title: 'Affiliate Dashboard',
                        subtitle: 'Track your referrals and payouts',
                        icon: Icons.handshake,
                        color: Colors.orange,
                        onTap: () => _openWebDashboard('/switch_view.php?view=affiliate', 'Affiliate Panel'),
                      ),
                      
                    const SizedBox(height: 30),
                  ],
                ),
              ),

            // Account Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Account', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 10),
                  
                  _buildMenuCard(
                    title: 'Profile Settings',
                    subtitle: 'Update your password, avatar, and details',
                    icon: Icons.settings,
                    color: Colors.grey[700]!,
                    onTap: () => _openWebDashboard('/my-profile/', 'Profile Settings'), 
                  ),
                  const SizedBox(height: 10),
                  
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.red.shade100)),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.logout, color: Colors.red),
                      ),
                      title: const Text('Log Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Log Out?'),
                            content: const Text('Are you sure you want to log out of your account?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _logout();
                                },
                                child: const Text('Log Out', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard({required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}

// Reusable Web Dashboard Screen for Roles and Settings
class WebDashboardScreen extends StatefulWidget {
  final String url;
  final String title;

  const WebDashboardScreen({Key? key, required this.url, required this.title}) : super(key: key);

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
      ..setBackgroundColor(AppTheme.backgroundColor)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            if (mounted) setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
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
    );
  }
}
