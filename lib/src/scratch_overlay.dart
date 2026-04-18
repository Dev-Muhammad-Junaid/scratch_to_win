import 'package:flutter/material.dart';

/// Default visual for the scratch layer: metallic gradient + subtle shine.
class ScratchMetallicOverlay extends StatelessWidget {
  /// Creates a metallic-looking scratch surface.
  const ScratchMetallicOverlay({
    super.key,
    this.baseColor = const Color(0xFF9E9E9E),
    this.highlightColor = const Color(0xFFE0E0E0),
    this.shadowColor = const Color(0xFF616161),
    this.borderRadius = BorderRadius.zero,
  });

  /// Mid-tone color of the metal strip.
  final Color baseColor;

  /// Highlight streak across the surface.
  final Color highlightColor;

  /// Edge shading.
  final Color shadowColor;

  /// Optional border radius.
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              shadowColor,
              baseColor,
              highlightColor,
              baseColor,
              shadowColor,
            ],
            stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
          ),
        ),
      ),
    );
  }
}
