import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'home_screen.dart';
import 'dashboard_screen.dart';
import 'catalog_screen.dart';
import 'profile_screen.dart';
import 'ai_chat_screen.dart';

class MainLayout extends StatefulWidget {
  final int initialIndex; 
  const MainLayout({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  _MainLayoutState createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex; 
  }

  // Restored YOUR exact screen list, just removing Shop and Downloads
  final List<Widget> _screens = [
    const HomeScreen(), // 0
    const CatalogScreen(actionType: 'courses', title: 'Explore Courses'), // 1
    const AiChatScreen(), // 2
    const DashboardScreen(), // 3 (This is your Learn screen)
    const ProfileScreen(), // 4
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBgColor = isDark ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor;
    final barColor = isDark ? AppTheme.darkSurfaceColor : Colors.white;
    final activeColor = AppTheme.primaryColor;
    final inactiveColor = isDark ? Colors.grey.shade500 : Colors.grey.shade400;

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      body: Stack(
        children: [
          Positioned.fill(
            bottom: 60, 
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
          
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: barColor,
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // ONLY Home and Courses on the left
                  _buildNavItem(icon: Icons.home_rounded, label: 'Home', index: 0, activeColor: activeColor, inactiveColor: inactiveColor),
                  _buildNavItem(icon: Icons.school_rounded, label: 'Courses', index: 1, activeColor: activeColor, inactiveColor: inactiveColor),
                  
                  const SizedBox(width: 50), // Gap for your floating AI button
                  
                  // ONLY Learn and Profile on the right
                  _buildNavItem(icon: Icons.play_circle_fill_rounded, label: 'Learn', index: 3, activeColor: activeColor, inactiveColor: inactiveColor),
                  _buildNavItem(icon: Icons.person_rounded, label: 'Profile', index: 4, activeColor: activeColor, inactiveColor: inactiveColor),
                ],
              ),
            ),
          ),

          // Your gorgeous floating AI button untouched
          Positioned(
            bottom: 15, 
            left: (MediaQuery.of(context).size.width / 2) - 28, 
            child: GestureDetector(
              onTap: () => setState(() => _currentIndex = 2), // Index updated to 2 for AI Chat
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryColor,
                  boxShadow: [
                    if (_currentIndex == 2)
                      BoxShadow(color: AppTheme.primaryColor.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))
                    else
                      BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))
                  ],
                  border: Border.all(color: barColor, width: 3), 
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                    Text('AI', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, height: 1.1)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required String label, required int index, required Color activeColor, required Color inactiveColor}) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: MediaQuery.of(context).size.width / 5, // Adjusted slightly so the 4 icons space out evenly now
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              transform: Matrix4.translationValues(0, isSelected ? -2 : 0, 0),
              child: Icon(icon, color: isSelected ? activeColor : inactiveColor, size: 22),
            ),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: isSelected ? activeColor : inactiveColor, fontSize: 9, fontWeight: isSelected ? FontWeight.bold : FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)
          ],
        ),
      ),
    );
  }
}
