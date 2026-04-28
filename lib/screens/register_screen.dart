import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../config/api_config.dart';
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
  
  // Dynamic API Data
  List<dynamic> _countries = [];
  List<dynamic> _states = [];
  List<dynamic> _cities = [];

  String? _selectedCountryId;
  String? _selectedCountryName;

  String? _selectedStateId;
  String? _selectedStateName;

  String? _selectedCityId;
  String? _selectedCityName;

  bool _agreeTerms = false;
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final List<Map<String, String>> _languages = [{'id': 'en', 'name': 'English'}, {'id': 'ha', 'name': 'Hausa'}];

  @override
  void initState() {
    super.initState();
    _fetchCountries();
  }

  // --- API FETCH METHODS ---
  Future<void> _fetchCountries() async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.locations}?action=countries'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && mounted) {
          setState(() => _countries = data['data']);
        }
      }
    } catch (e) {
      debugPrint("Countries fetch error: $e");
    }
  }

  Future<void> _fetchStates(String countryId) async {
    setState(() {
      _states = []; _cities = [];
      _selectedStateId = null; _selectedStateName = null;
      _selectedCityId = null; _selectedCityName = null;
    });
    try {
      final response = await http.get(Uri.parse('${ApiConfig.locations}?action=states&country_id=$countryId'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && mounted) {
          setState(() => _states = data['data']);
        }
      }
    } catch (e) {
      debugPrint("States fetch error: $e");
    }
  }

  Future<void> _fetchCities(String stateId) async {
    setState(() {
      _cities = [];
      _selectedCityId = null; _selectedCityName = null;
    });
    try {
      final response = await http.get(Uri.parse('${ApiConfig.locations}?action=cities&state_id=$stateId'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && mounted) {
          setState(() => _cities = data['data']);
        }
      }
    } catch (e) {
      debugPrint("Cities fetch error: $e");
    }
  }

  void _handleRegister() async {
    FocusScope.of(context).unfocus();
    
    if (_fullNameController.text.isEmpty || _usernameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields')));
      return;
    }
    if (_selectedCountryId == null || _selectedStateId == null || _selectedCityId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please complete your location selection')));
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
      'country_id': _selectedCountryId ?? '',
      'state_id': _selectedStateId ?? '',
      'city_id': _selectedCityId ?? '',
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

  // --- NATIVE BOTTOM SHEET PICKER ---
  void _openSelectionSheet({required String title, required List<dynamic> items, required Function(String id, String name) onSelect}) {
    if (items.isEmpty) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.darkBackgroundColor : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Select $title', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                ),
                Divider(height: 1, color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    physics: const BouncingScrollPhysics(),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                        title: Text(item['name'], style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16)),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                        onTap: () {
                          onSelect(item['id'].toString(), item['name'].toString());
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildBottomSheetDropdown({
    required IconData icon,
    required String label,
    required String? valueName,
    required VoidCallback onTap,
    required bool isDark,
    bool disabled = false,
  }) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(disabled ? 0.03 : 0.08), shape: BoxShape.circle),
            child: Icon(icon, color: disabled ? Colors.grey : AppTheme.primaryColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 1.5))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        valueName ?? 'Select',
                        style: TextStyle(color: valueName == null || disabled ? Colors.grey : (isDark ? Colors.white : Colors.black), fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade400, size: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
                        icon: Icon((isConfirm ? _obscureConfirmPassword : _obscurePassword) ? Icons.visibility_off : Icons.visibility, color: Colors.grey.shade400, size: 20),
                        onPressed: () => setState(() { if (isConfirm) _obscureConfirmPassword = !_obscureConfirmPassword; else _obscurePassword = !_obscurePassword; }),
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
                
                _buildBottomSheetDropdown(
                  icon: Icons.language_rounded, label: 'Preferred Language', valueName: _selectedLanguage == 'ha' ? 'Hausa' : 'English', isDark: isDark,
                  onTap: () => _openSelectionSheet(title: 'Language', items: _languages, onSelect: (id, name) => setState(() => _selectedLanguage = id)),
                ),
                const SizedBox(height: 24),
                
                _buildBottomSheetDropdown(
                  icon: Icons.public_rounded, label: 'Country', valueName: _selectedCountryName, isDark: isDark,
                  disabled: _countries.isEmpty,
                  onTap: () => _openSelectionSheet(title: 'Country', items: _countries, onSelect: (id, name) {
                    setState(() { _selectedCountryId = id; _selectedCountryName = name; });
                    _fetchStates(id);
                  }),
                ),
                const SizedBox(height: 24),
                
                _buildBottomSheetDropdown(
                  icon: Icons.map_rounded, label: 'State', valueName: _selectedStateName, isDark: isDark,
                  disabled: _states.isEmpty,
                  onTap: () => _openSelectionSheet(title: 'State', items: _states, onSelect: (id, name) {
                    setState(() { _selectedStateId = id; _selectedStateName = name; });
                    _fetchCities(id);
                  }),
                ),
                const SizedBox(height: 24),
                
                _buildBottomSheetDropdown(
                  icon: Icons.location_city_rounded, label: 'City', valueName: _selectedCityName, isDark: isDark,
                  disabled: _cities.isEmpty,
                  onTap: () => _openSelectionSheet(title: 'City', items: _cities, onSelect: (id, name) => setState(() { _selectedCityId = id; _selectedCityName = name; })),
                ),
                const SizedBox(height: 24),
                
                _buildCustomInput(icon: Icons.lock_rounded, label: 'Password', controller: _passwordController, isDark: isDark, isPassword: true),
                const SizedBox(height: 24),
                
                _buildCustomInput(icon: Icons.lock_reset_rounded, label: 'Confirm Password', controller: _confirmPasswordController, isDark: isDark, isPassword: true, isConfirm: true),
                const SizedBox(height: 30),
                
                Row(
                  children: [
                    SizedBox(height: 24, width: 24, child: Checkbox(value: _agreeTerms, activeColor: AppTheme.primaryColor, onChanged: (val) => setState(() => _agreeTerms = val ?? false))),
                    const SizedBox(width: 12),
                    Expanded(child: Text('I agree to the Terms & Conditions', style: TextStyle(fontSize: 14, color: isDark ? Colors.grey.shade300 : Colors.black87))),
                  ],
                ),
                const SizedBox(height: 30),
                
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _handleRegister,
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), elevation: 0),
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
                    Container(height: 54, width: 54, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200, width: 1.5)), child: IconButton(icon: const FaIcon(FontAwesomeIcons.google, color: Colors.redAccent, size: 20), onPressed: () {})),
                    const SizedBox(width: 24),
                    Container(height: 54, width: 54, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200, width: 1.5)), child: IconButton(icon: const FaIcon(FontAwesomeIcons.facebook, color: Colors.blue, size: 20), onPressed: () {})),
                  ],
                ),
                const SizedBox(height: 40),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Already have an account?", style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade700, fontWeight: FontWeight.w600, fontSize: 14)),
                    TextButton(onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())), child: const Text('Sign In', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 15))),
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
