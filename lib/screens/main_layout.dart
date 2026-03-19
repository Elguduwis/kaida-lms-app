import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'dashboard_screen.dart';
// We will build these next!
// import 'explore_screen.dart'; 
// import 'profile_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({Key? key}) : super(key: key);

  @override
  _MainLayoutState createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 2; // Default to 'My Learning' for now

  final List<Widget> _screens = [
    const Center(child: Text('Home Dashboard (Coming Next)', style: TextStyle(fontSize: 18))),
    const Center(child: Text('Explore / Shop (Coming Next)', style: TextStyle(fontSize: 18))),
    const DashboardScreen(), // This is the My Courses screen we already built
    const Center(child: Text('Profile & Role Switch (Coming Next)', style: TextStyle(fontSize: 18))),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Explore'),
          BottomNavigationBarItem(icon: Icon(Icons.play_circle_fill), label: 'My Learning'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
