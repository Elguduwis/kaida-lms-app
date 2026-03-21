import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';
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
              _role = pData['data']['role'];
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

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context, 
      MaterialPageRoute(builder: (context) => const LoginScreen()), 
      (route) => false
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                        backgroundImage: _avatarUrl != null && _avatarUrl!.isNotEmpty ? NetworkImage(_avatarUrl!) : null,
                        child: _avatarUrl == null || _avatarUrl!.isEmpty ? const Icon(Icons.person, size: 40, color: AppTheme.primaryColor) : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text(_email, style: const TextStyle(color: Colors.grey, fontSize: 14)),
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
              
              // Settings List
              const Padding(
                padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
                child: Text('Settings & Preferences', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.cloud_download, color: AppTheme.primaryColor),
                      title: const Text('My Downloads', style: TextStyle(fontWeight: FontWeight.w600)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DownloadsScreen())),
                    ),
                    const Divider(height: 1),
                    
                    // --- DARK MODE TOGGLE ---
                    SwitchListTile(
                      title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w600)),
                      secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: AppTheme.primaryColor),
                      value: Provider.of<ThemeProvider>(context).isDarkMode,
                      onChanged: (value) {
                        Provider.of<ThemeProvider>(context, listen: false).toggleTheme(value);
                      },
                      activeColor: AppTheme.primaryColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

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
