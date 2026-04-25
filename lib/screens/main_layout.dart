import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'home_screen.dart';
import 'dashboard_screen.dart';
import 'catalog_screen.dart';
import 'profile_screen.dart';
import 'downloads_screen.dart';
import 'ai_chat_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({Key? key}) : super(key: key);

  @override
  _MainLayoutState createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0; 

  // The 7 active screens mapping to our custom navigation
  final List<Widget> _screens = [
    const HomeScreen(),
    const CatalogScreen(actionType: 'courses', title: 'Explore Courses'),
    const CatalogScreen(actionType: 'products', title: 'Shop Products'),
    const AiChatScreen(), // 3: Center AI Screen
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
      // We use a completely custom Stack to prevent Snackbars from pushing the menu up
      body: Stack(
        children: [
          // 1. Main Content Body
          Positioned.fill(
            bottom: 60, // Leaves exact space for the bottom bar so content isn't hidden
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
          
          // 2. Frozen Custom Bottom Bar Background
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
                  // LEFT SIDE (3 Items)
                  _buildNavItem(icon: Icons.home_rounded, label: 'Home', index: 0, activeColor: activeColor, inactiveColor: inactiveColor),
                  _buildNavItem(icon: Icons.school_rounded, label: 'Courses', index: 1, activeColor: activeColor, inactiveColor: inactiveColor),
                  _buildNavItem(icon: Icons.shopping_bag_rounded, label: 'Shop', index: 2, activeColor: activeColor, inactiveColor: inactiveColor),
                  
                  // CENTER SPACER (For the floating AI button)
                  const SizedBox(width: 50),
                  
                  // RIGHT SIDE (3 Items)
                  _buildNavItem(icon: Icons.play_circle_fill_rounded, label: 'Learn', index: 4, activeColor: activeColor, inactiveColor: inactiveColor),
                  _buildNavItem(icon: Icons.cloud_download_rounded, label: 'Saved', index: 5, activeColor: activeColor, inactiveColor: inactiveColor),
                  _buildNavItem(icon: Icons.person_rounded, label: 'Profile', index: 6, activeColor: activeColor, inactiveColor: inactiveColor),
                ],
              ),
            ),
          ),

          // 3. Center Floating AI Button
          Positioned(
            bottom: 15, // Elevated above the bar
            left: (MediaQuery.of(context).size.width / 2) - 28, // Perfectly centered (56 width / 2)
            child: GestureDetector(
              onTap: () => setState(() => _currentIndex = 3),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor.withOpacity(0.8), AppTheme.primaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    if (_currentIndex == 3)
                      BoxShadow(color: AppTheme.primaryColor.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))
                    else
                      BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))
                  ],
                  border: Border.all(color: barColor, width: 3), // Creates a simulated "notch" outline
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
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
        width: MediaQuery.of(context).size.width / 8, // Ensures they fit evenly
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
                size: 22, // Scaled to fit 7 items
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? activeColor : inactiveColor,
                fontSize: 9, // Scaled to fit 7 items
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          ],
        ),
      ),
    );
  }
}
