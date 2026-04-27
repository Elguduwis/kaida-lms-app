import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../config/app_theme.dart';
import '../services/auth_service.dart';
import '../widgets/kaida_loader.dart';
import 'main_layout.dart';
import 'register_screen.dart';
import 'onboarding_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  void _handleLogin() async {
    FocusScope.of(context).unfocus();
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }
    
    setState(() => _isLoading = true);
    final result = await _authService.login(_emailController.text.trim(), _passwordController.text);
    if (mounted) setState(() => _isLoading = false);

    if (result['success']) {
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainLayout()));
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message']), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      // Exactly Pure White in light mode
      backgroundColor: isDark ? AppTheme.darkBackgroundColor : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black, size: 20),
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OnboardingScreen())),
        ),
      ),
      body: SafeArea(
        child: _isLoading 
        ? const Center(child: KaidaLoader()) 
        : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch, // Helps center the text and stretch the buttons
              children: [
                const SizedBox(height: 10),
                
                // Centered, smaller headers with NO emoji
                Text(
                  'Welcome Back', 
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to continue to Kaida Learn', 
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600)
                ),
                
                const SizedBox(height: 50),
                
                // Email Label
                Text('Email address', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
                // Email Field (Underline ONLY, no fill)
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.primaryColor),
                    filled: false, // NO background fill
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
                    focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryColor, width: 2)),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Password Label
                Text('Password', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
                // Password Field (Underline ONLY, no fill)
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primaryColor),
                    filled: false, // NO background fill
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
                    focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryColor, width: 2)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, 
                        color: Colors.grey.shade500 
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {}, 
                    child: const Text('Forgot Password?', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 13))
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Sign In Button (Welled Curved / Stadium Style)
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), // Perfect curve
                      elevation: 0,
                    ),
                    child: const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Divider ("Or")
                Row(
                  children: [
                    Expanded(child: Divider(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300, thickness: 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Or', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600, fontSize: 14)),
                    ),
                    Expanded(child: Divider(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300, thickness: 1)),
                  ],
                ),
                
                const SizedBox(height: 30),
                
                // Pure Icon Social Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                      ),
                      child: IconButton(
                        icon: const FaIcon(FontAwesomeIcons.google, color: Colors.redAccent, size: 20),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Google Sign-In coming soon!')));
                        },
                      ),
                    ),
                    const SizedBox(width: 24),
                    Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                      ),
                      child: IconButton(
                        icon: const FaIcon(FontAwesomeIcons.facebook, color: Colors.blue, size: 20),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Facebook Sign-In coming soon!')));
                        },
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 40),
                
                // Sign Up text
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account?", style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade700, fontWeight: FontWeight.w600, fontSize: 14)),
                    TextButton(
                      onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                      child: const Text('Sign Up', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 15)),
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
