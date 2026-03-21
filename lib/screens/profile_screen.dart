import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../config/api_config.dart';
import '../config/app_theme.dart';
import '../config/theme_provider.dart';
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
      final profileRes = await http.post(Uri.parse(ApiConfig.userProfile), body: {'user_id': userId.toString()});
      final dashRes = await http.post(Uri.parse(ApiConfig.dashboardData), body: {'user_id': userId.toString()});
      
      if (profileRes.statusCode == 200 && dashRes.statusCode == 200) {
        final pData = json.decode(profileRes.body);
        final dData = json.decode(dashRes.body);
        
        if (mounted) {
          setState(() {
            if (pData['status'] == 'success') {
              _name = pData['data']['name'];
              _email = pData['data']['email'];
              _role = pData['data']['role'].toString().toLowerCase();
              _avatarUrl = pData['data']['avatar_url'];
            }
            if (dData['status'] == 'success') {
              _walletBalance = dData['data']['wallet_balance'].toString();
            }
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // RESTORED: Avatar Upload
  Future<void> _pickAndUploadAvatar() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (image == null || _userId == null) return;

    setState(() => _isUploadingAvatar = true);

    try {
      var request = http.MultipartRequest('POST', Uri.parse(ApiConfig.uploadAvatar));
      request.fields['user_id'] = _userId.toString();
      request.files.add(await http.MultipartFile.fromPath('avatar', image.path));

      var response = await request.send();
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var jsonResponse = json.decode(responseData);
        
        if (jsonResponse['status'] == 'success') {
          setState(() => _avatarUrl = jsonResponse['url']);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Avatar updated!'), backgroundColor: Colors.green));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload failed'), backgroundColor: Colors.red));
    } finally {
      setState(() => _isUploadingAvatar = false);
    }
  }

  // RESTORED: Change Password
  void _showChangePasswordModal() {
    final currentPasswordCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Change Password', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextField(
                  controller: currentPasswordCtrl,
                  obscureText: true,
                  decoration: InputDecoration(labelText: 'Current Password', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: newPasswordCtrl,
                  obscureText: true,
                  decoration: InputDecoration(labelText: 'New Password', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, padding: const EdgeInsets.symmetric(vertical: 15)),
                    onPressed: isSubmitting ? null : () async {
                      if (currentPasswordCtrl.text.isEmpty || newPasswordCtrl.text.isEmpty) return;
                      setModalState(() => isSubmitting = true);
                      
                      try {
                        final res = await http.post(
                          Uri.parse(ApiConfig.changePassword),
                          body: {'user_id': _userId.toString(), 'current_password': currentPasswordCtrl.text, 'new_password': newPasswordCtrl.text}
                        );
                        final data = json.decode(res.body);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(data['message']), backgroundColor: data['status'] == 'success' ? Colors.green : Colors.red)
                        );
                      } catch (e) {
                        setModalState(() => isSubmitting = false);
                      }
                    },
                    child: isSubmitting 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                      : const Text('Update Password', style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        });
      }
    );
  }

  // RESTORED: Role-based WebView Routing
  void _openWebDashboard(String title, String path) {
    if (_userId == null) return;
    final url = 'https://academy.kainuwa.africa/api/mobile/webview_auth.php?user_id=$_userId&redirect=$path';
    Navigator.push(context, MaterialPageRoute(builder: (context) => WebDashboardScreen(title: title, url: url)));
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile'), centerTitle: true),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // User Info Card
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _pickAndUploadAvatar,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                              backgroundImage: _avatarUrl != null && _avatarUrl!.isNotEmpty ? NetworkImage(_avatarUrl!) : null,
                              child: _avatarUrl == null || _avatarUrl!.isEmpty ? const Icon(Icons.person, size: 40, color: AppTheme.primaryColor) : null,
                            ),
                            if (_isUploadingAvatar)
                              const Positioned.fill(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
                            Positioned(
                              bottom: 0, right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
                                child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                              ),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text(_email, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                              child: Text('KAIDA Points: $_walletBalance', style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Settings & Features
              const Padding(
                padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
                child: Text('Settings & Preferences', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.cloud_download),
                      title: const Text('My Downloads', style: TextStyle(fontWeight: FontWeight.w600)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DownloadsScreen())),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.favorite),
                      title: const Text('Wishlist', style: TextStyle(fontWeight: FontWeight.w600)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                      onTap: () => _openWebDashboard('Wishlist', '/wishlist.php'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.lock),
                      title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.w600)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                      onTap: _showChangePasswordModal,
                    ),
                    const Divider(height: 1),
                    // THE NEW DARK MODE TOGGLE
                    SwitchListTile(
                      title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w600)),
                      secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: AppTheme.primaryColor),
                      value: themeProvider.isDarkMode,
                      onChanged: (value) => themeProvider.toggleTheme(value),
                      activeColor: AppTheme.primaryColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // RESTORED: Smart Role Dashboards
              if (_role == 'instructor' || _role == 'admin') ...[
                const Padding(padding: EdgeInsets.only(left: 8.0, bottom: 8.0), child: Text('Instructor Tools', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: ListTile(
                    leading: const Icon(Icons.dashboard_customize),
                    title: const Text('Instructor Dashboard', style: TextStyle(fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    onTap: () => _openWebDashboard('Instructor Dashboard', '/instructor/dashboard.php'),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              if (_role == 'affiliate' || _role == 'admin') ...[
                const Padding(padding: EdgeInsets.only(left: 8.0, bottom: 8.0), child: Text('Affiliate Tools', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: ListTile(
                    leading: const Icon(Icons.campaign),
                    title: const Text('Affiliate Dashboard', style: TextStyle(fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    onTap: () => _openWebDashboard('Affiliate Dashboard', '/affiliate/dashboard.php'),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Logout Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: _logout,
              ),
            ],
          ),
    );
  }
}

// RESTORED: Web Dashboard Screen for routing to PHP pages safely
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
      ..setJavaScriptMode(JavaScriptMode.unrestricted)\n      ..setBackgroundColor(AppTheme.backgroundColor)
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
          if (_isLoading) const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
        ],
      ),
    );
  }
}
