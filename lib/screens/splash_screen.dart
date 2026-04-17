import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accent.withValues(alpha: 0.3),
                    spreadRadius: 8,
                    blurRadius: 20,
                  )
                ],
              ),
              child: const Icon(
                Icons.qr_code_scanner,
                size: 80,
                color: AppTheme.accent,
              ),
            ).animate()
              .scale(duration: 600.ms, curve: Curves.easeOutBack)
              .shimmer(delay: 600.ms, duration: 1200.ms, color: Colors.white54),
            const SizedBox(height: 32),
            const Text(
              'Oi QR Scanner',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2.0,
              ),
            ).animate().fade(delay: 300.ms).slideY(begin: 0.5, end: 0, duration: 500.ms),
            const SizedBox(height: 16),
            const Text(
              'Fast & Secure',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.accent,
                letterSpacing: 1.5,
              ),
            ).animate().fade(delay: 500.ms),
          ],
        ),
      ),
    );
  }
}
