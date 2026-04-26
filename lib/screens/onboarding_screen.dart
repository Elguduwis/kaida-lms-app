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

  final List<Map<String, String>> _pages = [
    {
      'type': 'welcome',
      'title': 'Kaida Learn',
      'subtitle': '',
    },
    {
      'type': 'image',
      'image': 'https://img.kainuwa.africa/serve?id=dhbARApv4RAD',
      'title': 'Expert-Led Courses',
      'subtitle': 'Learn high-income skills in English and Hausa.',
    },
    {
      'type': 'image',
      'image': 'https://img.kainuwa.africa/serve?id=yLn5ZMeHcbdJ',
      'title': 'Earn Kaida Tokens',
      'subtitle': 'Get rewarded for your progress and achievements.',
    },
    {
      'type': 'image',
      'image': 'https://img.kainuwa.africa/serve?id=YOdo5iOOitUe',
      'title': 'Join the Community',
      'subtitle': 'Connect with fellow learners and grow together.',
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
    
    // Exact Requirement: Screen 1 is Solid Purple, the rest are Pure White (or Dark Mode)
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
                  // Exact Requirement: Solid Purple background with just "Kaida Learn" in white
                  return Center(
                    child: Text(
                      page['title']!,
                      style: const TextStyle(
                        fontSize: 42,
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
                        Image.network(
                          page['image']!,
                          height: 320,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image, size: 100),
                        ),
                        const SizedBox(height: 50),
                        Text(
                          page['title']!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppTheme.textDarkMode : AppTheme.textMainMode,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page['subtitle']!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),

            // 2. TOP RIGHT SKIP BUTTON
            Positioned(
              top: 10,
              right: 20,
              child: _currentPage < _pages.length - 1
                  ? TextButton(
                      onPressed: _completeOnboarding,
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          // White text on purple background, dark text on white background
                          color: _currentPage == 0 
                              ? Colors.white 
                              : (isDark ? Colors.grey.shade300 : Colors.grey.shade800),
                        ),
                      ),
                    )
                  : const SizedBox(),
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

                  // EXACT REQUIREMENT: CIRCULAR PROGRESS ICON BUTTON
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
