import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Lightweight confetti across the full card: spawns along the top (full width)
/// and through the upper/mid area. [confettiDuration] and chip [Size] ranges
/// match the defaults from the legacy `confetti` package integration.
class ScratchCelebrationOverlay extends StatefulWidget {
  /// Creates an overlay; runs one cycle then calls [onEnded].
  const ScratchCelebrationOverlay({
    super.key,
    required this.areaSize,
    required this.particleCount,
    this.confettiDuration = const Duration(seconds: 4),
    this.confettiMinChipSize = const Size(20, 10),
    this.confettiMaxChipSize = const Size(30, 15),
    this.onEnded,
  });

  final Size areaSize;
  final int particleCount;

  /// Total time before the overlay stops (matches previous [ConfettiController] default).
  final Duration confettiDuration;

  /// Smallest confetti chip (matches legacy [ConfettiWidget] defaults).
  final Size confettiMinChipSize;

  /// Largest confetti chip (matches legacy [ConfettiWidget] defaults).
  final Size confettiMaxChipSize;

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

  double get _lifeDecayPerSecond {
    final s = widget.confettiDuration.inMilliseconds / 1000.0;
    if (s <= 0) {
      return 1.0;
    }
    return 1.0 / s;
  }

  @override
  void initState() {
    super.initState();
    assert(() {
      assert(widget.confettiDuration.inMilliseconds > 0);
      return true;
    }());
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
    final minS = widget.confettiMinChipSize;
    final maxS = widget.confettiMaxChipSize;
    final minW = math.min(minS.width, maxS.width);
    final maxW = math.max(minS.width, maxS.width);
    final minH = math.min(minS.height, maxS.height);
    final maxH = math.max(minS.height, maxS.height);

    for (var i = 0; i < n; i++) {
      final chipW = minW + rand.nextDouble() * (maxW - minW);
      final chipH = minH + rand.nextDouble() * (maxH - minH);

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
            w: chipW,
            h: chipH,
            life: 1,
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
            w: chipW,
            h: chipH,
            life: 1,
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
    final decay = _lifeDecayPerSecond * dt;
    for (final p in _particles) {
      p.vy += _gravity * dt;
      p.vx *= _drag;
      p.vy *= _drag;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.rotation += p.spin * dt;
      p.life -= decay;
      if (p.life > 0.02 &&
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

    final maxMs = widget.confettiDuration.inMilliseconds;
    final timedOut = maxMs > 0 && (elapsed - _firstTick).inMilliseconds >= maxMs;
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
        Radius.circular(math.min(p.w, p.h) * 0.22),
      );
      canvas.drawRRect(r, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _CelebrationPainter oldDelegate) => true;
}
