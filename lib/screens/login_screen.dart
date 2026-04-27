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

          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black, size: 24),

          onPressed: () => Navigator.pop(context),

        ),

      ),

      body: SafeArea(

        child: _isLoading 

        ? const Center(child: KaidaLoader()) 

        : SingleChildScrollView(

            padding: const EdgeInsets.symmetric(horizontal: 24.0),

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.stretch,

              children: [

                const SizedBox(height: 20),

                Text(

                  'Welcome back', 

                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)

                ),

                const SizedBox(height: 12),

                Text(

                  'Lorem Ipsum is simply dummy text of the\nLorem Ipsum has been the industry's', 

                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.4)

                ),



                const SizedBox(height: 40),



                // Email Row

                Row(

                  children: [

                    Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.email_outlined, color: Colors.blue)),

                    const SizedBox(width: 15),

                    Expanded(

                      child: Column(

                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [

                          Text('Email Address', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),

                          TextField(controller: _emailController, decoration: const InputDecoration(border: UnderlineInputBorder(), contentPadding: EdgeInsets.zero)),

                        ],

                      ),

                    ),

                  ],

                ),



                const SizedBox(height: 20),



                // Password Row

                Row(

                  children: [

                    Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.lock_outline, color: Colors.blue)),

                    const SizedBox(width: 15),

                    Expanded(

                      child: Column(

                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [

                          Text('Password', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),

                          TextField(

                            controller: _passwordController,

                            obscureText: _obscurePassword,

                            decoration: InputDecoration(

                              border: const UnderlineInputBorder(),

                              contentPadding: EdgeInsets.zero,

                              suffixIcon: IconButton(

                                icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),

                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),

                              ),

                            ),

                          ),

                        ],

                      ),

                    ),

                  ],

                ),



                const SizedBox(height: 15),

                Align(

                  alignment: Alignment.centerRight,

                  child: TextButton(

                    onPressed: () {}, 

                    child: const Text('Forgot Password', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))

                  ),

                ),



                const SizedBox(height: 30),



                SizedBox(

                  height: 55,

                  child: ElevatedButton(

                    onPressed: _handleLogin,

                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),

                    child: const Text('Sign in', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),

                  ),

                ),



                const SizedBox(height: 30),

                Center(child: Text('or', style: TextStyle(color: Colors.grey.shade500))),

                const SizedBox(height: 30),



                Row(

                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [

                    Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300)), child: const FaIcon(FontAwesomeIcons.facebookF, color: Colors.blue)),

                    const SizedBox(width: 20),

                    Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300)), child: const FaIcon(FontAwesomeIcons.google, color: Colors.red)),

                  ],

                ),



                const SizedBox(height: 40),

                Row(

                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [

                    Text("Don't have an account? ", style: TextStyle(color: Colors.grey.shade700)),

                    GestureDetector(

                      onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),

                      child: const Text('Sign up', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),

                    ),

                  ],

                ),

              ],

            ),

          ),

      ),

    );

  }

} 
