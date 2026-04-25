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
    final bgColor = isDark ? AppTheme.darkSurfaceColor : Colors.white;
    final activeColor = AppTheme.primaryColor;
    final inactiveColor = isDark ? Colors.grey.shade500 : Colors.grey.shade600;

    return Scaffold(
      // extendBody ensures the screens flow smoothly behind the transparent notch
      extendBody: true, 
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      
      // 1. THE CENTER FLOATING BUTTON (Shop Products)
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SizedBox(
        height: 64,
        width: 64,
        child: FloatingActionButton(
          backgroundColor: Colors.transparent,
          elevation: _currentIndex == 2 ? 8 : 4,
          shape: const CircleBorder(),
          onPressed: () => setState(() => _currentIndex = 2),
          child: Container(
            width: 64,
            height: 64,
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
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
              ],
            ),
            child: const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 28),
          ),
        ),
      ),
      
      // 2. THE NOTCHED BOTTOM BAR
      bottomNavigationBar: BottomAppBar(
        color: bgColor,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        elevation: 20,
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: 65,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left Group
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(icon: Icons.home_rounded, label: 'Home', index: 0, activeColor: activeColor, inactiveColor: inactiveColor),
                    _buildNavItem(icon: Icons.school_rounded, label: 'Courses', index: 1, activeColor: activeColor, inactiveColor: inactiveColor),
                  ],
                ),
              ),
              
              // Spacing for the Floating Button Notch
              const SizedBox(width: 48), 
              
              // Right Group
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
              size: isSelected ? 26 : 24,
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
