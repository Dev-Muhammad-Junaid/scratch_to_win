import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Lightweight confetti across the full card: spawns along the top (full width)
/// and through the upper/mid area so nothing clusters on one side.
class ScratchCelebrationOverlay extends StatefulWidget {
  /// Creates an overlay; runs one cycle then calls [onEnded].
  const ScratchCelebrationOverlay({
    super.key,
    required this.areaSize,
    required this.particleCount,
    this.onEnded,
  });

  final Size areaSize;
  final int particleCount;
  final VoidCallback? onEnded;

  @override
  State<ScratchCelebrationOverlay> createState() => _ScratchCelebrationOverlayState();
}

class _Particle {
  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.rotation,
    required this.spin,
    required this.color,
    required this.w,
    required this.h,
    required this.life,
  });

  double x;
  double y;
  double vx;
  double vy;
  double rotation;
  double spin;
  final Color color;
  final double w;
  final double h;
  double life;
}

class _ScratchCelebrationOverlayState extends State<ScratchCelebrationOverlay>
    with SingleTickerProviderStateMixin {
  static const double _gravity = 520;
  static const double _drag = 0.985;

  final List<_Particle> _particles = [];
  Ticker? _ticker;
  Duration _firstTick = Duration.zero;
  Duration _prevElapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    if (widget.areaSize.width <= 0 || widget.areaSize.height <= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onEnded?.call());
      return;
    }
    _spawn();
    _ticker = createTicker(_onTick)..start();
  }

  void _spawn() {
    _particles.clear();
    final w = widget.areaSize.width;
    final h = widget.areaSize.height;
    if (w <= 0 || h <= 0) {
      return;
    }
    final rand = math.Random();
    final n = widget.particleCount;
    for (var i = 0; i < n; i++) {
      final fromTop = rand.nextDouble() < 0.55;
      double x;
      double y;
      if (fromTop) {
        x = rand.nextDouble() * w;
        y = -12 - rand.nextDouble() * math.min(40.0, h * 0.15);
        final vy = 80 + rand.nextDouble() * 140;
        final vx = (rand.nextDouble() - 0.5) * 200;
        _particles.add(
          _Particle(
            x: x,
            y: y,
            vx: vx,
            vy: vy,
            rotation: rand.nextDouble() * math.pi * 2,
            spin: (rand.nextDouble() - 0.5) * 5,
            color: Color.fromARGB(
              255,
              80 + rand.nextInt(175),
              80 + rand.nextInt(175),
              80 + rand.nextInt(175),
            ),
            w: 5 + rand.nextDouble() * 7,
            h: 3 + rand.nextDouble() * 6,
            life: 0.95 + rand.nextDouble() * 0.05,
          ),
        );
      } else {
        x = rand.nextDouble() * w;
        y = rand.nextDouble() * h * 0.55;
        final speed = 120 + rand.nextDouble() * 180;
        final dir = rand.nextDouble() * math.pi * 2;
        _particles.add(
          _Particle(
            x: x,
            y: y,
            vx: math.cos(dir) * speed * 0.5,
            vy: math.sin(dir) * speed * 0.5,
            rotation: rand.nextDouble() * math.pi * 2,
            spin: (rand.nextDouble() - 0.5) * 6,
            color: Color.fromARGB(
              255,
              80 + rand.nextInt(175),
              80 + rand.nextInt(175),
              80 + rand.nextInt(175),
            ),
            w: 5 + rand.nextDouble() * 7,
            h: 3 + rand.nextDouble() * 6,
            life: 0.95 + rand.nextDouble() * 0.05,
          ),
        );
      }
    }
  }

  void _onTick(Duration elapsed) {
    if (_firstTick == Duration.zero) {
      _firstTick = elapsed;
      _prevElapsed = elapsed;
      return;
    }

    var dt = (elapsed - _prevElapsed).inMicroseconds / 1e6;
    _prevElapsed = elapsed;
    if (dt <= 0 || dt > 0.05) {
      dt = 1 / 60;
    }

    final w = widget.areaSize.width;
    final h = widget.areaSize.height;

    var visible = 0;
    for (final p in _particles) {
      p.vy += _gravity * dt;
      p.vx *= _drag;
      p.vy *= _drag;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.rotation += p.spin * dt;
      p.life -= 0.36 * dt;
      if (p.life > 0.015 &&
          p.y < h + 100 &&
          p.y > -120 &&
          p.x > -60 &&
          p.x < w + 60) {
        visible++;
      }
    }

    if (mounted) {
      setState(() {});
    }

    final timedOut = (elapsed - _firstTick).inMilliseconds > 4200;
    if (visible == 0 || timedOut) {
      _ticker?.dispose();
      _ticker = null;
      widget.onEnded?.call();
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CelebrationPainter(particles: _particles),
      size: widget.areaSize,
    );
  }
}

class _CelebrationPainter extends CustomPainter {
  _CelebrationPainter({required this.particles});

  final List<_Particle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final o = p.life.clamp(0.0, 1.0);
      if (o <= 0) {
        continue;
      }
      final paint = Paint()
        ..color = p.color.withValues(alpha: o)
        ..style = PaintingStyle.fill;
      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rotation);
      final r = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: p.w, height: p.h),
        const Radius.circular(1),
      );
      canvas.drawRRect(r, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _CelebrationPainter oldDelegate) => true;
}
