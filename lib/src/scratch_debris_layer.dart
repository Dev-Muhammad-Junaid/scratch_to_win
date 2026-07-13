import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Falling scratch flakes emitted while the user scrapes the overlay.
///
/// Drive this via [ScratchDebrisController] (owned by [ScratchToWin]) so
/// spawning does not depend on [GlobalKey.currentState] timing.
class ScratchDebrisLayer extends StatefulWidget {
  /// Creates a debris layer sized to [areaSize].
  const ScratchDebrisLayer({
    super.key,
    required this.areaSize,
    required this.controller,
    this.enabled = true,
  });

  /// Bounds used for culling off-screen flakes.
  final Size areaSize;

  /// Shared spawn / clear API from the parent scratch widget.
  final ScratchDebrisController controller;

  /// When false, [ScratchDebrisController.emit] is a no-op.
  final bool enabled;

  @override
  State<ScratchDebrisLayer> createState() => _ScratchDebrisLayerState();
}

/// Lets [ScratchToWin] spawn flakes without a [GlobalKey].
class ScratchDebrisController {
  _ScratchDebrisLayerState? _state;

  /// Spawns flakes at [local] (scratch-layer coordinates).
  void emit(
    Offset local, {
    Offset? strokeDirection,
    Color? baseColor,
    int count = 5,
  }) {
    _state?.emit(
      local,
      strokeDirection: strokeDirection,
      baseColor: baseColor,
      count: count,
    );
  }

  /// Removes all flakes immediately.
  void clear() => _state?.clear();
}

class _ScratchDebrisLayerState extends State<ScratchDebrisLayer>
    with SingleTickerProviderStateMixin {
  static const double _gravity = 900;
  static const double _drag = 0.99;
  static const int _maxParticles = 180;

  final List<_DebrisParticle> _particles = <_DebrisParticle>[];
  final math.Random _rand = math.Random();
  Ticker? _ticker;
  Duration _prevElapsed = Duration.zero;
  Offset? _lastEmit;

  @override
  void initState() {
    super.initState();
    widget.controller._state = this;
  }

  @override
  void didUpdateWidget(covariant ScratchDebrisLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller._state = null;
      widget.controller._state = this;
    }
  }

  @override
  void dispose() {
    if (widget.controller._state == this) {
      widget.controller._state = null;
    }
    _ticker?.dispose();
    super.dispose();
  }

  void emit(
    Offset local, {
    Offset? strokeDirection,
    Color? baseColor,
    int count = 5,
  }) {
    if (!widget.enabled || !mounted) {
      return;
    }
    if (widget.areaSize.isEmpty) {
      return;
    }

    final last = _lastEmit;
    if (last != null && (local - last).distance < 2) {
      return;
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

    final foil = baseColor ?? const Color(0xFFE8E8E8);
    final n = count.clamp(3, 12);

    for (var i = 0; i < n; i++) {
      if (_particles.length >= _maxParticles) {
        _particles.removeAt(0);
      }
      final jitter = Offset(
        (_rand.nextDouble() - 0.5) * 18,
        (_rand.nextDouble() - 0.5) * 18,
      );
      final side = (_rand.nextDouble() - 0.5) * 260;
      final sprayX = -ny * side + nx * (_rand.nextDouble() * 80);
      // Mild downward bias so flakes hang in view longer.
      final sprayY = 20 + _rand.nextDouble() * 140;
      final size = 5.0 + _rand.nextDouble() * 10.0;
      final light = _rand.nextBool();
      final shade = light
          ? 0.95 + _rand.nextDouble() * 0.4
          : 0.4 + _rand.nextDouble() * 0.35;
      // Warm metallic foil — readable on photos and solid fills.
      final r =
          (foil.r * 255.0 * shade + (light ? 40 : 0)).round().clamp(40, 255);
      final g =
          (foil.g * 255.0 * shade + (light ? 28 : 0)).round().clamp(40, 255);
      final b = (foil.b * 255.0 * shade * 0.85).round().clamp(30, 255);
      _particles.add(
        _DebrisParticle(
          x: local.dx + jitter.dx,
          y: local.dy + jitter.dy,
          vx: sprayX + (_rand.nextDouble() - 0.5) * 100,
          vy: sprayY,
          rotation: _rand.nextDouble() * math.pi * 2,
          spin: (_rand.nextDouble() - 0.5) * 18,
          color: Color.fromARGB(255, r, g, b),
          w: size * (0.8 + _rand.nextDouble() * 1.4),
          h: size * (0.5 + _rand.nextDouble() * 0.9),
          life: 1.1 + _rand.nextDouble() * 0.9,
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
      p.life -= dt * 0.75;
      return p.life <= 0 || p.y > h + 60 || p.x < -60 || p.x > w + 60;
    });

    if (mounted) {
      setState(() {});
    }
    _stopTickerIfIdle();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: widget.areaSize,
        painter: _DebrisPainter(
          particles: List<_DebrisParticle>.of(_particles),
        ),
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
      final o = (p.life / 1.2).clamp(0.0, 1.0);
      if (o <= 0) {
        continue;
      }
      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rotation);
      final path = Path()
        ..moveTo(0, -p.h)
        ..lineTo(p.w * 0.55, 0)
        ..lineTo(0, p.h * 0.65)
        ..lineTo(-p.w * 0.45, 0)
        ..close();
      final fill = Paint()
        ..color = p.color.withValues(alpha: o * 0.98)
        ..style = PaintingStyle.fill;
      final rim = Paint()
        ..color = Colors.black.withValues(alpha: o * 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.25;
      final shine = Paint()
        ..color = Colors.white.withValues(alpha: o * 0.55)
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fill);
      canvas.drawPath(path, rim);
      canvas.drawCircle(Offset(-p.w * 0.12, -p.h * 0.25), p.w * 0.12, shine);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _DebrisPainter oldDelegate) => true;
}
