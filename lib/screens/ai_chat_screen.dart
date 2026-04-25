import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class AiChatScreen extends StatelessWidget {
  const AiChatScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.darkSurfaceColor : AppTheme.primaryColor,
        title: const Text('Kaida AI', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome, size: 64, color: AppTheme.primaryColor),
              ),
              const SizedBox(height: 32),
              Text(
                'Kaida AI is Awakening...',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87),
              ),
              const SizedBox(height: 12),
              Text(
                'Your personal, intelligent learning assistant is currently being trained. It will be available in the next major update!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
