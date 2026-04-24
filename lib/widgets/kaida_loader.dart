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
    _controller = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 1500)
    )..repeat();
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
            // Outer Reverse Spinning Ring
            RotationTransition(
              turns: Tween(begin: 1.0, end: 0.0).animate(_controller),
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.primaryColor.withOpacity(0.15), width: 3),
                ),
                child: const CircularProgressIndicator(
                  value: 0.75,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  strokeWidth: 3,
                  backgroundColor: Colors.transparent,
                ),
              ),
            ),
            // Inner Fast Spinning Ring
            RotationTransition(
              turns: _controller,
              child: SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  value: 0.4,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor.withOpacity(0.6)),
                  strokeWidth: 2,
                  backgroundColor: Colors.transparent,
                ),
              ),
            ),
            // Pulsing Center Icon
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                // Sine wave pulse effect
                double scale = 0.85 + (0.15 * math.sin(_controller.value * math.pi * 2));
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.school, color: AppTheme.primaryColor, size: 22),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
