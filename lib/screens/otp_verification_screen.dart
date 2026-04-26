import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_theme.dart';
import '../services/auth_service.dart';
import '../widgets/kaida_loader.dart';
import 'login_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  const OtpVerificationScreen({Key? key, required this.email}) : super(key: key);

  @override
  _OtpVerificationScreenState createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> with WidgetsBindingObserver {
  final _otpController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkClipboardForOTP();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _otpController.dispose();
    super.dispose();
  }

  // Detects when user returns to app from email client
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkClipboardForOTP();
    }
  }

  // Auto-Detects 6-digit codes in clipboard
  void _checkClipboardForOTP() async {
    ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null) {
      String text = data.text!.trim();
      if (RegExp(r'^\d{6}$').hasMatch(text)) {
        if (_otpController.text != text) {
          setState(() {
            _otpController.text = text;
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP Auto-Detected!'), backgroundColor: Colors.green));
          // Optional: Auto submit here
        }
      }
    }
  }

  void _verifyOTP() async {
    FocusScope.of(context).unfocus();
    if (_otpController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid 6-digit OTP')));
      return;
    }
    
    setState(() => _isLoading = true);
    final result = await _authService.verifyOtp(widget.email, _otpController.text.trim());
    if (mounted) setState(() => _isLoading = false);

    if (result['success']) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account Verified! Please log in.'), backgroundColor: Colors.green));
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
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
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black)),
      body: SafeArea(
        child: _isLoading 
        ? const Center(child: KaidaLoader()) 
        : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.mark_email_read_rounded, size: 80, color: AppTheme.primaryColor),
                const SizedBox(height: 30),
                Text('Check Your Email', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                const SizedBox(height: 12),
                Text('We sent a 6-digit verification code to:\n${widget.email}', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey.shade600, height: 1.5)),
                const SizedBox(height: 40),
                
                // Sleek Auto-Detecting OTP Field
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 32, letterSpacing: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                  autofillHints: const [AutofillHints.oneTimeCode],
                  decoration: InputDecoration(
                    counterText: "",
                    hintText: "••••••",
                    hintStyle: TextStyle(color: Colors.grey.shade400, letterSpacing: 24),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2)),
                  ),
                  onChanged: (val) {
                    if (val.length == 6) _verifyOTP();
                  },
                ),
                const SizedBox(height: 40),
                
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _verifyOTP,
                    child: const Text('Verify Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
      ),
    );
  }
}
