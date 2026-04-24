import '../widgets/kaida_loader.dart';
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
    FocusScope.of(context).unfocus();
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
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppTheme.secondaryColor;
    final subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final cardColor = isDark ? AppTheme.darkSurfaceColor : Colors.white;
    final inputFillColor = isDark ? Colors.grey.shade900 : Colors.grey.shade50;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // HEADER SECTION
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryColor.withOpacity(0.2),
                              AppTheme.primaryColor.withOpacity(0.05)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.auto_awesome, size: 50, color: AppTheme.primaryColor),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Welcome Back', 
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: textColor, letterSpacing: -0.5),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in to continue your learning journey', 
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, color: subTextColor, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),

                  // LOGIN CARD
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: isDark ? Colors.black.withOpacity(0.4) : AppTheme.primaryColor.withOpacity(0.08), 
                          blurRadius: 30, 
                          offset: const Offset(0, 15)
                        )
                      ],
                      border: Border.all(
                        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                        width: 1.5
                      )
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // EMAIL FIELD
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            labelText: 'Email Address',
                            labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                            floatingLabelStyle: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                            prefixIcon: const Icon(Icons.alternate_email_rounded, color: AppTheme.primaryColor, size: 22),
                            filled: true,
                            fillColor: inputFillColor,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20), 
                              borderSide: BorderSide.none
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20), 
                              borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2)
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // PASSWORD FIELD
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                            floatingLabelStyle: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                            prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.primaryColor, size: 22),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.grey.shade400, size: 22),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              splashRadius: 24,
                            ),
                            filled: true,
                            fillColor: inputFillColor,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20), 
                              borderSide: BorderSide.none
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20), 
                              borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2)
                            ),
                          ),
                        ),
                        
                        // FORGOT PASSWORD
                        Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8.0, bottom: 24.0),
                            child: TextButton(
                              onPressed: () => _openWebFlow('Reset Password', 'https://academy.kainuwa.africa/forgot_password.php'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.primaryColor,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text('Forgot Password?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                            ),
                          ),
                        ),

                        // LOGIN BUTTON
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            elevation: 4,
                            shadowColor: AppTheme.primaryColor.withOpacity(0.4),
                          ),
                          onPressed: _isLoading ? null : _handleLogin,
                          child: _isLoading
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                              : const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // SIGN UP LINK
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account? ", style: TextStyle(color: subTextColor, fontSize: 15, fontWeight: FontWeight.w500)),
                      GestureDetector(
                        onTap: () => _openWebFlow('Create Account', 'https://academy.kainuwa.africa/register.php'),
                        child: const Text('Sign Up', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w800, fontSize: 15)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
          title: Text(widget.title, style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
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
