import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// The signature FORGE-style backdrop: deep burgundy radial ellipses bleeding
/// into dusty rose over a near-black linear base, finished with a subtle
/// fractal-noise overlay. Used behind every screen in the shell and the
/// live room so all glass surfaces sit on the same painterly depth.
class CongressBackground extends StatelessWidget {
  final Widget? child;

  const CongressBackground({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(painter: _CongressBackgroundPainter()),
          ),
        ),
        ?child,
      ],
    );
  }
}

class _CongressBackgroundPainter extends CustomPainter {
  const _CongressBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    _paintLinearBase(canvas, size);
    _radialEllipse(
      canvas,
      size,
      center: const Alignment(0.0, 0.6),
      radiusX: 1.2,
      radiusY: 0.4,
      colors: const [Color(0x993B1514), Color(0x003B1514)],
      stops: const [0.0, 0.5],
    );
    _radialEllipse(
      canvas,
      size,
      center: const Alignment(0.4, -0.4),
      radiusX: 1.0,
      radiusY: 0.5,
      colors: const [Color(0x33C68C98), Color(0x00C68C98)],
      stops: const [0.0, 0.6],
    );
    _radialEllipse(
      canvas,
      size,
      center: const Alignment(-0.6, -0.8),
      radiusX: 1.4,
      radiusY: 0.6,
      colors: const [Color(0x737B1B37), Color(0x007B1B37)],
      stops: const [0.0, 0.7],
    );
    _paintNoise(canvas, size);
  }

  void _paintLinearBase(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF2a0f10), Color(0xFF1a0a0b), Color(0xFF1a0a0b)],
        stops: [0.0, 0.4, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, paint);
  }

  void _radialEllipse(
    Canvas canvas,
    Size size, {
    required Alignment center,
    required double radiusX,
    required double radiusY,
    required List<Color> colors,
    required List<double> stops,
  }) {
    final c = center.alongSize(size);
    final matrix = Matrix4.identity()
      ..translateByDouble(c.dx, c.dy, 0, 1)
      ..scaleByDouble(size.width * radiusX, size.height * radiusY, 1, 1);
    final paint = Paint()
      ..shader = ui.Gradient.radial(
        Offset.zero,
        1.0,
        colors,
        stops,
        ui.TileMode.clamp,
        matrix.storage,
      );
    canvas.drawRect(Offset.zero & size, paint);
  }

  void _paintNoise(Canvas canvas, Size size) {
    final random = Random(0x4AF);
    final paint = Paint()..blendMode = BlendMode.overlay;
    const tile = 256.0;
    for (double y = 0; y < size.height; y += tile) {
      for (double x = 0; x < size.width; x += tile) {
        const count = 110;
        for (int i = 0; i < count; i++) {
          final gray = (96.0 + random.nextDouble() * 128.0).round();
          final alpha = 0.06 + random.nextDouble() * 0.10;
          paint.color = Color.fromRGBO(gray, gray, gray, alpha);
          canvas.drawCircle(
            Offset(
              x + random.nextDouble() * tile,
              y + random.nextDouble() * tile,
            ),
            0.6 + random.nextDouble() * 0.8,
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CongressBackgroundPainter oldDelegate) => false;
}
