import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/brand.dart';

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
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFF0B1F33), Color(0xFF1F4D6B), Color(0xFFC48A3A)],
          ),
        ),
        child: Stack(
          children: <Widget>[
            Positioned(
              top: -120,
              left: -110,
              child: Container(
                width: 320,
                height: 320,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x22FFFFFF),
                ),
              ),
            ),
            Positioned(
              bottom: -150,
              right: -120,
              child: Container(
                width: 360,
                height: 360,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x28FFFFFF),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ScaleTransition(
                    scale: Tween<double>(begin: 0.95, end: 1.05).animate(
                      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
                    ),
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        color: const Color(0xF2FFFFFF),
                      ),
                      child: const BrandLogo(size: 66, withBackdrop: false),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    AppBrand.appName,
                    style: GoogleFonts.merriweather(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    AppBrand.tagline,
                    style: TextStyle(color: Colors.white70, fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  const SizedBox(
                    width: 34,
                    height: 34,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}