import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'scratch_brush.dart';

/// Details passed to scratch callbacks.
class ScratchDetails {
  /// Creates scratch details.
  const ScratchDetails({
    required this.localPosition,
    required this.pointerCount,
    this.estimatedRevealFraction,
  });

  /// Position in the scratch layer’s local coordinates.
  final Offset localPosition;

  /// Active pointers on the scratch layer.
  final int pointerCount;

  /// Best-effort estimate of how much area has been cleared (0–1), if
  /// [ScratchToWin.trackRevealProgress] is enabled.
  final double? estimatedRevealFraction;
}

/// Paints the scratch layer and clears along the gesture path.
class _ScratchPainter extends CustomPainter {
  _ScratchPainter({
    required this.brushRadius,
    required this.brushShape,
    required this.path,
    required this.dotSamples,
    required this.overlayColor,
    required this.overlayGradient,
    required this.borderRadius,
  });

  final double brushRadius;
  final ScratchBrushShape brushShape;
  final Path path;
  final List<Offset> dotSamples;
  final Color? overlayColor;
  final Gradient? overlayGradient;
  final BorderRadius borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(rect);

    canvas.saveLayer(rect, Paint());

    final base = Paint();
    if (overlayGradient != null) {
      base.shader = overlayGradient!.createShader(rect);
    } else {
      base.color = overlayColor ?? const Color(0xFFBDBDBD);
    }
    canvas.drawRRect(rrect, base);

    final clear = Paint()..blendMode = BlendMode.clear;

    if (brushShape == ScratchBrushShape.dots) {
      for (final o in dotSamples) {
        canvas.drawCircle(o, brushRadius, clear);
      }
    } else {
      clear
        ..style = PaintingStyle.stroke
        ..strokeWidth = brushRadius * 2
        ..strokeCap =
            brushShape == ScratchBrushShape.square ? StrokeCap.square : StrokeCap.round
        ..strokeJoin =
            brushShape == ScratchBrushShape.square ? StrokeJoin.miter : StrokeJoin.round;
      canvas.drawPath(path, clear);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ScratchPainter oldDelegate) {
    return oldDelegate.path != path ||
        oldDelegate.dotSamples != dotSamples ||
        oldDelegate.brushRadius != brushRadius ||
        oldDelegate.brushShape != brushShape ||
        oldDelegate.overlayColor != overlayColor ||
        oldDelegate.overlayGradient != overlayGradient ||
        oldDelegate.borderRadius != borderRadius;
  }
}

/// Hide [child] behind a scratch-off surface; dragging reveals the content.
///
/// Callbacks:
/// - [onScratchStart] — first pointer down on the layer.
/// - [onScratchUpdate] — pointer moved (or additional pointers changed).
/// - [onScratchEnd] — last pointer lifted.
/// - [onScratchCancel] — pointer cancelled (e.g. system gesture won).
/// - [onRevealProgress] — when [trackRevealProgress] is true, as the estimated
///   cleared fraction changes.
/// - [onThresholdReached] — when estimated cleared fraction reaches
///   [revealThreshold] (fires once until reset).
class ScratchToWin extends StatefulWidget {
  /// Creates a scratch-off overlay.
  const ScratchToWin({
    super.key,
    required this.child,
    this.overlayColor,
    this.overlayGradient,
    this.borderRadius = BorderRadius.zero,
    this.brushRadius = 22,
    this.brushShape = ScratchBrushShape.round,
    this.revealThreshold = 0.55,
    this.trackRevealProgress = true,
    this.progressGridResolution = 28,
    this.hapticFeedbackOnStart = true,
    this.hapticFeedbackOnThreshold = true,
    this.enabled = true,
    this.onScratchStart,
    this.onScratchUpdate,
    this.onScratchEnd,
    this.onScratchCancel,
    this.onRevealProgress,
    this.onThresholdReached,
    this.controller,
  }) : assert(revealThreshold > 0 && revealThreshold <= 1),
       assert(progressGridResolution > 0);

  /// Widget revealed underneath.
  final Widget child;

  /// Solid scratch color when [overlayGradient] is null.
  final Color? overlayColor;

  /// Gradient scratch surface (wins over [overlayColor] when set).
  final Gradient? overlayGradient;

  /// Border radius of the scratch surface.
  final BorderRadius borderRadius;

  /// Half-width of the scratch stroke (or dot radius for [ScratchBrushShape.dots]).
  final double brushRadius;

  /// Brush style along the path.
  final ScratchBrushShape brushShape;

  /// Estimated cleared fraction (0–1) to trigger [onThresholdReached].
  final double revealThreshold;

  /// Whether to maintain a grid to estimate reveal progress and call
  /// [onRevealProgress] / [onThresholdReached].
  final bool trackRevealProgress;

  /// Grid size for progress estimation (higher = smoother estimate, more work).
  final int progressGridResolution;

  /// Light haptic when scratching starts.
  final bool hapticFeedbackOnStart;

  /// Medium haptic when [revealThreshold] is first crossed.
  final bool hapticFeedbackOnThreshold;

  /// When false, gestures are ignored.
  final bool enabled;

  /// Called when the first pointer touches the scratch area.
  final void Function(ScratchDetails details)? onScratchStart;

  /// Called when the pointer moves while scratching.
  final void Function(ScratchDetails details)? onScratchUpdate;

  /// Called when the last pointer is released.
  final void Function(ScratchDetails details)? onScratchEnd;

  /// Called when an active pointer is cancelled.
  final void Function(ScratchDetails details)? onScratchCancel;

  /// Estimated cleared fraction (0–1) when [trackRevealProgress] is true.
  final void Function(double fraction)? onRevealProgress;

  /// Called once when estimated cleared fraction reaches [revealThreshold].
  final void Function(double fraction)? onThresholdReached;

  /// Optional controller to programmatically reset the scratch layer.
  final ScratchToWinController? controller;

  @override
  State<ScratchToWin> createState() => _ScratchToWinState();
}

/// Drives [ScratchToWin] from outside the widget tree (e.g. reset the card).
///
/// Attach by passing [ScratchToWin.controller]. Each controller should be used
/// with at most one [ScratchToWin] at a time.
class ScratchToWinController {
  _ScratchToWinState? _state;

  /// Clears scratch strokes and progress so the overlay is fully covered again.
  void reset() {
    _state?._reset();
  }
}

class _ScratchToWinState extends State<ScratchToWin> {
  final Path _scratchPath = Path();
  final List<Offset> _dotSamples = <Offset>[];
  int _activePointers = 0;
  bool _thresholdReported = false;
  late List<bool> _grid;
  int _gridCleared = 0;
  Size? _lastSize;

  @override
  void initState() {
    super.initState();
    widget.controller?._state = this;
    _grid = List<bool>.filled(
      widget.progressGridResolution * widget.progressGridResolution,
      false,
    );
  }

  @override
  void didUpdateWidget(covariant ScratchToWin oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._state = null;
      widget.controller?._state = this;
    }
    if (oldWidget.progressGridResolution != widget.progressGridResolution) {
      _grid = List<bool>.filled(
        widget.progressGridResolution * widget.progressGridResolution,
        false,
      );
      _gridCleared = 0;
      _lastSize = null;
    }
  }

  @override
  void dispose() {
    widget.controller?._state = null;
    super.dispose();
  }

  void _reset() {
    setState(() {
      _scratchPath.reset();
      _dotSamples.clear();
      _thresholdReported = false;
      _gridCleared = 0;
      _grid = List<bool>.filled(
        widget.progressGridResolution * widget.progressGridResolution,
        false,
      );
    });
  }

  double _fraction() {
    if (!widget.trackRevealProgress) return 0;
    return _gridCleared / _grid.length;
  }

  void _markGrid(Offset local, Size size) {
    if (!widget.trackRevealProgress) return;
    final n = widget.progressGridResolution;
    final cellW = size.width / n;
    final cellH = size.height / n;
    final r = widget.brushRadius;
    final minCx = ((local.dx - r) / cellW).floor().clamp(0, n - 1);
    final maxCx = ((local.dx + r) / cellW).ceil().clamp(0, n - 1);
    final minCy = ((local.dy - r) / cellH).floor().clamp(0, n - 1);
    final maxCy = ((local.dy + r) / cellH).ceil().clamp(0, n - 1);
    for (var cy = minCy; cy <= maxCy; cy++) {
      for (var cx = minCx; cx <= maxCx; cx++) {
        final idx = cy * n + cx;
        if (_grid[idx]) continue;
        final cellRect = Rect.fromLTWH(cx * cellW, cy * cellH, cellW, cellH);
        if (_circleIntersectsRect(local, r, cellRect)) {
          _grid[idx] = true;
          _gridCleared++;
        }
      }
    }
  }

  bool _circleIntersectsRect(Offset c, double radius, Rect rect) {
    final closest = Offset(
      c.dx.clamp(rect.left, rect.right),
      c.dy.clamp(rect.top, rect.bottom),
    );
    return (closest - c).distance <= radius;
  }

  void _emitProgress() {
    if (!widget.trackRevealProgress) return;
    final f = _fraction();
    widget.onRevealProgress?.call(f);
    if (!_thresholdReported && f >= widget.revealThreshold) {
      _thresholdReported = true;
      if (widget.hapticFeedbackOnThreshold) {
        HapticFeedback.mediumImpact();
      }
      widget.onThresholdReached?.call(f);
    }
  }

  ScratchDetails _details(Offset local) {
    return ScratchDetails(
      localPosition: local,
      pointerCount: _activePointers,
      estimatedRevealFraction: widget.trackRevealProgress ? _fraction() : null,
    );
  }

  void _handlePointerDown(PointerDownEvent e) {
    if (!widget.enabled) return;
    _activePointers++;
    if (_activePointers == 1) {
      if (widget.hapticFeedbackOnStart) {
        HapticFeedback.selectionClick();
      }
      final local = e.localPosition;
      if (widget.brushShape == ScratchBrushShape.dots) {
        _dotSamples.add(local);
      } else {
        _scratchPath.moveTo(local.dx, local.dy);
      }
      final box = context.findRenderObject() as RenderBox?;
      final size = box?.size;
      if (size != null) {
        _lastSize = size;
        _markGrid(local, size);
      }
      widget.onScratchStart?.call(_details(local));
      _emitProgress();
      setState(() {});
    }
  }

  void _handlePointerMove(PointerMoveEvent e) {
    if (!widget.enabled || _activePointers == 0) return;
    final local = e.localPosition;
    if (widget.brushShape == ScratchBrushShape.dots) {
      _dotSamples.add(local);
    } else {
      _scratchPath.lineTo(local.dx, local.dy);
    }
    final box = context.findRenderObject() as RenderBox?;
    final size = box?.size;
    if (size != null) {
      _lastSize = size;
      _markGrid(local, size);
    }
    widget.onScratchUpdate?.call(_details(local));
    _emitProgress();
    setState(() {});
  }

  void _handlePointerUp(PointerUpEvent e) {
    if (_activePointers == 0) return;
    _activePointers = math.max(0, _activePointers - 1);
    final local = e.localPosition;
    if (_activePointers == 0) {
      widget.onScratchEnd?.call(_details(local));
    }
    setState(() {});
  }

  void _handlePointerCancel(PointerCancelEvent e) {
    if (_activePointers == 0) return;
    _activePointers = math.max(0, _activePointers - 1);
    final local = e.localPosition;
    widget.onScratchCancel?.call(_details(local));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final gradient = widget.overlayGradient ??
        const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF757575),
            Color(0xFFBDBDBD),
            Color(0xFFE0E0E0),
            Color(0xFF9E9E9E),
          ],
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(
          constraints.maxWidth,
          constraints.maxHeight,
        );
        if (_lastSize != size && size.width > 0 && size.height > 0) {
          _lastSize = size;
        }

        final effectiveGradient =
            widget.overlayGradient ?? (widget.overlayColor == null ? gradient : null);

        return Stack(
          clipBehavior: Clip.none,
          fit: StackFit.passthrough,
          children: [
            widget.child,
            Positioned.fill(
              child: IgnorePointer(
                ignoring: !widget.enabled,
                child: Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: _handlePointerDown,
                  onPointerMove: _handlePointerMove,
                  onPointerUp: _handlePointerUp,
                  onPointerCancel: _handlePointerCancel,
                  child: RepaintBoundary(
                    child: CustomPaint(
                      size: size,
                      painter: _ScratchPainter(
                        brushRadius: widget.brushRadius,
                        brushShape: widget.brushShape,
                        path: _scratchPath,
                        dotSamples: List<Offset>.from(_dotSamples),
                        overlayColor: widget.overlayColor,
                        overlayGradient: effectiveGradient,
                        borderRadius: widget.borderRadius,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
