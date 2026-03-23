import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../config/app_theme.dart';
import '../services/auth_service.dart';
import 'main_layout.dart';

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
    FocusScope.of(context).unfocus(); // Dismiss keyboard
    setState(() => _isLoading = true);
    
    final result = await _authService.login(
      _emailController.text.trim(),
      _passwordController.text,
    );
    
    if (mounted) setState(() => _isLoading = false);

    if (result['success']) {
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainLayout()));
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openWebFlow(String title, String url) {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => AuthWebViewScreen(title: title, url: url)
    ));
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic Theme Detectors to prevent blinding white flashes in dark mode
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppTheme.secondaryColor;
    final subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final cardColor = isDark ? AppTheme.darkSurfaceColor : Colors.white;
    final inputFillColor = isDark ? Colors.grey.shade800 : AppTheme.backgroundColor;

    return Scaffold(
      // Let Scaffold handle the background color dynamically based on the theme
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // LOGO & GREETING
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(isDark ? 0.2 : 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.school, size: 70, color: AppTheme.primaryColor),
                ),
                const SizedBox(height: 24),
                Text('Welcome Back', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 8),
                Text('Sign in to continue your learning journey', style: TextStyle(fontSize: 14, color: subTextColor)),
                const SizedBox(height: 40),

                // LOGIN CARD
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: isDark ? Colors.black54 : Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: Column(
                    children: [
                      // EMAIL FIELD
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          labelStyle: TextStyle(color: Colors.grey.shade500),
                          prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.primaryColor),
                          filled: true,
                          fillColor: inputFillColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16), 
                            borderSide: isDark ? BorderSide(color: Colors.grey.shade700) : BorderSide.none
                          ),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // PASSWORD FIELD WITH TOGGLE
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: TextStyle(color: Colors.grey.shade500),
                          prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primaryColor),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey.shade500),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          filled: true,
                          fillColor: inputFillColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16), 
                            borderSide: isDark ? BorderSide(color: Colors.grey.shade700) : BorderSide.none
                          ),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2)),
                        ),
                      ),
                      
                      // FORGOT PASSWORD
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => _openWebFlow('Reset Password', 'https://academy.kainuwa.africa/forgot_password.php'),
                          child: const Text('Forgot Password?', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // LOGIN BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          onPressed: _isLoading ? null : _handleLogin,
                          child: _isLoading
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                              : const Text('SIGN IN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2)),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // SIGN UP LINK
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account? ", style: TextStyle(color: subTextColor, fontSize: 15)),
                    GestureDetector(
                      onTap: () => _openWebFlow('Create Account', 'https://academy.kainuwa.africa/register.php'),
                      child: const Text('Sign Up', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Pre-Login WebView for Registration, Verification, and Password Reset
class AuthWebViewScreen extends StatefulWidget {
  final String title;
  final String url;
  const AuthWebViewScreen({Key? key, required this.title, required this.url}) : super(key: key);

  @override
  _AuthWebViewScreenState createState() => _AuthWebViewScreenState();
}

class _AuthWebViewScreenState extends State<AuthWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppTheme.backgroundColor)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) { if (mounted) setState(() => _isLoading = true); },
          onPageFinished: (String url) { if (mounted) setState(() => _isLoading = false); },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  Future<bool> _goBack() async {
    if (await _controller.canGoBack()) {
      _controller.goBack();
      return Future.value(false);
    }
    return Future.value(true);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _goBack,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title, style: const TextStyle(fontSize: 16, color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading) const Center(child: KaidaLoader()),
          ],
        ),
      ),
    );
  }
}
