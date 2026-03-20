import 'package:flutter/material.dart';

import '../core/brand.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFF0B1F33), Color(0xFF1F4D6B), Color(0xFFC48A3A)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              BrandLogo(size: 74),
              SizedBox(height: 16),
              Text(
                AppBrand.appName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              SizedBox(height: 8),
              Text(
                AppBrand.tagline,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              SizedBox(height: 24),
              CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}