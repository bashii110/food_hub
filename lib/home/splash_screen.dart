import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../components/theme/apptheme.dart';
import '../data/services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward();
  }

  // Future<void> _navigate() async {
  //   await Future.delayed(const Duration(seconds: 2));
  //
  //   final isLoggedIn = await AuthService.isLoggedIn();
  //
  //   if (!mounted) return;
  //
  //   Navigator.pushReplacementNamed(
  //     context,
  //     isLoggedIn ? '/home' : '/login',
  //   );
  // }

  @override
  void dispose() {
    _controller.dispose(); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: ScaleTransition(
          scale: CurvedAnimation(
            parent: _controller,
            curve: Curves.easeOutBack,
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.fastfood,
                size: 72,
                color: Colors.white,
              ),
              SizedBox(height: 16),
              Text(
                'FoodHub',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
