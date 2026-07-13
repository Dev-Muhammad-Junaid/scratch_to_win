import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Falling scratch flakes emitted while the user scrapes the overlay.
///
/// Call [ScratchDebrisLayerState.emit] from the parent (via [GlobalKey]) as
/// the brush moves. Particles fall with gravity and fade out.
class ScratchDebrisLayer extends StatefulWidget {
  /// Creates a debris layer sized to [areaSize].
  const ScratchDebrisLayer({
    super.key,
    required this.areaSize,
    this.enabled = true,
  });

  /// Bounds used for culling off-screen flakes.
  final Size areaSize;

  /// When false, [ScratchDebrisLayerState.emit] is a no-op.
  final bool enabled;

  @override
  State<ScratchDebrisLayer> createState() => ScratchDebrisLayerState();
}

/// Public state so [ScratchToWin] can spawn flakes along the brush path.
class ScratchDebrisLayerState extends State<ScratchDebrisLayer>
    with SingleTickerProviderStateMixin {
  static const double _gravity = 980;
  static const double _drag = 0.97;
  static const int _maxParticles = 120;

  final List<_DebrisParticle> _particles = <_DebrisParticle>[];
  final math.Random _rand = math.Random();
  Ticker? _ticker;
  Duration _prevElapsed = Duration.zero;
  Offset? _lastEmit;
  int _emitBudget = 0;

  /// Spawns a few flakes at [local] (scratch-layer coordinates).
  ///
  /// [strokeDirection] biases initial velocity (optional). [baseColor] tints
  /// flakes toward the overlay foil color.
  void emit(
    Offset local, {
    Offset? strokeDirection,
    Color? baseColor,
    int count = 3,
  }) {
    if (!widget.enabled || !mounted) {
      return;
    }
    if (widget.areaSize.isEmpty) {
      return;
    }

    // Throttle dense move events so we don't flood the particle list.
    final last = _lastEmit;
    if (last != null && (local - last).distance < 4) {
      _emitBudget++;
      if (_emitBudget < 2) {
        return;
      }
      _emitBudget = 0;
    } else {
      _emitBudget = 0;
    }
    _lastEmit = local;

    final dir = strokeDirection;
    double nx = 0;
    double ny = 1;
    if (dir != null) {
      final dirLen = dir.distance;
      if (dirLen > 0.001) {
        nx = dir.dx / dirLen;
        ny = dir.dy / dirLen;
      }
    }

    final foil = baseColor ?? const Color(0xFFB0B0B0);
    final n = count.clamp(1, 6);

    for (var i = 0; i < n; i++) {
      if (_particles.length >= _maxParticles) {
        _particles.removeAt(0);
      }
      final jitter = Offset(
        (_rand.nextDouble() - 0.5) * 10,
        (_rand.nextDouble() - 0.5) * 10,
      );
      final side = (_rand.nextDouble() - 0.5) * 140;
      final sprayX = -ny * side + nx * (_rand.nextDouble() * 40);
      final sprayY = nx * side.abs() * 0.15 + 40 + _rand.nextDouble() * 120;
      final size = 1.5 + _rand.nextDouble() * 3.5;
      final shade = 0.75 + _rand.nextDouble() * 0.35;
      _particles.add(
        _DebrisParticle(
          x: local.dx + jitter.dx,
          y: local.dy + jitter.dy,
          vx: sprayX + (_rand.nextDouble() - 0.5) * 60,
          vy: sprayY,
          rotation: _rand.nextDouble() * math.pi * 2,
          spin: (_rand.nextDouble() - 0.5) * 12,
          color: Color.fromARGB(
            255,
            (foil.r * 255.0 * shade).round().clamp(40, 255),
            (foil.g * 255.0 * shade).round().clamp(40, 255),
            (foil.b * 255.0 * shade).round().clamp(40, 255),
          ),
          w: size * (0.6 + _rand.nextDouble() * 1.4),
          h: size * (0.4 + _rand.nextDouble()),
          life: 0.55 + _rand.nextDouble() * 0.55,
        ),
      );
    }

    _ensureTicker();
    setState(() {});
  }

  void clear() {
    _particles.clear();
    _lastEmit = null;
    _stopTickerIfIdle();
    if (mounted) {
      setState(() {});
    }
  }

  void _ensureTicker() {
    if (_ticker != null) {
      return;
    }
    _prevElapsed = Duration.zero;
    _ticker = createTicker(_onTick)..start();
  }

  void _stopTickerIfIdle() {
    if (_particles.isEmpty) {
      _ticker?.dispose();
      _ticker = null;
      _prevElapsed = Duration.zero;
    }
  }

  void _onTick(Duration elapsed) {
    if (_prevElapsed == Duration.zero) {
      _prevElapsed = elapsed;
      return;
    }
    var dt = (elapsed - _prevElapsed).inMicroseconds / 1e6;
    _prevElapsed = elapsed;
    if (dt <= 0 || dt > 0.05) {
      dt = 1 / 60;
    }

    final h = widget.areaSize.height;
    final w = widget.areaSize.width;
    _particles.removeWhere((p) {
      p.vy += _gravity * dt;
      p.vx *= _drag;
      p.vy *= _drag;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.rotation += p.spin * dt;
      p.life -= dt * 1.35;
      return p.life <= 0 || p.y > h + 40 || p.x < -40 || p.x > w + 40;
    });

    if (mounted) {
      setState(() {});
    }
    _stopTickerIfIdle();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_particles.isEmpty) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: CustomPaint(
        size: widget.areaSize,
        painter:
            _DebrisPainter(particles: List<_DebrisParticle>.of(_particles)),
      ),
    );
  }
}

class _DebrisParticle {
  _DebrisParticle({
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

class _DebrisPainter extends CustomPainter {
  _DebrisPainter({required this.particles});

  final List<_DebrisParticle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final o = (p.life / 0.9).clamp(0.0, 1.0);
      if (o <= 0) {
        continue;
      }
      final paint = Paint()
        ..color = p.color.withValues(alpha: o * 0.9)
        ..style = PaintingStyle.fill;
      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rotation);
      // Irregular flake: thin diamond / shard.
      final path = Path()
        ..moveTo(0, -p.h)
        ..lineTo(p.w * 0.55, 0)
        ..lineTo(0, p.h * 0.65)
        ..lineTo(-p.w * 0.45, 0)
        ..close();
      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _DebrisPainter oldDelegate) => true;
}
