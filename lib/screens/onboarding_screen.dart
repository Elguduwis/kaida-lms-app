import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_theme.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Expanded descriptive texts
  final List<Map<String, String>> _pages = [
    {
      'type': 'welcome',
      'title': 'Kaida Learn',
      'subtitle': '',
    },
    {
      'type': 'image',
      'image': 'assets/images/onboarding_1.png',
      'title_black': 'Expert-Led ',
      'title_purple': 'Courses',
      'subtitle': 'Master high-income digital skills tailored for the African context. Access premium, expert-led courses crafted meticulously in both English and professional Hausa to accelerate your tech career.',
    },
    {
      'type': 'image',
      'image': 'assets/images/onboarding_2.png',
      'title_black': 'Earn ',
      'title_purple': 'Kaida Tokens',
      'subtitle': 'Experience education that pays you back. Get rewarded with official KAIDA TOKENS for your progress, complete learning milestones, and unlock exclusive platform benefits as you grow.',
    },
    {
      'type': 'image',
      'image': 'assets/images/onboarding_3.png',
      'title_black': 'Join the ',
      'title_purple': 'Community',
      'subtitle': 'You are never learning alone. Connect with thousands of ambitious youths, share ideas, access premium mentorship, and build your professional network in our interactive digital community.',
    },
  ];

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('first_time_user', false);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    Color bgColor = _currentPage == 0 
        ? AppTheme.primaryColor 
        : (isDark ? AppTheme.darkBackgroundColor : Colors.white);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Stack(
          children: [
            // 1. PAGE CONTENT
            PageView.builder(
              controller: _pageController,
              itemCount: _pages.length,
              onPageChanged: (int page) {
                setState(() {
                  _currentPage = page;
                });
              },
              itemBuilder: (context, index) {
                final page = _pages[index];
                
                if (page['type'] == 'welcome') {
                  return Center(
                    child: Text(
                      page['title']!,
                      style: const TextStyle(
                        fontSize: 48, 
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -1.0,
                      ),
                    ),
                  );
                } else {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ShaderMask(
                          shaderCallback: (Rect bounds) {
                            return LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.white, Colors.white.withOpacity(0.0)],
                              stops: const [0.75, 1.0], 
                            ).createShader(bounds);
                          },
                          blendMode: BlendMode.dstIn,
                          child: Image.asset(
                            page['image']!,
                            height: 330,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.broken_image, size: 100),
                          ),
                        ),
                        const SizedBox(height: 35),
                        
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 28, 
                              fontWeight: FontWeight.w900,
                              fontFamily: 'DMSans',
                              color: isDark ? Colors.white : Colors.black, 
                            ),
                            children: [
                              TextSpan(text: page['title_black']),
                              TextSpan(
                                text: page['title_purple'],
                                style: const TextStyle(color: AppTheme.primaryColor),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        
                        Text(
                          page['subtitle']!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16, 
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.grey.shade300 : Colors.black87, 
                            height: 1.6, 
                          ),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),

            // 2. TOP RIGHT SKIP BUTTON (HIDDEN ON PURPLE SCREEN)
            if (_currentPage > 0 && _currentPage < _pages.length - 1)
              Positioned(
                top: 10,
                right: 20,
                child: TextButton(
                  onPressed: _completeOnboarding,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      fontSize: 17,
                      fontFamily: 'sans-serif', 
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black, 
                    ),
                  ),
                ),
              ),

            // 3. BOTTOM NAVIGATION (Dots + Circular Progress Button)
            Positioned(
              bottom: 40,
              left: 30,
              right: 30,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // DOTS
                  Row(
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == 0
                              ? (_currentPage == index ? Colors.white : Colors.white.withOpacity(0.4))
                              : (_currentPage == index
                                  ? AppTheme.primaryColor
                                  : (isDark ? Colors.grey.shade700 : Colors.grey.shade300)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  // CIRCULAR PROGRESS ICON BUTTON
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 65,
                        height: 65,
                        child: CircularProgressIndicator(
                          value: (_currentPage + 1) / _pages.length,
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              _currentPage == 0 ? Colors.white : AppTheme.primaryColor),
                          backgroundColor: _currentPage == 0
                              ? Colors.white.withOpacity(0.2)
                              : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                        ),
                      ),
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: _currentPage == 0 ? Colors.white : AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            _currentPage == _pages.length - 1 
                                ? Icons.check 
                                : Icons.arrow_forward_ios_rounded,
                            color: _currentPage == 0 ? AppTheme.primaryColor : Colors.white,
                            size: 20,
                          ),
                          onPressed: () {
                            if (_currentPage == _pages.length - 1) {
                              _completeOnboarding();
                            } else {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
