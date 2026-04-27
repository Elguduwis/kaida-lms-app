import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../config/app_theme.dart';
import '../services/auth_service.dart';
import '../widgets/kaida_loader.dart';
import 'login_screen.dart';
import 'otp_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  String? _selectedLanguage = 'en';
  String? _selectedCountry;
  String? _selectedState;
  String? _selectedCity;
  bool _agreeTerms = false;
  
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Placeholder data - we will connect this to your API next
  final List<Map<String, String>> _languages = [{'id': 'en', 'name': 'English'}, {'id': 'ha', 'name': 'Hausa'}];
  final List<Map<String, String>> _countries = [{'id': '1', 'name': 'Nigeria'}];
  final List<Map<String, String>> _states = [{'id': '1', 'name': 'Kano'}, {'id': '2', 'name': 'Kaduna'}, {'id': '3', 'name': 'Abuja'}];
  final List<Map<String, String>> _cities = [{'id': '1', 'name': 'Kano City'}, {'id': '2', 'name': 'Zaria'}, {'id': '3', 'name': 'Gwarinpa'}];

  void _handleRegister() async {
    FocusScope.of(context).unfocus();
    
    if (_fullNameController.text.isEmpty || _usernameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields')));
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }
    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You must agree to the Terms & Conditions')));
      return;
    }
    
    setState(() => _isLoading = true);
    
    final userData = {
      'full_name': _fullNameController.text.trim(),
      'username': _usernameController.text.trim().toLowerCase(),
      'email': _emailController.text.trim(),
      'language': _selectedLanguage ?? 'en',
      'country_id': _selectedCountry ?? '',
      'state_id': _selectedState ?? '',
      'city_id': _selectedCity ?? '',
      'password': _passwordController.text,
    };

    final result = await _authService.register(userData);
    if (mounted) setState(() => _isLoading = false);

    if (result['success']) {
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => OtpVerificationScreen(email: _emailController.text.trim())));
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message']), backgroundColor: Colors.red));
    }
  }

  Widget _buildCustomInput({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required bool isDark,
    bool isPassword = false,
    bool isConfirm = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.08), shape: BoxShape.circle),
          child: Icon(icon, color: AppTheme.primaryColor, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
              TextField(
                controller: controller,
                obscureText: isPassword ? (isConfirm ? _obscureConfirmPassword : _obscurePassword) : false,
                style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5)),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryColor, width: 2)),
                  suffixIconConstraints: const BoxConstraints(maxHeight: 32, maxWidth: 32),
                  suffixIcon: isPassword 
                    ? IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          (isConfirm ? _obscureConfirmPassword : _obscurePassword) ? Icons.visibility_off : Icons.visibility, 
                          color: Colors.grey.shade400, size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            if (isConfirm) _obscureConfirmPassword = !_obscureConfirmPassword;
                            else _obscurePassword = !_obscurePassword;
                          });
                        },
                      ) 
                    : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustomDropdown({
    required IconData icon,
    required String label,
    required String? value,
    required List<Map<String, String>> items,
    required Function(String?) onChanged,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.08), shape: BoxShape.circle),
          child: Icon(icon, color: AppTheme.primaryColor, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
              DropdownButtonFormField<String>(
                value: value,
                isExpanded: true,
                menuMaxHeight: 250, // FIX: Forces the menu to scroll if it gets too long
                dropdownColor: isDark ? AppTheme.darkSurfaceColor : Colors.white,
                style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.w500),
                icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade400),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5)),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryColor, width: 2)),
                ),
                items: items.map((item) {
                  return DropdownMenuItem<String>(
                    value: item['id'],
                    child: Text(item['name']!),
                  );
                }).toList(),
                onChanged: onChanged,
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
    
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackgroundColor : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black, size: 20),
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
        ),
      ),
      body: SafeArea(
        child: _isLoading 
        ? const Center(child: KaidaLoader()) 
        : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Create Account', textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                const SizedBox(height: 8),
                Text('Sign up to start learning with Kaida Learn', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
                const SizedBox(height: 40),
                
                _buildCustomInput(icon: Icons.person_rounded, label: 'Full Name', controller: _fullNameController, isDark: isDark),
                const SizedBox(height: 24),
                
                _buildCustomInput(icon: Icons.alternate_email_rounded, label: 'Username', controller: _usernameController, isDark: isDark),
                const SizedBox(height: 24),
                
                _buildCustomInput(icon: Icons.email_rounded, label: 'Email address', controller: _emailController, isDark: isDark),
                const SizedBox(height: 24),
                
                _buildCustomDropdown(
                  icon: Icons.language_rounded, label: 'Preferred Language', value: _selectedLanguage, items: _languages, isDark: isDark,
                  onChanged: (val) => setState(() => _selectedLanguage = val),
                ),
                const SizedBox(height: 24),
                
                _buildCustomDropdown(
                  icon: Icons.public_rounded, label: 'Country', value: _selectedCountry, items: _countries, isDark: isDark,
                  onChanged: (val) => setState(() => _selectedCountry = val),
                ),
                const SizedBox(height: 24),
                
                _buildCustomDropdown(
                  icon: Icons.map_rounded, label: 'State', value: _selectedState, items: _states, isDark: isDark,
                  onChanged: (val) => setState(() => _selectedState = val),
                ),
                const SizedBox(height: 24),
                
                _buildCustomDropdown(
                  icon: Icons.location_city_rounded, label: 'City', value: _selectedCity, items: _cities, isDark: isDark,
                  onChanged: (val) => setState(() => _selectedCity = val),
                ),
                const SizedBox(height: 24),
                
                _buildCustomInput(icon: Icons.lock_rounded, label: 'Password', controller: _passwordController, isDark: isDark, isPassword: true),
                const SizedBox(height: 24),
                
                _buildCustomInput(icon: Icons.lock_reset_rounded, label: 'Confirm Password', controller: _confirmPasswordController, isDark: isDark, isPassword: true, isConfirm: true),
                const SizedBox(height: 30),
                
                Row(
                  children: [
                    SizedBox(
                      height: 24, width: 24,
                      child: Checkbox(
                        value: _agreeTerms,
                        activeColor: AppTheme.primaryColor,
                        onChanged: (val) => setState(() => _agreeTerms = val ?? false),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text('I agree to the Terms & Conditions', style: TextStyle(fontSize: 14, color: isDark ? Colors.grey.shade300 : Colors.black87))),
                  ],
                ),
                const SizedBox(height: 30),
                
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 0,
                    ),
                    child: const Text('Sign Up', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 40),
                
                Row(
                  children: [
                    Expanded(child: Divider(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200, thickness: 1.5)),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('Or', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600, fontSize: 14))),
                    Expanded(child: Divider(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200, thickness: 1.5)),
                  ],
                ),
                const SizedBox(height: 30),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 54, width: 54,
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200, width: 1.5)),
                      child: IconButton(icon: const FaIcon(FontAwesomeIcons.google, color: Colors.redAccent, size: 20), onPressed: () {}),
                    ),
                    const SizedBox(width: 24),
                    Container(
                      height: 54, width: 54,
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200, width: 1.5)),
                      child: IconButton(icon: const FaIcon(FontAwesomeIcons.facebook, color: Colors.blue, size: 20), onPressed: () {}),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Already have an account?", style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade700, fontWeight: FontWeight.w600, fontSize: 14)),
                    TextButton(
                      onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                      child: const Text('Sign In', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
      ),
    );
  }
}
