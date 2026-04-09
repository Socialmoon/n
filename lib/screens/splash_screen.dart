import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/brand.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _entryController;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _textSlide;
  late final Animation<double> _textOpacity;
  late final Animation<double> _spinnerOpacity;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );
    _textSlide = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.35, 0.7, curve: Curves.easeOutCubic),
      ),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.35, 0.7, curve: Curves.easeOut),
      ),
    );
    _spinnerOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Color(0xFF0A1A2E),
              Color(0xFF0F2638),
              Color(0xFF153450),
            ],
          ),
        ),
        child: Stack(
          children: <Widget>[
            // Decorative radial glow behind logo
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final pulse = 0.9 + 0.1 * _pulseController.value;
                  return CustomPaint(
                    painter: _GlowPainter(
                      progress: _pulseController.value,
                      scale: pulse,
                    ),
                  );
                },
              ),
            ),

            // Subtle top-left circle
            Positioned(
              top: -80,
              left: -60,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: <Color>[
                      const Color(0x15FFFFFF),
                      const Color(0x00FFFFFF),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom-right accent glow
            Positioned(
              bottom: -100,
              right: -60,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: <Color>[
                      const Color(0x18D4994A),
                      const Color(0x00D4994A),
                    ],
                  ),
                ),
              ),
            ),

            // Main content
            Center(
              child: AnimatedBuilder(
                animation: _entryController,
                builder: (context, child) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      // Logo with glow ring
                      Opacity(
                        opacity: _logoOpacity.value,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              color: Colors.white,
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: const Color(0x40D4994A),
                                  blurRadius: 40,
                                  spreadRadius: 4,
                                ),
                                BoxShadow(
                                  color: const Color(0x20FFFFFF),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: const BrandLogo(
                                  size: 84, withBackdrop: false),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // App name
                      Transform.translate(
                        offset: Offset(0, _textSlide.value),
                        child: Opacity(
                          opacity: _textOpacity.value,
                          child: Text(
                            AppBrand.appName,
                            style: GoogleFonts.merriweather(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Tagline
                      Transform.translate(
                        offset: Offset(0, _textSlide.value),
                        child: Opacity(
                          opacity: _textOpacity.value * 0.75,
                          child: Text(
                            AppBrand.tagline,
                            style: const TextStyle(
                              color: Color(0xB3FFFFFF),
                              fontSize: 14,
                              letterSpacing: 0.4,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Loading indicator
                      Opacity(
                        opacity: _spinnerOpacity.value,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: const Color(0xFFD4994A),
                                strokeCap: StrokeCap.round,
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Loading...',
                              style: TextStyle(
                                color: Color(0x80FFFFFF),
                                fontSize: 12,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowPainter extends CustomPainter {
  _GlowPainter({required this.progress, required this.scale});

  final double progress;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.42);
    final radius = size.width * 0.35 * scale;

    final paint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          Color.lerp(
            const Color(0x0ED4994A),
            const Color(0x18D4994A),
            progress,
          )!,
          const Color(0x00D4994A),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_GlowPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.scale != scale;
}
