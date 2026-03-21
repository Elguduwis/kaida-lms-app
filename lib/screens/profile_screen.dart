import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../config/api_config.dart';
import '../config/app_theme.dart';
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
      if (profileRes.statusCode == 200) {
        final pData = json.decode(profileRes.body);
        if (pData['status'] == 'success' && mounted) {
          setState(() {
            _name = pData['data']['name'];
            _email = pData['data']['email'];
            _role = pData['data']['role'];
            _avatarUrl = pData['data']['avatar_url'];
          });
        }
      }

      final dashRes = await http.post(Uri.parse(ApiConfig.dashboardData), body: {'user_id': userId.toString()});
      if (dashRes.statusCode == 200) {
        final dData = json.decode(dashRes.body);
        if (dData['status'] == 'success' && mounted) {
          setState(() => _walletBalance = dData['data']['wallet_balance'].toString());
        }
      }
    } catch (e) {
      debugPrint("Profile Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadAvatar() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 80);
    
    if (pickedFile != null && _userId != null) {
      setState(() => _isUploadingAvatar = true);
      try {
        var request = http.MultipartRequest('POST', Uri.parse(ApiConfig.uploadAvatar));
        request.fields['user_id'] = _userId.toString();
        request.files.add(await http.MultipartFile.fromPath('avatar', pickedFile.path));
        
        var response = await request.send();
        if (response.statusCode == 200) {
          var responseData = await response.stream.bytesToString();
          var jsonResponse = json.decode(responseData);
          if (jsonResponse['status'] == 'success') {
            setState(() => _avatarUrl = jsonResponse['avatar_url']);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile picture updated on Kainuwa Academy!'), backgroundColor: Colors.green));
          } else {
            throw Exception(jsonResponse['message']);
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update picture.'), backgroundColor: Colors.red));
      } finally {
        setState(() => _isUploadingAvatar = false);
      }
    }
  }

  void _showPasswordDialog() {
    final currentPasswordCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    bool isChanging = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: currentPasswordCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Current Password', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: newPasswordCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'New Password', border: OutlineInputBorder()),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isChanging ? null : () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                  onPressed: isChanging ? null : () async {
                    if (currentPasswordCtrl.text.isEmpty || newPasswordCtrl.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
                      return;
                    }

                    setDialogState(() => isChanging = true);

                    try {
                      final response = await http.post(
                        Uri.parse(ApiConfig.changePassword),
                        body: {
                          'user_id': _userId.toString(),
                          'current_password': currentPasswordCtrl.text,
                          'new_password': newPasswordCtrl.text,
                        },
                      );

                      final data = json.decode(response.body);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(data['message']),
                          backgroundColor: data['status'] == 'success' ? Colors.green : Colors.red,
                        ),
                      );
                    } catch (e) {
                      setDialogState(() => isChanging = false);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connection error')));
                    }
                  },
                  child: isChanging ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Save', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      }
    );
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const LoginScreen()), (Route<dynamic> route) => false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(backgroundColor: AppTheme.backgroundColor, body: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)));

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // HEADER & AVATAR
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 60, bottom: 40),
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white24,
                          backgroundImage: (_avatarUrl != null && _avatarUrl!.isNotEmpty) ? NetworkImage(_avatarUrl!) : null,
                          child: (_avatarUrl == null || _avatarUrl!.isEmpty) ? const Icon(Icons.person, size: 50, color: Colors.white) : null,
                        ),
                      ),
                      GestureDetector(
                        onTap: _uploadAvatar,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: _isUploadingAvatar 
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor))
                            : const Icon(Icons.camera_alt, color: AppTheme.primaryColor, size: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(_name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(_email, style: const TextStyle(fontSize: 14, color: Colors.white70)),
                ],
              ),
            ),

            // KAIDA WALLET CARD
            Transform.translate(
              offset: const Offset(0, -30),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.account_balance_wallet, color: AppTheme.primaryColor, size: 20),
                            SizedBox(width: 8),
                            Text('KAIDA Wallet', style: TextStyle(color: Colors.black54, fontSize: 14, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('$_walletBalance KAIDA', style: const TextStyle(color: Colors.black87, fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wallet top-up is coming soon!')));
                      },
                      child: const Text('Top Up', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ),
            ),

            // MENU LIST
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildMenuTile(Icons.favorite, 'My Wishlist', () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wishlist page coming soon!')));
                  }),
                  _buildMenuTile(Icons.cloud_download, 'Digital Downloads', () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const DownloadsScreen()));
                  }),
                  
                  if (_role == 'instructor' || _role == 'admin')
                    _buildMenuTile(Icons.dashboard, 'Instructor Dashboard', () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => WebDashboardScreen(title: 'Instructor Panel', url: 'https://academy.kainuwa.africa/api/mobile/webview_auth.php?user_id=$_userId&redirect=/instructor/dashboard')));
                    }),

                  _buildMenuTile(Icons.share, 'Affiliate Dashboard', () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => WebDashboardScreen(title: 'Affiliate Panel', url: 'https://academy.kainuwa.africa/api/mobile/webview_auth.php?user_id=$_userId&redirect=/affiliate/dashboard')));
                  }),

                  _buildMenuTile(Icons.lock, 'Change Password', _showPasswordDialog),

                  _buildMenuTile(Icons.logout, 'Log Out', _logout, isDestructive: true),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: isDestructive ? Colors.red.withOpacity(0.1) : AppTheme.primaryColor.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: isDestructive ? Colors.red : AppTheme.primaryColor, size: 20),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isDestructive ? Colors.red : Colors.black87)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
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
          if (_isLoading) const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
        ],
      ),
    );
  }
}
