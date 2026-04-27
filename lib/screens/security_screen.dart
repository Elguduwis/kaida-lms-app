import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../config/app_theme.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({Key? key}) : super(key: key);

  @override
  _SecurityScreenState createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSubmitting = false;
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  Future<void> _updatePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New passwords do not match')));
      return;
    }
    
    if (_oldPasswordController.text.isEmpty || _newPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() => _isSubmitting = true);
    
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.changePassword),
        body: {
          'user_id': userId.toString(),
          'old_password': _oldPasswordController.text,
          'new_password': _newPasswordController.text,
        }
      );
      
      final data = json.decode(response.body);
      
      if (data['status'] == 'success') {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed successfully!'), backgroundColor: Colors.green));
        Navigator.pop(context);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Failed to change password'), backgroundColor: Colors.red));
        setState(() => _isSubmitting = false);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connection error. Try again.'), backgroundColor: Colors.red));
      setState(() => _isSubmitting = false);
    }
  }

  Widget _buildPasswordField({
    required String label, 
    required TextEditingController controller, 
    required bool obscureText, 
    required VoidCallback toggleObscure,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
        TextField(
          controller: controller,
          obscureText: obscureText,
          style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryColor, width: 2)),
            prefixIconConstraints: const BoxConstraints(maxHeight: 32, maxWidth: 32),
            prefixIcon: const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.lock_rounded, color: AppTheme.primaryColor, size: 20),
            ),
            suffixIconConstraints: const BoxConstraints(maxHeight: 32, maxWidth: 32),
            suffixIcon: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, color: Colors.grey.shade400, size: 20),
              onPressed: toggleObscure,
            ),
          ),
        ),
      ],
    );
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
        title: Text('Security', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.shield_rounded, size: 80, color: AppTheme.primaryColor),
            const SizedBox(height: 16),
            Text('Update Password', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
            const SizedBox(height: 8),
            Text('Ensure your account stays secure by using a strong password.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
            const SizedBox(height: 40),
            
            _buildPasswordField(
              label: 'Current Password', 
              controller: _oldPasswordController, 
              obscureText: _obscureOld, 
              toggleObscure: () => setState(() => _obscureOld = !_obscureOld),
              isDark: isDark,
            ),
            const SizedBox(height: 24),
            
            _buildPasswordField(
              label: 'New Password', 
              controller: _newPasswordController, 
              obscureText: _obscureNew, 
              toggleObscure: () => setState(() => _obscureNew = !_obscureNew),
              isDark: isDark,
            ),
            const SizedBox(height: 24),
            
            _buildPasswordField(
              label: 'Confirm New Password', 
              controller: _confirmPasswordController, 
              obscureText: _obscureConfirm, 
              toggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm),
              isDark: isDark,
            ),
            const SizedBox(height: 40),
            
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _updatePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 0,
                ),
                child: _isSubmitting 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Save Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
