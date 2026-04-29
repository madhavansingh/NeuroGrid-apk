import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Logo reveal: fade + scale
  late AnimationController _revealCtrl;
  late Animation<double> _fade;
  late Animation<double> _scale;

  // Glow pulse: repeating
  late AnimationController _glowCtrl;
  late Animation<double> _glow;

  // Slow gradient drift
  late AnimationController _driftCtrl;

  @override
  void initState() {
    super.initState();

    _revealCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _revealCtrl, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.78, end: 1.0).animate(
      CurvedAnimation(parent: _revealCtrl, curve: Curves.easeOutBack),
    );

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _glow = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    _driftCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _revealCtrl.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2400));
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final hasOnboarded = prefs.getBool('has_onboarded') ?? false;
    if (!mounted) return;
    Navigator.pushReplacementNamed(
      context,
      hasOnboarded ? AppRoutes.homeScreen : AppRoutes.onboardingScreen,
    );
  }

  @override
  void dispose() {
    _revealCtrl.dispose();
    _glowCtrl.dispose();
    _driftCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_revealCtrl, _glowCtrl, _driftCtrl]),
        builder: (context, _) {
          final drift = _driftCtrl.value;
          return Container(
            width: double.infinity,
            height: double.infinity,
            // Soft light-blue → white gradient with subtle drift
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(0 + drift * 0.1, -1),
                end: Alignment(0 - drift * 0.1, 1),
                colors: const [
                  Color(0xFFD9ECFF),
                  Color(0xFFEEF6FF),
                  Color(0xFFF8FCFF),
                  Color(0xFFFFFFFF),
                ],
                stops: const [0.0, 0.3, 0.65, 1.0],
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  // ── Glow + Logo ──────────────────────────────────────────
                  FadeTransition(
                    opacity: _fade,
                    child: ScaleTransition(
                      scale: _scale,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer glow ring
                          Opacity(
                            opacity: _glow.value,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    const Color(0xFF1A6BF5).withAlpha(60),
                                    const Color(0xFF1A6BF5).withAlpha(0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Logo container
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF1A6BF5),
                                  Color(0xFF2E8BFF),
                                  Color(0xFF5BADFF),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(26),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF1A6BF5)
                                      .withAlpha((120 * _glow.value).round()),
                                  blurRadius: 32,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: CustomPaint(
                              painter: _NeuralLogoMark(
                                progress: _revealCtrl.value,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Wordmark ─────────────────────────────────────────────
                  FadeTransition(
                    opacity: _fade,
                    child: Column(
                      children: [
                        Text(
                          'NeuroGrid',
                          style: GoogleFonts.dmSans(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                            letterSpacing: -1.0,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Smart City Intelligence',
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 2),

                  // ── Animated dots loader ─────────────────────────────────
                  FadeTransition(
                    opacity: _fade,
                    child: _BouncingDots(),
                  ),
                  const SizedBox(height: 52),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Premium neural-network logo mark ─────────────────────────────────────────

class _NeuralLogoMark extends CustomPainter {
  final double progress;
  _NeuralLogoMark({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.32;

    final linePaint = Paint()
      ..color = Colors.white.withAlpha(100)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final nodePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // 6 outer nodes arranged in a hexagon
    final nodes = List.generate(6, (i) {
      final angle = (i * math.pi / 3) - math.pi / 2;
      return Offset(cx + r * math.cos(angle), cy + r * math.sin(angle));
    });

    // Draw connection lines (only to center and adjacent)
    for (final node in nodes) {
      canvas.drawLine(Offset(cx, cy), node, linePaint);
    }
    // Adjacent ring connections
    for (int i = 0; i < nodes.length; i++) {
      canvas.drawLine(nodes[i], nodes[(i + 2) % nodes.length], linePaint);
    }

    // Outer nodes
    for (final node in nodes) {
      canvas.drawCircle(node, 3.5, nodePaint);
    }

    // Center hub — larger
    canvas.drawCircle(Offset(cx, cy), 7, centerPaint);

    // Inner dot
    canvas.drawCircle(
      Offset(cx, cy),
      3.5,
      Paint()..color = const Color(0xFF1A6BF5),
    );
  }

  @override
  bool shouldRepaint(_NeuralLogoMark old) => old.progress != progress;
}

// ── Bouncing 3-dot loader ─────────────────────────────────────────────────────

class _BouncingDots extends StatefulWidget {
  @override
  State<_BouncingDots> createState() => _BouncingDotsState();
}

class _BouncingDotsState extends State<_BouncingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final phase = (i / 3.0);
            final t = ((_ctrl.value - phase) % 1.0);
            final y = math.sin(t * math.pi) * 6.0;
            return Transform.translate(
              offset: Offset(0, -y),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A6BF5).withAlpha(
                    (180 + 75 * math.sin(t * math.pi)).round(),
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
