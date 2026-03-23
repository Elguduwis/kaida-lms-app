import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../config/app_theme.dart';

class KaidaLoader extends StatefulWidget {
  const KaidaLoader({Key? key}) : super(key: key);

  @override
  _KaidaLoaderState createState() => _KaidaLoaderState();
}

class _KaidaLoaderState extends State<KaidaLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // 2-second continuous loop
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 80,
        height: 80,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // The Base Circle border
            Container(
              width: 70, height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor.withOpacity(0.05),
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3), width: 2),
              ),
            ),
            // The Animated Icons bubbling up
            ClipOval(
              child: SizedBox(
                width: 70, height: 70,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Stack(
                      children: [
                        _buildMovingIcon(Icons.school, 0.0),      // Campus
                        _buildMovingIcon(Icons.build, 0.33),      // Tools
                        _buildMovingIcon(Icons.settings, 0.66),   // Gear
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovingIcon(IconData icon, double delay) {
    // Calculate animation position based on delay
    double animValue = (_controller.value + delay) % 1.0;
    
    // Move from bottom (70) to top (-20)
    double yPos = 70 - (animValue * 90);
    
    // Fade in at the bottom, fade out at the top using a sine wave
    double opacity = math.sin(animValue * math.pi); 
    
    return Positioned(
      left: 23, // Center horizontally (70/2 - 24/2)
      top: yPos,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Icon(icon, color: AppTheme.primaryColor, size: 24),
      ),
    );
  }
}
