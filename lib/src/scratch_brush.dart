/// Shape of the scratch “eraser” applied along the gesture path.
enum ScratchBrushShape {
  /// Stroke with round caps and joins (default).
  round,

  /// Stroke with square caps.
  square,

  /// Filled circles at each sampled point (denser, more “spray” feel).
  dots,
}
