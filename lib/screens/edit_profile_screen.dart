import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../config/app_theme.dart';
import '../widgets/kaida_loader.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  
  int? _userId;
  String _role = 'student';
  String _originalUsername = '';

  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _headlineController = TextEditingController();
  final _bioController = TextEditingController();
  
  bool _isProfilePublic = false;
  bool _showCoursesOnProfile = true;

  Timer? _usernameDebounce;
  bool _isCheckingUsername = false;
  bool? _isUsernameAvailable;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  @override
  void dispose() {
    _usernameDebounce?.cancel();
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _headlineController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt('user_id');
    
    if (_userId == null) return;

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.getProfileDetails),
        body: {'user_id': _userId.toString()}
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && mounted) {
          final user = data['data'];
          setState(() {
            _originalUsername = user['username'] ?? '';
            _fullNameController.text = user['full_name'] ?? '';
            _usernameController.text = _originalUsername;
            _emailController.text = user['email'] ?? '';
            _headlineController.text = user['headline'] ?? '';
            _bioController.text = user['bio'] ?? '';
            
            _isProfilePublic = user['is_profile_public'] == 1;
            _showCoursesOnProfile = user['show_courses_on_profile'] == 1;
            _role = user['role'] ?? 'student';
            
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onUsernameChanged(String value) {
    if (_usernameDebounce?.isActive ?? false) _usernameDebounce!.cancel();
    
    if (value.trim() == _originalUsername) {
      setState(() { _isUsernameAvailable = null; _isCheckingUsername = false; });
      return;
    }
    
    if (value.isEmpty) {
      setState(() { _isUsernameAvailable = null; _isCheckingUsername = false; });
      return;
    }

    setState(() => _isCheckingUsername = true);
    
    _usernameDebounce = Timer(const Duration(milliseconds: 600), () async {
      try {
        final response = await http.get(Uri.parse('${ApiConfig.checkUsername}?username=${value.trim()}'));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'success' && mounted) {
            setState(() {
              _isUsernameAvailable = data['available'];
              _isCheckingUsername = false;
            });
          }
        }
      } catch (e) {
        if (mounted) setState(() => _isCheckingUsername = false);
      }
    });
  }

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();
    
    if (_fullNameController.text.trim().isEmpty || _usernameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name and Username are required.')));
      return;
    }
    
    if (_isUsernameAvailable == false) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please choose an available username.')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.updateProfile),
        body: {
          'user_id': _userId.toString(),
          'username': _usernameController.text.trim(),
          'full_name': _fullNameController.text.trim(),
          'headline': _headlineController.text.trim(),
          'bio': _bioController.text.trim(),
          'is_profile_public': _isProfilePublic ? '1' : '0',
          'show_courses_on_profile': _showCoursesOnProfile ? '1' : '0',
          'role': _role,
        }
      );

      final data = json.decode(response.body);
      if (mounted) {
        setState(() => _isSaving = false);
        if (data['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green));
          
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('full_name', _fullNameController.text.trim());
          await prefs.setString('username', _usernameController.text.trim());
          
          Navigator.pop(context); // Go back to Profile
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Update failed'), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A network error occurred.'), backgroundColor: Colors.red));
      }
    }
  }

  Widget _buildCustomInput({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required bool isDark,
    bool readOnly = false,
    int maxLines = 1,
    Function(String)? onChanged,
    Widget? statusWidget,
  }) {
    return Row(
      crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Container(
          margin: EdgeInsets.only(bottom: maxLines > 1 ? 0 : 8, top: maxLines > 1 ? 24 : 0),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(readOnly ? 0.03 : 0.08), shape: BoxShape.circle),
          child: Icon(icon, color: readOnly ? Colors.grey : AppTheme.primaryColor, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
              TextField(
                controller: controller,
                readOnly: readOnly,
                onChanged: onChanged,
                maxLines: maxLines,
                style: TextStyle(color: readOnly ? Colors.grey : (isDark ? Colors.white : Colors.black), fontSize: 16, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: maxLines > 1 ? 12 : 8),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: readOnly ? Colors.grey.shade300 : AppTheme.primaryColor, width: 2)),
                  suffixIconConstraints: const BoxConstraints(maxHeight: 32, maxWidth: 32),
                  suffixIcon: statusWidget,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Widget? usernameStatusWidget;
    if (_isCheckingUsername) {
      usernameStatusWidget = const Padding(padding: EdgeInsets.only(right: 8, bottom: 8), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)));
    } else if (_isUsernameAvailable == true) {
      usernameStatusWidget = const Padding(padding: EdgeInsets.only(right: 8, bottom: 8), child: Icon(Icons.check_circle, color: Colors.green, size: 18));
    } else if (_isUsernameAvailable == false) {
      usernameStatusWidget = const Padding(padding: EdgeInsets.only(right: 8, bottom: 8), child: Icon(Icons.cancel, color: Colors.red, size: 18));
    }

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackgroundColor : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Edit Profile', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading 
        ? const Center(child: KaidaLoader()) 
        : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCustomInput(icon: Icons.person_rounded, label: 'Full Name', controller: _fullNameController, isDark: isDark),
                const SizedBox(height: 24),
                
                _buildCustomInput(
                  icon: Icons.alternate_email_rounded, 
                  label: 'Username', 
                  controller: _usernameController, 
                  isDark: isDark, 
                  onChanged: _onUsernameChanged, 
                  statusWidget: usernameStatusWidget
                ),
                if (_isUsernameAvailable == false) 
                  const Padding(padding: EdgeInsets.only(left: 58, top: 4), child: Text('Username is already taken', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold))),
                const SizedBox(height: 24),
                
                _buildCustomInput(icon: Icons.email_rounded, label: 'Email address', controller: _emailController, isDark: isDark, readOnly: true),
                const SizedBox(height: 30),
                
                if (_role == 'instructor' || _role == 'admin') ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text('PUBLIC PROFILE', style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
                  _buildCustomInput(icon: Icons.badge_rounded, label: 'Headline', controller: _headlineController, isDark: isDark),
                  const SizedBox(height: 24),
                  _buildCustomInput(icon: Icons.description_rounded, label: 'Biography', controller: _bioController, isDark: isDark, maxLines: 4),
                  const SizedBox(height: 30),
                ],

                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text('PRIVACY SETTINGS', style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
                
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppTheme.primaryColor,
                  title: Text('Make Profile Public', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
                  subtitle: Text('Allow others to view your profile', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  value: _isProfilePublic,
                  onChanged: (val) => setState(() => _isProfilePublic = val),
                ),
                
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppTheme.primaryColor,
                  title: Text('Show Enrolled Courses', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
                  subtitle: Text('Display your active courses on your profile', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  value: _showCoursesOnProfile,
                  onChanged: (val) => setState(() => _showCoursesOnProfile = val),
                ),
                
                const SizedBox(height: 40),
                
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor, 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), 
                      elevation: 0
                    ),
                    child: _isSaving 
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
    );
  }
}
