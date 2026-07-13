import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Paints the scratch layer: image / color / gradient, then erodes with a round
/// stroke or textured stamps along the path.
class ScratchPainter extends CustomPainter {
  /// Creates a scratch painter.
  ScratchPainter({
    required this.borderRadius,
    required this.path,
    required this.scratchPathRevision,
    required this.brushRadius,
    this.overlayColor,
    this.overlayGradient,
    this.overlayImage,
    this.overlayImageFit = BoxFit.cover,
    this.brushTextureImage,
    this.brushTextureLoading = false,
    required this.fullyRevealed,
  });

  /// Border radius clipping the scratch surface.
  final BorderRadius borderRadius;

  /// The scratch path built up by pointer events.
  final Path path;

  /// Increments whenever [path] is mutated in place (reference stays the same); drives [shouldRepaint].
  final int scratchPathRevision;

  /// Half-width of the round scratch stroke.
  final double brushRadius;

  /// Solid fill color for the overlay (used when no gradient or image is set).
  final Color? overlayColor;

  /// Gradient fill for the overlay (ignored when [overlayImage] is set).
  final Gradient? overlayGradient;

  /// Decoded overlay image scratched away by the brush.
  final ui.Image? overlayImage;

  /// How [overlayImage] is fitted to the scratch area.
  final BoxFit overlayImageFit;

  /// Decoded brush-texture image; opaque pixels erase the overlay via [BlendMode.dstOut].
  final ui.Image? brushTextureImage;

  /// True when a [ScratchToWin.brushTexture] is set but not yet decoded.
  final bool brushTextureLoading;

  /// When true the overlay is not painted (child fully revealed).
  final bool fullyRevealed;

  bool get _textureMode => brushTextureImage != null || brushTextureLoading;

  @override
  void paint(Canvas canvas, Size size) {
    if (fullyRevealed) {
      return;
    }

    final rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(rect);

    canvas.saveLayer(rect, Paint());

    _paintOverlay(canvas, rect, rrect);

    if (_textureMode) {
      _eraseWithBrushTexture(canvas, brushTextureImage, path);
    } else {
      _eraseWithStrokedPath(canvas);
    }

    canvas.restore();
  }

  void _paintOverlay(Canvas canvas, Rect rect, RRect rrect) {
    if (overlayImage != null) {
      canvas.save();
      canvas.clipRRect(rrect);
      paintImage(
        canvas: canvas,
        rect: rect,
        image: overlayImage!,
        fit: overlayImageFit,
        filterQuality: FilterQuality.medium,
      );
      canvas.restore();
      return;
    }

    final base = Paint();
    if (overlayGradient != null) {
      base.shader = overlayGradient!.createShader(rect);
    } else {
      base.color = overlayColor ?? const Color(0xFFBDBDBD);
    }
    canvas.drawRRect(rrect, base);
  }

  void _eraseWithStrokedPath(Canvas canvas) {
    final clear = Paint()..blendMode = BlendMode.clear;
    clear
      ..style = PaintingStyle.stroke
      ..strokeWidth = brushRadius * 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, clear);
  }

  void _eraseWithBrushTexture(Canvas canvas, ui.Image? tex, Path scratchPath) {
    for (final m in scratchPath.computeMetrics()) {
      var d = 0.0;
      final len = m.length;
      final step = math.max(2.0, brushRadius * 0.45);
      while (d < len) {
        final tangent = m.getTangentForOffset(d);
        if (tangent == null) {
          break;
        }
        final dst =
            Rect.fromCircle(center: tangent.position, radius: brushRadius);
        _drawBrushStamp(canvas, tex, dst);
        d += step;
      }
    }
  }

  void _drawBrushStamp(Canvas canvas, ui.Image? tex, Rect dst) {
    final center = dst.center;
    final radius = dst.shortestSide / 2;

    if (tex != null) {
      canvas.save();
      final clip = Path()
        ..addOval(Rect.fromCircle(center: center, radius: radius));
      canvas.clipPath(clip);
      final src =
          Rect.fromLTWH(0, 0, tex.width.toDouble(), tex.height.toDouble());
      final paint = Paint()..blendMode = BlendMode.dstOut;
      canvas.drawImageRect(tex, src, dst, paint);
      canvas.restore();
    } else {
      final paint = Paint()..blendMode = BlendMode.clear;
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ScratchPainter oldDelegate) {
    return oldDelegate.scratchPathRevision != scratchPathRevision ||
        oldDelegate.path != path ||
        oldDelegate.brushRadius != brushRadius ||
        oldDelegate.overlayColor != overlayColor ||
        oldDelegate.overlayGradient != overlayGradient ||
        oldDelegate.overlayImage != overlayImage ||
        oldDelegate.overlayImageFit != overlayImageFit ||
        oldDelegate.brushTextureImage != brushTextureImage ||
        oldDelegate.brushTextureLoading != brushTextureLoading ||
        oldDelegate.fullyRevealed != fullyRevealed;
  }
}
