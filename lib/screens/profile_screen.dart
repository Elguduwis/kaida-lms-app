import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../config/api_config.dart';
import '../config/app_theme.dart';
import '../config/theme_provider.dart';
import '../widgets/kaida_loader.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int? _userId;
  String _name = "Loading...";
  String _email = "Loading...";
  String _role = "student";
  String? _avatarUrl;
  String _walletBalance = "0.00";
  
  String _shareMessage = "Join me on Kaida Learn! Start building your future today.";
  String _shareUrl = "https://play.google.com/store/apps/details?id=com.kainuwa.academy";
  
  bool _isLoading = true;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt('user_id');
    
    if (mounted) {
      setState(() {
        // Fix: Properly fallback to 'name' or 'full_name' so it doesn't default to Kaida Student
        _name = prefs.getString('full_name') ?? prefs.getString('name') ?? prefs.getString('username') ?? 'Loading...';
        _email = prefs.getString('email') ?? '';
        _role = prefs.getString('role') ?? 'student';
      });
    }

    if (_userId == null) return;

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.userProfile),
        body: {'user_id': _userId.toString()}
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && mounted) {
          setState(() {
            _name = data['data']['name'] ?? data['data']['full_name'] ?? data['data']['username'] ?? _name;
            _email = data['data']['email'] ?? _email;
            _role = data['data']['role'] ?? _role;
            
            String rawAvatar = data['data']['avatar_url']?.toString() ?? '';
            if (rawAvatar.isNotEmpty && !rawAvatar.startsWith('http')) {
              _avatarUrl = 'https://academy.kainuwa.africa/$rawAvatar';
            } else {
              _avatarUrl = rawAvatar.isNotEmpty ? rawAvatar : null;
            }
            
            _walletBalance = data['data']['wallet_balance']?.toString() ?? '0.00';
            
            if (data['data']['share_message'] != null) _shareMessage = data['data']['share_message'];
            if (data['data']['share_url'] != null) _shareUrl = data['data']['share_url'];

            _isLoading = false;
            
            prefs.setString('full_name', _name);
            prefs.setString('email', _email);
            prefs.setString('role', _role);
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // RESTORED: Native Image Picker & Uploader
  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null || _userId == null) return;

      setState(() => _isLoading = true);

      var request = http.MultipartRequest('POST', Uri.parse(ApiConfig.uploadAvatar));
      request.fields['user_id'] = _userId.toString();
      request.files.add(await http.MultipartFile.fromPath('avatar', image.path));

      var response = await request.send();
      if (response.statusCode == 200) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Avatar updated successfully!'), backgroundColor: Colors.green));
         _loadProfileData(); 
      } else {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update avatar'), backgroundColor: Colors.red));
         setState(() => _isLoading = false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error uploading avatar'), backgroundColor: Colors.red));
      setState(() => _isLoading = false);
    }
  }

  // RESTORED: Secure Change Password Dialog
  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: oldPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      prefixIcon: const Icon(Icons.lock_rounded, color: AppTheme.primaryColor),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
                      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryColor, width: 2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: newPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: const Icon(Icons.lock_reset_rounded, color: AppTheme.primaryColor),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
                      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryColor, width: 2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      prefixIcon: const Icon(Icons.lock_reset_rounded, color: AppTheme.primaryColor),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
                      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryColor, width: 2)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
              isSubmitting 
                ? const Padding(padding: EdgeInsets.all(8.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                    onPressed: () async {
                      if (newPasswordController.text != confirmPasswordController.text) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New passwords do not match')));
                        return;
                      }
                      setStateDialog(() => isSubmitting = true);
                      
                      try {
                        final response = await http.post(
                          Uri.parse(ApiConfig.changePassword),
                          body: {
                            'user_id': _userId.toString(),
                            'old_password': oldPasswordController.text,
                            'new_password': newPasswordController.text,
                          }
                        );
                        final data = json.decode(response.body);
                        Navigator.pop(context);
                        if (data['status'] == 'success') {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed successfully!'), backgroundColor: Colors.green));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Failed to change password'), backgroundColor: Colors.red));
                        }
                      } catch (e) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connection error'), backgroundColor: Colors.red));
                      }
                    },
                    child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
            ],
          );
        }
      )
    );
  }

  // RESTORED: Native Share Functionality
  void _shareApp() {
    Share.share("$_shareMessage \n\n$_shareUrl");
  }

  void _handleLogout() async {
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
              await prefs.clear();
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
        automaticallyImplyLeading: false, 
        title: Text('Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
      ),
      body: SafeArea(
        child: _isLoading && _name == "Loading..."
        ? const Center(child: KaidaLoader()) 
        : SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 20),
                
                // 1. Avatar & Info Section
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _pickAndUploadImage, // TRIGGER NATIVE GALLERY
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                              backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                              child: _avatarUrl == null 
                                  ? const Icon(Icons.person_rounded, size: 50, color: AppTheme.primaryColor) 
                                  : null,
                            ),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle, border: Border.all(color: isDark ? AppTheme.darkBackgroundColor : Colors.white, width: 3)),
                              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(_name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                      const SizedBox(height: 4),
                      Text(_email, style: TextStyle(fontSize: 15, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                      
                      // 2. Affiliate / Instructor Role Badge
                      if (_role != 'student')
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                          ),
                          child: Text(
                            _role.toUpperCase(),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryColor, letterSpacing: 1),
                          ),
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // 3. Option Tiles with strict Solid Rounded Icons
                _buildOptionTile(
                  icon: Icons.person_rounded,
                  title: 'Edit Profile',
                  isDark: isDark,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edit Profile coming soon!')));
                  },
                ),
                _buildOptionTile(
                  icon: Icons.account_balance_wallet_rounded,
                  title: 'Kaida Tokens',
                  isDark: isDark,
                  trailing: Text(_walletBalance, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor, fontSize: 16)), // NO NAIRA SIGN
                  onTap: () {},
                ),
                _buildOptionTile(
                  icon: Icons.favorite_rounded, // MY WISHLIST
                  title: 'My Wishlist',
                  isDark: isDark,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wishlist coming soon!')));
                  },
                ),
                _buildOptionTile(
                  icon: Icons.notifications_rounded,
                  title: 'Notifications',
                  isDark: isDark,
                  onTap: () {},
                ),
                _buildOptionTile(
                  icon: Icons.security_rounded, // SECURITY TILE
                  title: 'Security',
                  isDark: isDark,
                  onTap: _showChangePasswordDialog, // CHANGE PASSWORD TRIGGER
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
                
                _buildOptionTile(
                  icon: Icons.share_rounded, // SHARE APP RESTORED
                  title: 'Share App',
                  isDark: isDark,
                  onTap: _shareApp,
                ),

                _buildOptionTile(
                  icon: Icons.dark_mode_rounded,
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
                  icon: Icons.help_rounded,
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
                  trailing: const SizedBox(),
                  onTap: _handleLogout,
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
      ),
    );
  }
}
