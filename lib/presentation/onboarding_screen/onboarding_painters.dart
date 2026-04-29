import 'dart:math' as math;
import 'package:flutter/material.dart';

// ── Onboarding illustration painters ─────────────────────────────────────────

class CityNetworkPainter extends CustomPainter {
  final double t; // 0→1 animation progress
  CityNetworkPainter(this.t);

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width; final h = s.height;
    // Grid background
    final gp = Paint()..color = const Color(0xFF1A6BF5).withAlpha(12)..strokeWidth = 1;
    for (double x = 0; x < w; x += 22) { canvas.drawLine(Offset(x,0), Offset(x,h), gp); }
    for (double y = 0; y < h; y += 22) { canvas.drawLine(Offset(0,y), Offset(w,y), gp); }

    // Buildings
    final buildings = [
      [0.12, 0.55, 0.10, 0.38],
      [0.23, 0.62, 0.09, 0.22],
      [0.33, 0.62, 0.12, 0.30],
      [0.46, 0.62, 0.10, 0.42],
      [0.57, 0.62, 0.09, 0.28],
      [0.67, 0.62, 0.13, 0.35],
      [0.81, 0.62, 0.11, 0.20],
    ];
    for (final b in buildings) {
      final bh = b[3] * t;
      final rect = Rect.fromLTWH(b[0]*w, (b[1]-bh)*h, b[2]*w, bh*h);
      canvas.drawRRect(
        RRect.fromRectAndCorners(rect, topLeft: const Radius.circular(4), topRight: const Radius.circular(4)),
        Paint()..color = const Color(0xFF1A6BF5).withAlpha(160),
      );
      // Window lights
      if (t > 0.5) {
        final wp = Paint()..color = Colors.white.withAlpha(180);
        for (double wy = rect.top + 6; wy < rect.bottom - 4; wy += 10) {
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(rect.left+4, wy, rect.width-8, 4), const Radius.circular(1)), wp);
        }
      }
    }

    // Road
    canvas.drawRect(Rect.fromLTWH(0, h*0.62, w, h*0.06),
        Paint()..color = const Color(0xFF94B4E8).withAlpha(80));
    // Road dashes
    final dp = Paint()..color = Colors.white.withAlpha(120)..strokeWidth = 2;
    for (double x = 0; x < w; x += 28) { canvas.drawLine(Offset(x, h*0.65), Offset(x+14, h*0.65), dp); }

    // Moving car dots
    final carX = w * ((t * 1.2) % 1.0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(carX - 10, h*0.625, 20, 8), const Radius.circular(3)),
      Paint()..color = const Color(0xFF2E8BFF),
    );

    // Data nodes (pulsing)
    final nodes = [Offset(w*0.15, h*0.18), Offset(w*0.82, h*0.22), Offset(w*0.50, h*0.10)];
    for (final n in nodes) {
      final pulse = 0.5 + 0.5 * math.sin(t * math.pi * 4);
      canvas.drawCircle(n, 14 + pulse*4, Paint()..color = const Color(0xFF1A6BF5).withAlpha(20));
      canvas.drawCircle(n, 10, Paint()..color = Colors.white..style = PaintingStyle.fill);
      canvas.drawCircle(n, 10, Paint()..color = const Color(0xFF1A6BF5)..style = PaintingStyle.stroke..strokeWidth = 1.5);
      canvas.drawCircle(n, 4, Paint()..color = const Color(0xFF1A6BF5));
      // Lines between nodes
      if (t > 0.3) {
        final lp = Paint()..color = const Color(0xFF1A6BF5).withAlpha(60)..strokeWidth = 1.2;
        for (final n2 in nodes) {
          if (n != n2) canvas.drawLine(n, n2, lp);
        }
      }
    }
  }

  @override
  bool shouldRepaint(CityNetworkPainter old) => old.t != t;
}

// ── Insights dashboard painter ────────────────────────────────────────────────

class InsightsDashPainter extends CustomPainter {
  final double t;
  InsightsDashPainter(this.t);

  @override
  void paint(Canvas canvas, Size s) {
    final cards = [
      [0.04, 0.05, 0.42, 0.38, 'traffic', 0xFF1A6BF5],
      [0.54, 0.02, 0.42, 0.38, 'parking', 0xFF0EA5E9],
      [0.04, 0.50, 0.42, 0.38, 'waste',   0xFF10B981],
      [0.54, 0.48, 0.42, 0.38, 'alert',   0xFFF59E0B],
    ];
    for (int i = 0; i < cards.length; i++) {
      final c = cards[i];
      final delay = i * 0.2;
      final prog = ((t - delay) / 0.6).clamp(0.0, 1.0);
      final float = math.sin((t + i * 0.5) * math.pi * 2) * 4.0;
      final rect = Rect.fromLTWH(
        (c[0] as double) * s.width,
        ((c[1] as double) * s.height) + float,
        (c[2] as double) * s.width,
        (c[3] as double) * s.height,
      );
      final rr = RRect.fromRectAndRadius(rect, const Radius.circular(16));
      // Shadow
      canvas.drawRRect(rr.shift(const Offset(0, 4)),
          Paint()..color = Color(c[5] as int).withAlpha(30)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
      // Card bg
      canvas.drawRRect(rr, Paint()..color = Colors.white);
      // Color accent bar
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(rect.left, rect.top, rect.width, 4),
          topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
        ),
        Paint()..color = Color(c[5] as int).withAlpha((255 * prog).round()),
      );
    }
  }

  @override
  bool shouldRepaint(InsightsDashPainter old) => old.t != t;
}

// ── AI decision painter ───────────────────────────────────────────────────────

class AiDecisionPainter extends CustomPainter {
  final double t;
  AiDecisionPainter(this.t);

  @override
  void paint(Canvas canvas, Size s) {
    // Background wave
    final wavePaint = Paint()
      ..color = const Color(0xFF1A6BF5).withAlpha(15)
      ..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(0, s.height * 0.6);
    for (double x = 0; x <= s.width; x += 2) {
      final y = s.height * 0.6 + math.sin((x / s.width * 3 * math.pi) + t * math.pi * 2) * 20;
      path.lineTo(x, y);
    }
    path.lineTo(s.width, s.height);
    path.lineTo(0, s.height);
    path.close();
    canvas.drawPath(path, wavePaint);

    // User bubble
    if (t > 0.1) {
      final bubbleP = ((t - 0.1) / 0.3).clamp(0.0, 1.0);
      final bRect = Rect.fromLTWH(s.width * 0.2, s.height * 0.1, s.width * 0.6, s.height * 0.18);
      canvas.drawRRect(
        RRect.fromRectAndRadius(bRect, const Radius.circular(14)),
        Paint()..color = const Color(0xFFEBF1FF).withAlpha((255 * bubbleP).round()),
      );
    }

    // AI reply bubble
    if (t > 0.5) {
      final replyP = ((t - 0.5) / 0.4).clamp(0.0, 1.0);
      final rRect = Rect.fromLTWH(s.width * 0.1, s.height * 0.35, s.width * 0.7, s.height * 0.20);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rRect, const Radius.circular(14)),
        Paint()..color = const Color(0xFF1A6BF5).withAlpha((255 * replyP).round()),
      );
    }
  }

  @override
  bool shouldRepaint(AiDecisionPainter old) => old.t != t;
}
