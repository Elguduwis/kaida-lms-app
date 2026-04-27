import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../config/api_config.dart';
import '../config/app_theme.dart';
import '../config/theme_provider.dart';
import 'login_screen.dart';
import 'main_layout.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = "Loading...";
  String _email = "Loading...";
  String? _avatarUrl;
  String _walletBalance = "0.00";
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    
    // 1. Instantly load cached local data
    if (mounted) {
      setState(() {
        _name = prefs.getString('full_name') ?? prefs.getString('username') ?? 'Kaida Student';
        _email = prefs.getString('email') ?? '';
      });
    }

    if (userId == null) return;

    // 2. Fetch fresh data from the server quietly in the background
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.userProfile),
        body: {'user_id': userId.toString()}
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && mounted) {
          setState(() {
            _name = data['data']['full_name'] ?? data['data']['username'] ?? _name;
            _email = data['data']['email'] ?? _email;
            
            String rawAvatar = data['data']['avatar_url']?.toString() ?? '';
            if (rawAvatar.isNotEmpty && !rawAvatar.startsWith('http')) {
              _avatarUrl = 'https://academy.kainuwa.africa/$rawAvatar';
            } else {
              _avatarUrl = rawAvatar.isNotEmpty ? rawAvatar : null;
            }
            
            _walletBalance = data['data']['wallet_balance']?.toString() ?? '0.00';
            _isLoading = false;
            
            // Update the cache
            prefs.setString('full_name', _name);
            prefs.setString('email', _email);
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleLogout() async {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to log out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear(); // Destroys the local token and session
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context, 
                MaterialPageRoute(builder: (_) => const LoginScreen()), 
                (route) => false
              );
            },
            child: const Text('Log Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurfaceColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black12 : Colors.grey.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.primaryColor, size: 28),
            ),
            const SizedBox(height: 12),
            Text(count, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(fontSize: 14, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required bool isDark,
    Widget? trailing,
    VoidCallback? onTap,
    bool isLogout = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isLogout 
              ? Colors.red.withOpacity(0.1) 
              : AppTheme.primaryColor.withOpacity(isDark ? 0.15 : 0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: isLogout ? Colors.red : AppTheme.primaryColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isLogout ? Colors.red : (isDark ? Colors.white : Colors.black87),
        ),
      ),
      trailing: trailing ?? Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey.shade400),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackgroundColor : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text('Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black, size: 20),
          // Routes safely back to the Home tab instead of popping the app
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainLayout(initialIndex: 0))),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit_rounded, color: AppTheme.primaryColor, size: 22),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edit Profile coming soon!')));
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // 1. Avatar & Info Section
            Center(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                        child: _avatarUrl == null 
                            ? const Icon(Icons.person, size: 50, color: AppTheme.primaryColor) 
                            : null,
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle, border: Border.all(color: isDark ? AppTheme.darkBackgroundColor : Colors.white, width: 3)),
                        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(_name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                  const SizedBox(height: 4),
                  Text(_email, style: TextStyle(fontSize: 15, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // 2. Stats Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  _buildStatCard('My Courses', '2', Icons.play_lesson_rounded, isDark),
                  const SizedBox(width: 16),
                  _buildStatCard('Downloads', '0', Icons.cloud_download_rounded, isDark),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // 3. Menu Options
            _buildOptionTile(
              icon: Icons.person_outline_rounded,
              title: 'Edit Profile',
              isDark: isDark,
              onTap: () {},
            ),
            _buildOptionTile(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Kaida Tokens',
              isDark: isDark,
              trailing: Text('₦$_walletBalance', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor, fontSize: 16)),
              onTap: () {},
            ),
            _buildOptionTile(
              icon: Icons.notifications_none_rounded,
              title: 'Notifications',
              isDark: isDark,
              onTap: () {},
            ),
            _buildOptionTile(
              icon: Icons.lock_outline_rounded,
              title: 'Security',
              isDark: isDark,
              onTap: () {},
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
              child: Divider(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
            ),
            
            _buildOptionTile(
              icon: Icons.language_rounded,
              title: 'Language',
              isDark: isDark,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('English', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey.shade400),
                ],
              ),
              onTap: () {},
            ),
            
            // Native Theme Switcher
            _buildOptionTile(
              icon: Icons.dark_mode_outlined,
              title: 'Dark Mode',
              isDark: isDark,
              trailing: Switch(
                value: isDark,
                activeColor: AppTheme.primaryColor,
                onChanged: (value) {
                  themeProvider.toggleTheme(value);
                },
              ),
              onTap: () {
                themeProvider.toggleTheme(!isDark);
              },
            ),
            
            _buildOptionTile(
              icon: Icons.help_outline_rounded,
              title: 'Help Center',
              isDark: isDark,
              onTap: () {},
            ),
            
            const SizedBox(height: 10),
            
            _buildOptionTile(
              icon: Icons.logout_rounded,
              title: 'Log Out',
              isDark: isDark,
              isLogout: true,
              trailing: const SizedBox(), // No arrow for logout
              onTap: _handleLogout,
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
