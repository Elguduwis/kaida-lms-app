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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Text('Welcome Back! 👋', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black, letterSpacing: -0.5)),
                const SizedBox(height: 8),
                Text('Sign in to continue to Kaida Learn', style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                const SizedBox(height: 40),
                
                // Email Field (With Icon)
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    hintText: 'Email address',
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.primaryColor),
                    filled: true,
                    fillColor: isDark ? AppTheme.darkSurfaceColor : Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5)),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Password Field (With Icon & Toggle)
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    hintText: 'Password',
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primaryColor),
                    filled: true,
                    fillColor: isDark ? AppTheme.darkSurfaceColor : Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, 
                        color: AppTheme.primaryColor // Styled with Kaida Purple
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {}, 
                    child: const Text('Forgot Password?', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold))
                  ),
                ),
                const SizedBox(height: 20),
                
                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text('Sign In', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300, thickness: 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Or continue with', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                    ),
                    Expanded(child: Divider(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300, thickness: 1)),
                  ],
                ),
                
                const SizedBox(height: 30),
                
                // Social Buttons (Google & Facebook)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Google Sign-In coming soon!')));
                        },
                        icon: const FaIcon(FontAwesomeIcons.google, color: Colors.redAccent, size: 20),
                        label: Text('Google', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          side: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Facebook Sign-In coming soon!')));
                        },
                        icon: const FaIcon(FontAwesomeIcons.facebook, color: Colors.blue, size: 20),
                        label: Text('Facebook', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          side: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 40),
                
                // Sign Up text
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account?", style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade700, fontWeight: FontWeight.w600, fontSize: 15)),
                    TextButton(
                      onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                      child: const Text('Sign Up', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
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
