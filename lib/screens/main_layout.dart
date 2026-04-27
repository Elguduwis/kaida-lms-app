import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'home_screen.dart';
import 'catalog_screen.dart';
import 'ai_chat_screen.dart'; // YOUR actual AI screen
import 'my_courses_screen.dart'; // The Learn screen
import 'profile_screen.dart';

class MainLayout extends StatefulWidget {
  final int initialIndex;
  const MainLayout({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  _MainLayoutState createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  late int _currentIndex;

  // The 5 Screens mapped exactly to your layout
  final List<Widget> _screens = [
    const HomeScreen(),
    const CatalogScreen(actionType: 'courses', title: 'All Courses'),
    const AiChatScreen(), // Assuming the class name inside your file is AiChatScreen
    const MyCoursesScreen(), 
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black26 : Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            )
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: isDark ? AppTheme.darkSurfaceColor : Colors.white,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: Colors.grey.shade400,
          type: BottomNavigationBarType.fixed, 
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 10),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.home_rounded)),
              activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.home_rounded, size: 26)),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.menu_book_rounded)),
              activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.menu_book_rounded, size: 26)),
              label: 'Courses',
            ),
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.auto_awesome_rounded)),
              activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.auto_awesome_rounded, size: 26)),
              label: 'AI',
            ),
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.play_circle_fill_rounded)),
              activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.play_circle_fill_rounded, size: 26)),
              label: 'Learn',
            ),
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.person_rounded)),
              activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.person_rounded, size: 26)),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
