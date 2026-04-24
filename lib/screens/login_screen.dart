import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../config/app_theme.dart';
import '../services/auth_service.dart';
import '../widgets/kaida_loader.dart';
import 'main_layout.dart';
import 'dart:ui' as ui;

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
    final size = MediaQuery.of(context).size;
    
    // Aesthetic Colors Based on Theme
    final textColor = isDark ? Colors.white : AppTheme.secondaryColor;
    final subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final cardColor = isDark ? AppTheme.darkSurfaceColor : Colors.white;
    final inputFillColor = isDark ? Colors.grey.shade900 : Colors.grey.shade50;
    final inputBorderColor = isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200;

    return Scaffold(
      backgroundColor: cardColor,
      body: Stack(
        children: [
          // 1. Modern Gradient Header with Curve
          CustomPaint(
            size: Size(size.width, 320),
            painter: ModernCurvePainter(),
          ),
          
          // 2. Header Content (Logo/Text)
          SafeArea(
            child: Container(
              width: double.infinity,
              height: 200,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Refined School Icon Logo
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.2), width: 1)
                    ),
                    child: const Icon(Icons.school, size: 40, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Kainuwa Academy',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Kaida Learn - The Future of Learning',
                    style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
          
          // 3. Main Form Section (Scrollable)
          Positioned.fill(
            top: 250, // Starts below the curve peak
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Welcome Back!',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.primaryColor),
                  ),
                  const SizedBox(height: 28),
                  
                  // Polished Email Input
                  _buildInputLabel("Email Address", subTextColor),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: "example@email.com",
                      hintStyle: TextStyle(color: subTextColor.withOpacity(0.5), fontSize: 14),
                      prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.primaryColor, size: 20),
                      filled: true,
                      fillColor: inputFillColor,
                      contentPadding: const EdgeInsets.symmetric(vertical: 18),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: inputBorderColor)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2)),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Polished Password Input
                  _buildInputLabel("Password", subTextColor),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: "••••••••",
                      hintStyle: TextStyle(color: subTextColor.withOpacity(0.5), fontSize: 14),
                      prefixIcon: const Icon(Icons.lock_clock_outlined, color: AppTheme.primaryColor, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: subTextColor.withOpacity(0.5), size: 20),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        splashRadius: 20,
                      ),
                      filled: true,
                      fillColor: inputFillColor,
                      contentPadding: const EdgeInsets.symmetric(vertical: 18),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: inputBorderColor)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2)),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Refined Forgot Password Link
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => _openWebFlow('Reset Password', 'https://academy.kainuwa.africa/forgot_password.php'),
                      style: TextButton.styleFrom(foregroundColor: AppTheme.primaryColor, padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                      child: const Text('Forgot Password?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Premium Modern Login Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 8,
                      shadowColor: AppTheme.primaryColor.withOpacity(0.5),
                    ),
                    onPressed: _isLoading ? null : _handleLogin,
                    child: _isLoading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                        : const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.2)),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Social Login Section (Matches Screenshot Aesthetic)
                  _buildSocialLoginSection(subTextColor, inputBorderColor, cardColor),
                  
                  const SizedBox(height: 40),
                  
                  // Refined Sign Up Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("New learner? ", style: TextStyle(color: subTextColor, fontSize: 14, fontWeight: FontWeight.w500)),
                      GestureDetector(
                        onTap: () => _openWebFlow('Create Account', 'https://academy.kainuwa.africa/register.php'),
                        child: const Text('Create Account', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w800, fontSize: 14)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(label, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildSocialLoginSection(Color textColor, Color borderColor, Color cardColor) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: borderColor)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text("or login with", style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w600)),
            ),
            Expanded(child: Divider(color: borderColor)),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSocialCard("assets/images/google_logo.png", borderColor, cardColor), // Note: Assets required or replace with icons
            const SizedBox(width: 16),
            _buildSocialCard("assets/images/facebook_logo.png", borderColor, cardColor), // Note: Assets required or replace with icons
          ],
        ),
      ],
    );
  }

  Widget _buildSocialCard(String assetPath, Color borderColor, Color cardColor) {
    // Note: If you don't have these assets yet, I've added error handling to show a generic icon.
    return Container(
      width: 80,
      height: 56,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(color: AppTheme.primaryColor.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))
        ]
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onPressed: () {}, // Not implemented yet
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Image.asset(
              assetPath, 
              height: 24, 
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.language, size: 24, color: AppTheme.primaryColor),
            ),
          ),
        ),
      ),
    );
  }
}

// --- Custom Painter for the Modern Curved Header ---
class ModernCurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint();
    
    // Kainuwa Purple Gradient
    paint.shader = ui.Gradient.linear(
      Offset(0, size.height * 0.2), // Gradient start
      Offset(size.width, size.height), // Gradient end
      [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.85)],
      [0.0, 1.0]
    );
    paint.style = PaintingStyle.fill;

    // Drawing the modern, pronounced concave curve from the screenshot
    Path path = Path();
    path.lineTo(0, size.height * 0.7); // Adjust for curve sharpness
    
    // First Control Point and End Point for the wave
    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2, size.height * 0.85); // Highest part of concave
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy, firstEndPoint.dx, firstEndPoint.dy);
    
    // Second Control Point and End Point for the wave
    var secondControlPoint = Offset(size.width - (size.width / 4), size.height * 0.7);
    var secondEndPoint = Offset(size.width, size.height * 0.9);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy, secondEndPoint.dx, secondEndPoint.dy);

    path.lineTo(size.width, 0); // Complete to top right
    path.close(); // Close path back to (0,0)

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

// --- Web View Screen for External Links (Unchanged visually for stability) ---
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
