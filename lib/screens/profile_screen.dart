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
      final profileRes = await http.post(Uri.parse(ApiConfig.userProfile), body: {'user_id': userId.toString()});
      if (profileRes.statusCode == 200) {
        final pData = json.decode(profileRes.body);
        if (pData['status'] == 'success' && mounted) {
          setState(() {
            _name = pData['data']['name'] ?? 'Learner';
            _email = pData['data']['email'] ?? '';
            // Safe parsing to ensure no null breaks the UI
            _role = pData['data']['role']?.toString().trim() ?? 'student';
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

      final settingsRes = await http.get(Uri.parse(ApiConfig.appSettings));
      if (settingsRes.statusCode == 200) {
        final setData = json.decode(settingsRes.body);
        if (setData['status'] == 'success' && mounted) {
          setState(() {
            _facebookUrl = setData['data']['facebook'] ?? '';
            _twitterUrl = setData['data']['twitter'] ?? '';
            _instagramUrl = setData['data']['instagram'] ?? '';
            if (setData['data']['share_message'] != null) _shareMessage = setData['data']['share_message'];
            if (setData['data']['share_url'] != null) _shareUrl = setData['data']['share_url'];
          });
        }
      }
    } catch (e) {
      debugPrint("Profile Error: $e");
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
            String newUrl = jsonResponse['url'] ?? jsonResponse['avatar_url'];
            newUrl += '?t=${DateTime.now().millisecondsSinceEpoch}';
            setState(() => _avatarUrl = newUrl);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile picture updated!'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating));
          } else {
            throw Exception(jsonResponse['message']);
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update picture.'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
      } finally {
        setState(() => _isUploadingAvatar = false);
      }
    }
  }

  void _showChangePasswordModal() {
    final currentPasswordCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Change Password', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                TextField(
                  controller: currentPasswordCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Current Password', 
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'New Password', 
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    prefixIcon: const Icon(Icons.lock_reset),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor, 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
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
                          SnackBar(content: Text(data['message']), backgroundColor: data['status'] == 'success' ? Colors.green : Colors.red, behavior: SnackBarBehavior.floating)
                        );
                      } catch (e) {
                        setModalState(() => isSubmitting = false);
                      }
                    },
                    child: isSubmitting 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        });
      }
    );
  }

  void _openWebDashboard(String title, String path) {
    if (_userId == null) return;
    final url = 'https://academy.kainuwa.africa/api/mobile/webview_auth.php?user_id=$_userId&redirect=$path';
    Navigator.push(context, MaterialPageRoute(builder: (context) => WebDashboardScreen(title: title, url: url)));
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    try { await WebViewCookieManager().clearCookies(); } catch (e) {}
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const LoginScreen()), (Route<dynamic> route) => false);
  }

  // --- UPGRADED: BULLETPROOF FUZZY MATCHING BADGE GENERATOR ---
  Widget _buildRoleBadge(String role) {
    String safeRole = role.toLowerCase().trim();
    
    String title = 'Standard Member';
    Color badgeColor = const Color(0xFFD4AF37); // Default Gold
    IconData icon = Icons.verified_rounded;

    if (safeRole.contains('admin')) {
      title = 'Administrator';
      badgeColor = Colors.redAccent;
      icon = Icons.admin_panel_settings_rounded;
    } else if (safeRole.contains('instructor') || safeRole.contains('teacher')) {
      title = 'Instructor';
      badgeColor = Colors.blueAccent;
      icon = Icons.school_rounded;
    } else if (safeRole.contains('affiliate') || safeRole.contains('partner')) {
      title = 'Affiliate Partner';
      badgeColor = Colors.purpleAccent;
      icon = Icons.campaign_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15), 
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withOpacity(0.3))
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: badgeColor, size: 14),
          const SizedBox(width: 6),
          Text(title, style: TextStyle(color: badgeColor, fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final surfaceColor = isDark ? AppTheme.darkSurfaceColor : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final iconColor = isDark ? Colors.grey.shade400 : Colors.grey.shade700;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackgroundColor : const Color(0xFFF8F9FE),
      body: _isLoading 
        ? const Center(child: KaidaLoader())
        : SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Profile', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: textColor, letterSpacing: -0.5)),
                        TextButton(
                          onPressed: _logout,
                          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                          child: const Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                        )
                      ],
                    ),
                  ),

                  Center(
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.white, width: 4),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                              ),
                              child: CircleAvatar(
                                radius: 50,
                                backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                                backgroundImage: (_avatarUrl != null && _avatarUrl!.isNotEmpty) ? NetworkImage(_avatarUrl!) : null,
                                child: (_avatarUrl == null || _avatarUrl!.isEmpty) ? Icon(Icons.person, size: 50, color: Colors.grey.shade400) : null,
                              ),
                            ),
                            GestureDetector(
                              onTap: _uploadAvatar,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white, 
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
                                ),
                                child: _isUploadingAvatar 
                                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor))
                                  : const Icon(Icons.edit, color: AppTheme.primaryColor, size: 14),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(_name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                        const SizedBox(height: 6),
                        
                        // DEPLOYS THE NEW BULLETPROOF BADGE
                        _buildRoleBadge(_role),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                        const SizedBox(height: 12),
                        
                        Container(
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.03), blurRadius: 15, offset: const Offset(0, 5))],
                          ),
                          child: Column(
                            children: [
                              _buildSettingsRow(Icons.account_balance_wallet_outlined, 'KAIDA Wallet', '$_walletBalance KAIDA', onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wallet top-up coming soon!'), behavior: SnackBarBehavior.floating)), iconColor: iconColor, textColor: textColor),
                              _buildDivider(isDark),
                              _buildSettingsRow(Icons.favorite_border_rounded, 'My Wishlist', '', onTap: () => _openWebDashboard('My Wishlist', '/wishlist.php'), iconColor: iconColor, textColor: textColor),
                              
                              // Check visibility using the same safe logic
                              if (_role.trim().toLowerCase().contains('instructor') || _role.trim().toLowerCase().contains('admin')) ...[
                                _buildDivider(isDark),
                                _buildSettingsRow(Icons.dashboard_outlined, 'Instructor Panel', '', onTap: () => _openWebDashboard('Instructor Panel', '/instructor/dashboard.php'), iconColor: iconColor, textColor: textColor),
                              ],
                              if (_role.trim().toLowerCase().contains('affiliate') || _role.trim().toLowerCase().contains('admin')) ...[
                                _buildDivider(isDark),
                                _buildSettingsRow(Icons.campaign_outlined, 'Affiliate Panel', '', onTap: () => _openWebDashboard('Affiliate Panel', '/affiliate/dashboard.php'), iconColor: iconColor, textColor: textColor),
                              ],
                              
                              _buildDivider(isDark),
                              _buildSettingsRow(Icons.lock_outline_rounded, 'Change Password', '', onTap: _showChangePasswordModal, iconColor: iconColor, textColor: textColor),
                              _buildDivider(isDark),
                              _buildSettingsRow(Icons.share_outlined, 'Share Application', '', onTap: _shareApp, iconColor: iconColor, textColor: textColor),
                              _buildDivider(isDark),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Row(
                                  children: [
                                    Icon(Icons.dark_mode_outlined, color: iconColor, size: 22),
                                    const SizedBox(width: 16),
                                    Expanded(child: Text('Dark Theme', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor))),
                                    Switch(
                                      value: themeProvider.isDarkMode,
                                      onChanged: (val) => themeProvider.toggleTheme(val),
                                      activeColor: AppTheme.primaryColor,
                                      activeTrackColor: AppTheme.primaryColor.withOpacity(0.3),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 40),

                        Center(
                          child: Column(
                            children: [
                              Text("Connect with us", style: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade400, fontSize: 13, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_facebookUrl.isNotEmpty)
                                    IconButton(icon: const FaIcon(FontAwesomeIcons.facebook, color: Colors.blueAccent, size: 24), onPressed: () => _launchSocial(_facebookUrl)),
                                  if (_twitterUrl.isNotEmpty)
                                    IconButton(icon: FaIcon(FontAwesomeIcons.xTwitter, color: isDark ? Colors.white : Colors.black87, size: 24), onPressed: () => _launchSocial(_twitterUrl)),
                                  if (_instagramUrl.isNotEmpty)
                                    IconButton(icon: const FaIcon(FontAwesomeIcons.instagram, color: Colors.pinkAccent, size: 24), onPressed: () => _launchSocial(_instagramUrl)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildSettingsRow(IconData icon, String title, String trailingText, {required VoidCallback onTap, required Color iconColor, required Color textColor}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor))),
            if (trailingText.isNotEmpty) 
              Text(trailingText, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor, fontSize: 14)),
            if (trailingText.isEmpty)
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(height: 1, thickness: 1, color: isDark ? Colors.grey.shade800 : Colors.grey.shade100, indent: 54);
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
  bool _hasError = false; 

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppTheme.backgroundColor)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) { if (mounted) setState(() { _isLoading = true; _hasError = false; }); },
          onPageFinished: (String url) { if (mounted) setState(() => _isLoading = false); },
          onWebResourceError: (WebResourceError error) {
            if (mounted) setState(() { _isLoading = false; _hasError = true; });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Stack(
        children: [
          if (_hasError)
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
            
          if (_isLoading && !_hasError) const Center(child: KaidaLoader()),
        ],
      ),
    );
  }
}
