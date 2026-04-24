import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../config/app_theme.dart';
import '../services/auth_service.dart';
import '../widgets/kaida_loader.dart';
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    FocusScope.of(context).unfocus();
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar("Please fill all fields", Colors.orange.shade800);
      return;
    }
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
      _showSnackBar(result['message'], Colors.red.shade600);
    }
  }

  void _showSnackBar(String message, Color bgColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  void _openWebFlow(String title, String url) {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => AuthWebViewScreen(title: title, url: url)
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Minimalist Colors
    final bgColor = isDark ? AppTheme.darkBackgroundColor : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.grey.shade500 : Colors.grey.shade400;
    final inputBorderColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
    final inputFillColor = isDark ? AppTheme.darkSurfaceColor : Colors.white;
    final socialBtnColor = isDark ? Colors.grey.shade800 : const Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                // 1. Minimalist Title
                Text(
                  'Login',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 40),

                // 2. Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: textColor, fontWeight: FontWeight.w500, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: "Email",
                    hintStyle: TextStyle(color: hintColor, fontSize: 15),
                    prefixIcon: Icon(Icons.mail_outline_rounded, color: hintColor, size: 22),
                    filled: true,
                    fillColor: inputFillColor,
                    contentPadding: const EdgeInsets.symmetric(vertical: 20),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30), 
                      borderSide: BorderSide(color: inputBorderColor, width: 1.5)
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30), 
                      borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2)
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(color: textColor, fontWeight: FontWeight.w500, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: "Password",
                    hintStyle: TextStyle(color: hintColor, fontSize: 15),
                    prefixIcon: Icon(Icons.lock_outline_rounded, color: hintColor, size: 22),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, 
                        color: hintColor, 
                        size: 20
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      splashRadius: 20,
                    ),
                    filled: true,
                    fillColor: inputFillColor,
                    contentPadding: const EdgeInsets.symmetric(vertical: 20),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30), 
                      borderSide: BorderSide(color: inputBorderColor, width: 1.5)
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30), 
                      borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2)
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 4. Centered Forgot Password
                Center(
                  child: TextButton(
                    onPressed: () => _openWebFlow('Reset Password', 'https://academy.kainuwa.africa/forgot_password.php'),
                    style: TextButton.styleFrom(
                      foregroundColor: subTextColor(isDark),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                        fontWeight: FontWeight.w600, 
                        fontSize: 13, 
                        decoration: TextDecoration.underline,
                        decorationColor: subTextColor(isDark),
                        color: subTextColor(isDark)
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 5. Primary Login Button (Stadium shape)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 0,
                  ),
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                      : const Text('Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 32),

                // 6. Divider "or"
                Row(
                  children: [
                    Expanded(child: Divider(color: inputBorderColor)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text("or", style: TextStyle(color: hintColor, fontSize: 13, fontWeight: FontWeight.w500)),
                    ),
                    Expanded(child: Divider(color: inputBorderColor)),
                  ],
                ),
                const SizedBox(height: 32),

                // 7. Continue with Google
                _buildAlternativeLoginBtn(
                  icon: const FaIcon(FontAwesomeIcons.google, color: Colors.blue, size: 20),
                  text: "Continue with Google",
                  bgColor: socialBtnColor,
                  textColor: textColor,
                  onTap: () {
                    _showSnackBar("Google Login coming soon!", AppTheme.primaryColor);
                  }
                ),
                const SizedBox(height: 16),

                // 8. Continue with Apple (Uses primary color like the reference image's green)
                _buildAlternativeLoginBtn(
                  icon: const FaIcon(FontAwesomeIcons.apple, color: Colors.white, size: 22),
                  text: "Continue with Apple",
                  bgColor: AppTheme.primaryColor.withOpacity(0.9), // Using Kainuwa color for emphasis
                  textColor: Colors.white,
                  onTap: () {
                    _showSnackBar("Apple Login coming soon!", AppTheme.primaryColor);
                  }
                ),
                const SizedBox(height: 16),

                // 9. Continue As Guest
                _buildAlternativeLoginBtn(
                  icon: Icon(Icons.person_outline_rounded, color: textColor, size: 22),
                  text: "Continue As Guest",
                  bgColor: socialBtnColor,
                  textColor: textColor,
                  onTap: () {
                     Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainLayout()));
                  }
                ),
                const SizedBox(height: 40),

                // 10. Bottom Sign Up Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Need an account? ", style: TextStyle(color: subTextColor(isDark), fontSize: 14, fontWeight: FontWeight.w500)),
                    GestureDetector(
                      onTap: () => _openWebFlow('Create Account', 'https://academy.kainuwa.africa/register.php'),
                      child: Text('Sign up', style: TextStyle(color: textColor, fontWeight: FontWeight.w800, fontSize: 14)),
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

  Color subTextColor(bool isDark) => isDark ? Colors.grey.shade400 : Colors.grey.shade700;

  Widget _buildAlternativeLoginBtn({
    required Widget icon, 
    required String text, 
    required Color bgColor, 
    required Color textColor,
    required VoidCallback onTap
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      onPressed: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(width: 12),
          Text(text, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textColor)),
        ],
      ),
    );
  }
}

// --- Web View Screen for External Links ---
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
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: AppTheme.primaryColor,
          elevation: 0,
          title: Text(widget.title, style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
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
