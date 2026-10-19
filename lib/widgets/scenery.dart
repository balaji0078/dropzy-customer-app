import 'package:flutter/material.dart';
import '../core/theme.dart';

/// A hand-drawn Tamil-Nadu-flavoured scene — gopuram temple skyline, hills,
/// palms, sun, and a bus carrying a parcel — used as the illustrated header on
/// each page. Pure vector (no image assets), themed to the dark/violet palette.
class DropzyHero extends StatelessWidget {
  const DropzyHero({
    super.key,
    required this.title,
    this.subtitle,
    this.height = 190,
    this.overlay,
    this.showBus = true,
  });

  final String title;
  final String? subtitle;
  final double height;

  /// Optional widget pinned to the top-right of the hero (e.g. an avatar).
  final Widget? overlay;
  final bool showBus;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Sky gradient
          DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF3B2C67), Color(0xFF241A3D), Color(0xFF14101F)],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
          ),
          // The scene
          ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
            child: CustomPaint(painter: _ScenePainter(showBus: showBus)),
          ),
          // Text
          Positioned(
            left: 22,
            right: 22,
            top: 54,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              height: 1.1)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(subtitle!,
                            style: const TextStyle(
                                color: Color(0xFFCFC8E6), fontSize: 13.5, height: 1.3)),
                      ],
                    ],
                  ),
                ),
                if (overlay != null) overlay!,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScenePainter extends CustomPainter {
  _ScenePainter({required this.showBus});
  final bool showBus;

  static const _silhouette = Color(0xFF201A38);
  static const _backHill = Color(0xFF2E2450);
  static const _road = Color(0xFF17131F);
  static const _sun = Color(0xFFFBBF24);
  static const _bus = DropzyColors.primary;
  static const _window = Color(0xFFEDEAF8);
  static const _parcel = Color(0xFFF4C15A);

  @override
  void paint(Canvas canvas, Size size) {
    // Design space: 400 x (400 * aspect). Uniform scale by width.
    final k = size.width / 400;
    canvas.save();
    canvas.scale(k);
    final h = size.height / k; // design-space height
    final ground = h - 18;
    final p = Paint()..isAntiAlias = true;

    // ── Sun with glow ──
    p.color = _sun.withValues(alpha: 0.16);
    canvas.drawCircle(const Offset(232, 50), 40, p);
    p.color = _sun;
    canvas.drawCircle(const Offset(232, 50), 22, p);

    // ── Back hills ──
    p.color = _backHill;
    final back = Path()
      ..moveTo(0, ground)
      ..lineTo(0, ground - 34)
      ..quadraticBezierTo(90, ground - 74, 190, ground - 40)
      ..quadraticBezierTo(300, ground - 4, 400, ground - 44)
      ..lineTo(400, ground)
      ..close();
    canvas.drawPath(back, p);

    // ── Gopuram (temple tower) silhouette ──
    _drawGopuram(canvas, p, cx: 72, baseY: ground);

    // ── Palm trees ──
    _drawPalm(canvas, p, x: 150, baseY: ground, scale: 1.0);
    _drawPalm(canvas, p, x: 356, baseY: ground, scale: 0.8);

    // ── Front hill ──
    p.color = _silhouette;
    final front = Path()
      ..moveTo(0, ground)
      ..lineTo(0, ground - 12)
      ..quadraticBezierTo(120, ground - 34, 250, ground - 14)
      ..quadraticBezierTo(330, ground - 2, 400, ground - 20)
      ..lineTo(400, ground)
      ..close();
    canvas.drawPath(front, p);

    // ── Road ──
    p.color = _road;
    canvas.drawRect(Rect.fromLTWH(0, ground, 400, 24), p);
    // dashes
    p.color = const Color(0xFF3A3350);
    for (double x = 10; x < 400; x += 46) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, ground + 9, 24, 4), const Radius.circular(2)),
        p,
      );
    }

    // ── Bus carrying a parcel ──
    if (showBus) _drawBus(canvas, p, x: 236, baseY: ground + 4);

    canvas.restore();
  }

  void _drawGopuram(Canvas canvas, Paint p, {required double cx, required double baseY}) {
    p.color = _silhouette;
    // 5 stacked tiers, narrowing upward.
    const tiers = 5;
    for (var i = 0; i < tiers; i++) {
      final w = 66.0 - i * 10;
      const th = 17.0;
      final y = baseY - (i + 1) * (th + 1);
      final r = RRect.fromRectAndCorners(
        Rect.fromLTWH(cx - w / 2, y, w, th),
        topLeft: const Radius.circular(3),
        topRight: const Radius.circular(3),
      );
      canvas.drawRRect(r, p);
    }
    // Kalasam (dome + spire) on top.
    final topY = baseY - tiers * 18 - 2;
    canvas.drawCircle(Offset(cx, topY), 6, p);
    canvas.drawRect(Rect.fromLTWH(cx - 1.5, topY - 14, 3, 12), p);
    // Warm doorway glow at the base.
    p.color = _sun.withValues(alpha: 0.55);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(cx - 6, baseY - 16, 12, 16),
        topLeft: const Radius.circular(6),
        topRight: const Radius.circular(6),
      ),
      p,
    );
  }

  void _drawPalm(Canvas canvas, Paint p, {required double x, required double baseY, double scale = 1}) {
    p.color = _silhouette;
    final trunk = Paint()
      ..color = _silhouette
      ..strokeWidth = 4 * scale
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final topY = baseY - 54 * scale;
    final path = Path()
      ..moveTo(x, baseY)
      ..quadraticBezierTo(x - 6 * scale, baseY - 28 * scale, x, topY);
    canvas.drawPath(path, trunk);
    // Fronds
    final frond = Paint()
      ..color = _silhouette
      ..strokeWidth = 3 * scale
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final dx in [-22.0, -14.0, 14.0, 22.0]) {
      final f = Path()
        ..moveTo(x, topY)
        ..quadraticBezierTo(x + dx * 0.5 * scale, topY - 12 * scale, x + dx * scale, topY - 2 * scale);
      canvas.drawPath(f, frond);
    }
    final fd = Path()
      ..moveTo(x, topY)
      ..quadraticBezierTo(x, topY - 14 * scale, x + 2 * scale, topY - 16 * scale);
    canvas.drawPath(fd, frond);
  }

  void _drawBus(Canvas canvas, Paint p, {required double x, required double baseY}) {
    const bw = 104.0, bh = 40.0;
    final bodyTop = baseY - bh - 8;
    // Parcel on the roof
    p.color = _parcel;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x + 20, bodyTop - 22, 30, 24), const Radius.circular(4)),
      p,
    );
    p.color = const Color(0xFFB4801F);
    canvas.drawRect(Rect.fromLTWH(x + 33, bodyTop - 22, 4, 24), p); // strap v
    canvas.drawRect(Rect.fromLTWH(x + 20, bodyTop - 12, 30, 4), p); // strap h

    // Body
    p.color = _bus;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x, bodyTop, bw, bh), const Radius.circular(9)),
      p,
    );
    // Windows
    p.color = _window;
    for (var i = 0; i < 4; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x + 10 + i * 22, bodyTop + 8, 16, 13), const Radius.circular(3)),
        p,
      );
    }
    // Front destination strip
    p.color = _sun;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x + bw - 10, bodyTop + 8, 6, 13), const Radius.circular(2)),
      p,
    );
    // Wheels
    p.color = const Color(0xFF0E0B16);
    canvas.drawCircle(Offset(x + 26, baseY - 6), 10, p);
    canvas.drawCircle(Offset(x + bw - 26, baseY - 6), 10, p);
    p.color = const Color(0xFF3A3350);
    canvas.drawCircle(Offset(x + 26, baseY - 6), 4, p);
    canvas.drawCircle(Offset(x + bw - 26, baseY - 6), 4, p);
    // Motion lines
    final ml = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final ly = bodyTop + 10 + i * 10;
      canvas.drawLine(Offset(x - 8 - i * 6, ly), Offset(x - 20 - i * 6, ly), ml);
    }
  }

  @override
  bool shouldRepaint(covariant _ScenePainter old) => old.showBus != showBus;
}
