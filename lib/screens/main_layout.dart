import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'home_screen.dart';
import 'dashboard_screen.dart';
import 'catalog_screen.dart';
import 'profile_screen.dart';
import 'downloads_screen.dart';
import 'ai_chat_screen.dart';

class MainLayout extends StatefulWidget {
  final int initialIndex; // NEW: Allows other screens to route to specific tabs
  const MainLayout({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  _MainLayoutState createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex; // Set initial tab based on routing
  }

  final List<Widget> _screens = [
    const HomeScreen(),
    const CatalogScreen(actionType: 'courses', title: 'Explore Courses'),
    const CatalogScreen(actionType: 'products', title: 'Shop Products'),
    const AiChatScreen(),
    const DashboardScreen(), 
    const DownloadsScreen(),
    const ProfileScreen(), 
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
                  _buildNavItem(icon: Icons.home_rounded, label: 'Home', index: 0, activeColor: activeColor, inactiveColor: inactiveColor),
                  _buildNavItem(icon: Icons.school_rounded, label: 'Courses', index: 1, activeColor: activeColor, inactiveColor: inactiveColor),
                  _buildNavItem(icon: Icons.shopping_bag_rounded, label: 'Shop', index: 2, activeColor: activeColor, inactiveColor: inactiveColor),
                  
                  const SizedBox(width: 50),
                  
                  _buildNavItem(icon: Icons.play_circle_fill_rounded, label: 'Learn', index: 4, activeColor: activeColor, inactiveColor: inactiveColor),
                  _buildNavItem(icon: Icons.cloud_download_rounded, label: 'Saved', index: 5, activeColor: activeColor, inactiveColor: inactiveColor),
                  _buildNavItem(icon: Icons.person_rounded, label: 'Profile', index: 6, activeColor: activeColor, inactiveColor: inactiveColor),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: 15, 
            left: (MediaQuery.of(context).size.width / 2) - 28, 
            child: GestureDetector(
              onTap: () => setState(() => _currentIndex = 3),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryColor,
                  boxShadow: [
                    if (_currentIndex == 3)
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
        width: MediaQuery.of(context).size.width / 8, 
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
