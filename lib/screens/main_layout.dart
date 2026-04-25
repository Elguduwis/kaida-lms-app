import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'home_screen.dart';
import 'dashboard_screen.dart';
import 'catalog_screen.dart';
import 'profile_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({Key? key}) : super(key: key);

  @override
  _MainLayoutState createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0; 

  final List<Widget> _screens = [
    const HomeScreen(),
    const CatalogScreen(actionType: 'courses', title: 'Explore Courses'),
    const CatalogScreen(actionType: 'products', title: 'Shop Products'),
    const DashboardScreen(), 
    const ProfileScreen(), 
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBgColor = isDark ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor;
    final barColor = isDark ? AppTheme.darkSurfaceColor : Colors.white;
    final activeColor = AppTheme.primaryColor;
    final inactiveColor = isDark ? Colors.grey.shade500 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      // FIXED: Disabling extendBody automatically pads your scrollable content globally 
      // so it never hides behind the BottomAppBar.
      extendBody: false, 
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      
      // 1. THE CENTER FLOATING BUTTON (Scaled down slightly)
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SizedBox(
        height: 56, // Scaled down from 64
        width: 56,
        child: FloatingActionButton(
          backgroundColor: Colors.transparent,
          elevation: _currentIndex == 2 ? 8 : 4,
          shape: const CircleBorder(),
          onPressed: () => setState(() => _currentIndex = 2),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.8),
                  AppTheme.primaryColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                if (_currentIndex == 2)
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
              ],
            ),
            child: const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 24),
          ),
        ),
      ),
      
      // 2. THE NOTCHED BOTTOM BAR (Added shadow outline)
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              // FIXED: Adds a crisp outline shadow to distinguish the bar in dark/light mode
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomAppBar(
          color: barColor,
          surfaceTintColor: barColor,
          shape: const CircularNotchedRectangle(),
          notchMargin: 6.0,
          elevation: 0, // Handled by container shadow above
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: 60, // Scaled down from 65
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(icon: Icons.home_rounded, label: 'Home', index: 0, activeColor: activeColor, inactiveColor: inactiveColor),
                      _buildNavItem(icon: Icons.school_rounded, label: 'Courses', index: 1, activeColor: activeColor, inactiveColor: inactiveColor),
                    ],
                  ),
                ),
                const SizedBox(width: 48), // Notch space
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(icon: Icons.play_circle_fill_rounded, label: 'Learning', index: 3, activeColor: activeColor, inactiveColor: inactiveColor),
                      _buildNavItem(icon: Icons.person_rounded, label: 'Profile', index: 4, activeColor: activeColor, inactiveColor: inactiveColor),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required String label, required int index, required Color activeColor, required Color inactiveColor}) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            transform: Matrix4.translationValues(0, isSelected ? -2 : 0, 0),
            child: Icon(
              icon,
              color: isSelected ? activeColor : inactiveColor,
              size: isSelected ? 24 : 22,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              color: isSelected ? activeColor : inactiveColor,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            ),
            child: Text(label),
          )
        ],
      ),
    );
  }
}
