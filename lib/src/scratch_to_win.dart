import 'dart:ui' as ui;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'scratch_celebration_overlay.dart';
import 'scratch_painter.dart';

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

/// Hide [child] behind a scratch-off surface; dragging reveals the content.
///
/// **Progress:** The scratch area is split into a grid of
/// [progressGridResolution] × [progressGridResolution] cells. When the brush
/// intersects a cell, that cell counts as cleared. [onRevealProgress] reports
/// **clearedCells / totalCells** — a simple, fast approximation of how much of
/// the card has been scratched. Higher resolution tracks the brush shape more
/// closely (smoother progress) but costs a bit more work per pointer event;
/// **24–32** is a good default for most apps; use **16** on very low-end
/// devices or **40–48** if you need a tighter estimate for game logic.
class ScratchToWin extends StatefulWidget {
  /// Creates a scratch-off overlay.
  const ScratchToWin({
    super.key,
    required this.child,
    this.overlayColor,
    this.overlayGradient,
    this.overlayImage,
    this.overlayImageFit = BoxFit.cover,
    this.borderRadius = BorderRadius.zero,
    this.brushRadius = 22,
    this.brushTexture,
    this.revealThreshold = 0.55,
    this.trackRevealProgress = true,
    this.progressGridResolution = 28,
    this.hapticFeedbackOnStart = true,
    this.hapticFeedbackOnThreshold = true,
    this.enabled = true,
    this.playConfettiOnThreshold = false,
    this.confettiParticleCount = 24,
    this.confettiDuration = const Duration(seconds: 4),
    this.confettiMinChipSize = const Size(20, 10),
    this.confettiMaxChipSize = const Size(30, 15),
    this.playSoundOnCompletion = false,
    this.completionSoundAsset,
    this.completionSoundUrl,
    this.showRevealAssistButton = false,
    this.revealAssistButtonLabel,
    this.revealAssistPadding = const EdgeInsets.only(bottom: 12),
    this.onScratchStart,
    this.onScratchUpdate,
    this.onScratchEnd,
    this.onScratchCancel,
    this.onRevealProgress,
    this.onThresholdReached,
    this.controller,
  }) : assert(revealThreshold > 0 && revealThreshold <= 1),
       assert(progressGridResolution > 0),
       assert(confettiParticleCount > 0);

  /// Widget revealed underneath.
  final Widget child;

  /// Solid scratch color when [overlayGradient] / [overlayImage] are null.
  final Color? overlayColor;

  /// Gradient scratch surface (ignored if [overlayImage] is set).
  final Gradient? overlayGradient;

  /// Optional image scratched off instead of a solid color / gradient.
  final ImageProvider? overlayImage;

  /// How [overlayImage] is fitted to the scratch area.
  final BoxFit overlayImageFit;

  /// Border radius of the scratch surface.
  final BorderRadius borderRadius;

  /// Half-width of the round scratch stroke.
  final double brushRadius;

  /// Optional tile image; opaque pixels remove the overlay ([BlendMode.dstOut]).
  final ImageProvider? brushTexture;

  /// Estimated cleared fraction (0–1) to trigger [onThresholdReached].
  final double revealThreshold;

  /// Whether to maintain a grid for progress / threshold.
  final bool trackRevealProgress;

  /// See [ScratchToWin] class documentation.
  final int progressGridResolution;

  /// Light haptic when scratching starts.
  final bool hapticFeedbackOnStart;

  /// Medium haptic when [revealThreshold] is first crossed.
  final bool hapticFeedbackOnThreshold;

  /// When false, gestures are ignored — the [child] can receive taps.
  final bool enabled;

  /// Confetti when the threshold is reached or [ScratchToWinController.revealAll] runs.
  /// Fills the card (rain from the top + sparkle in the upper area), then fades.
  final bool playConfettiOnThreshold;

  /// Number of confetti chips (density).
  final int confettiParticleCount;

  /// How long the confetti overlay runs (previous [ConfettiController] used 4s).
  final Duration confettiDuration;

  /// Lower bound for chip size (legacy [ConfettiWidget] default).
  final Size confettiMinChipSize;

  /// Upper bound for chip size (legacy [ConfettiWidget] default).
  final Size confettiMaxChipSize;

  /// Plays [completionSoundAsset] or [completionSoundUrl] when completed once.
  final bool playSoundOnCompletion;

  /// Path in the **host app** `assets/` (e.g. `assets/win.mp3`). List it in the app `pubspec.yaml`.
  final String? completionSoundAsset;

  /// Optional remote sound (played via [UrlSource]).
  final String? completionSoundUrl;

  /// When true, shows the assist control if [revealAssistButtonLabel] resolves to a
  /// non-empty string (see below). When false, the button is never shown.
  final bool showRevealAssistButton;

  /// Assist button text. If null, defaults to `"Reveal"` when visible. If non-null
  /// and empty after trimming, the button is **hidden** even when [showRevealAssistButton] is true.
  final String? revealAssistButtonLabel;

  /// Insets for the assist button (relative to the stack).
  final EdgeInsets revealAssistPadding;

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

  /// Optional controller: [ScratchToWinController.reset], [ScratchToWinController.revealAll].
  final ScratchToWinController? controller;

  @override
  State<ScratchToWin> createState() => _ScratchToWinState();
}

/// Drives [ScratchToWin] from outside the widget tree.
class ScratchToWinController {
  _ScratchToWinState? _state;

  /// Clears scratch strokes so the overlay is fully covered again.
  void reset() {
    _state?._resetScratch();
  }

  /// Instantly reveals the [child] and triggers completion (same as assist + threshold).
  void revealAll() {
    _state?._revealAll();
  }
}

class _ScratchToWinState extends State<ScratchToWin> {
  final Path _scratchPath = Path();

  /// Drives [ScratchPainter.shouldRepaint] — [Path] is mutated in place, so the
  /// reference alone does not change when the user scratches.
  int _scratchPathRevision = 0;

  ui.Image? _resolvedOverlayImage;
  ui.Image? _resolvedBrushTexture;

  ImageStream? _overlayStream;
  ImageStreamListener? _overlayListener;

  ImageStream? _brushTextureStream;
  ImageStreamListener? _brushListener;

  int _activePointers = 0;
  bool _thresholdReported = false;
  bool _completionEffectsDone = false;
  bool _fullyRevealed = false;

  late List<bool> _grid;
  int _gridCleared = 0;
  Size? _lastSize;

  /// Each completion bumps this so a fresh [ScratchCelebrationOverlay] runs.
  int _celebrationSession = 0;
  bool _celebrationVisible = false;

  AudioPlayer? _audioPlayer;

  /// Effective assist label (defaults to `Reveal` when [ScratchToWin.revealAssistButtonLabel] is null).
  String get _revealAssistEffectiveLabel =>
      (widget.revealAssistButtonLabel ?? 'Reveal').trim();

  /// The assist button is shown only when [ScratchToWin.showRevealAssistButton] is true
  /// and the effective label is non-empty (set label to `''` to keep the flag on but hide).
  bool get _shouldShowRevealAssistButton =>
      widget.showRevealAssistButton && _revealAssistEffectiveLabel.isNotEmpty;

  @override
  void initState() {
    super.initState();
    assert(() {
      final d = widget.confettiDuration;
      final mn = widget.confettiMinChipSize;
      final mx = widget.confettiMaxChipSize;
      assert(d.inMilliseconds > 0);
      assert(mn.width > 0 && mn.height > 0);
      assert(mx.width > 0 && mx.height > 0);
      assert(mn.width <= mx.width && mn.height <= mx.height);
      return true;
    }());
    widget.controller?._state = this;
    _grid = _freshGrid();
    if (widget.playSoundOnCompletion &&
        (widget.completionSoundAsset != null || widget.completionSoundUrl != null)) {
      _audioPlayer = AudioPlayer();
    }
  }

  List<bool> _freshGrid() {
    return List<bool>.filled(
      widget.progressGridResolution * widget.progressGridResolution,
      false,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _attachOverlayImage();
    _attachBrushTexture();
  }

  @override
  void didUpdateWidget(covariant ScratchToWin oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._state = null;
      widget.controller?._state = this;
    }
    if (oldWidget.overlayImage != widget.overlayImage) {
      _attachOverlayImage();
    }
    if (oldWidget.brushTexture != widget.brushTexture) {
      _attachBrushTexture();
    }
    if (oldWidget.progressGridResolution != widget.progressGridResolution) {
      _grid = _freshGrid();
      _gridCleared = 0;
      _lastSize = null;
    }
    final needPlayer = widget.playSoundOnCompletion &&
        (widget.completionSoundAsset != null || widget.completionSoundUrl != null);
    if (needPlayer && _audioPlayer == null) {
      _audioPlayer = AudioPlayer();
    } else if (!needPlayer && _audioPlayer != null) {
      _audioPlayer?.dispose();
      _audioPlayer = null;
    }
  }

  void _attachOverlayImage() {
    final provider = widget.overlayImage;
    if (provider == null) {
      _overlayStream?.removeListener(_overlayListener!);
      _overlayStream = null;
      _overlayListener = null;
      if (_resolvedOverlayImage != null) {
        setState(() => _resolvedOverlayImage = null);
      }
      return;
    }

    final stream = provider.resolve(createLocalImageConfiguration(context));
    if (stream == _overlayStream) {
      return;
    }

    _overlayStream?.removeListener(_overlayListener!);

    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (ImageInfo info, bool _) {
        if (!mounted) {
          return;
        }
        setState(() => _resolvedOverlayImage = info.image);
      },
      onError: (Object error, StackTrace? stackTrace) {
        if (mounted) {
          setState(() => _resolvedOverlayImage = null);
        }
      },
    );

    _overlayListener = listener;
    _overlayStream = stream;
    stream.addListener(listener);
  }

  void _attachBrushTexture() {
    final provider = widget.brushTexture;
    if (provider == null) {
      _brushTextureStream?.removeListener(_brushListener!);
      _brushTextureStream = null;
      _brushListener = null;
      if (_resolvedBrushTexture != null) {
        setState(() => _resolvedBrushTexture = null);
      }
      return;
    }

    final stream = provider.resolve(createLocalImageConfiguration(context));
    if (stream == _brushTextureStream) {
      return;
    }

    _brushTextureStream?.removeListener(_brushListener!);

    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (ImageInfo info, bool _) {
        if (!mounted) {
          return;
        }
        setState(() => _resolvedBrushTexture = info.image);
      },
      onError: (Object error, StackTrace? stackTrace) {
        if (mounted) {
          setState(() => _resolvedBrushTexture = null);
        }
      },
    );

    _brushListener = listener;
    _brushTextureStream = stream;
    stream.addListener(listener);
  }

  @override
  void dispose() {
    widget.controller?._state = null;
    if (_overlayListener != null && _overlayStream != null) {
      _overlayStream!.removeListener(_overlayListener!);
    }
    if (_brushListener != null && _brushTextureStream != null) {
      _brushTextureStream!.removeListener(_brushListener!);
    }
    _audioPlayer?.dispose();
    super.dispose();
  }

  void _resetScratch() {
    setState(() {
      _scratchPath.reset();
      _scratchPathRevision++;
      _thresholdReported = false;
      _completionEffectsDone = false;
      _fullyRevealed = false;
      _gridCleared = 0;
      _grid = _freshGrid();
      _celebrationVisible = false;
    });
  }

  void _revealAll() {
    if (_fullyRevealed) {
      return;
    }
    final hadThreshold = _thresholdReported;
    setState(() {
      _fullyRevealed = true;
      _thresholdReported = true;
      if (widget.trackRevealProgress) {
        _gridCleared = _grid.length;
        for (var i = 0; i < _grid.length; i++) {
          _grid[i] = true;
        }
      }
    });
    widget.onRevealProgress?.call(1.0);
    if (!hadThreshold) {
      widget.onThresholdReached?.call(1.0);
    }
    _runCompletionEffects();
  }

  double _fraction() {
    if (!widget.trackRevealProgress) {
      return 0;
    }
    if (_fullyRevealed) {
      return 1.0;
    }
    return _gridCleared / _grid.length;
  }

  void _markGrid(Offset local, Size size, double radius) {
    if (!widget.trackRevealProgress) {
      return;
    }
    final n = widget.progressGridResolution;
    final cellW = size.width / n;
    final cellH = size.height / n;
    final r = radius;
    final minCx = ((local.dx - r) / cellW).floor().clamp(0, n - 1);
    final maxCx = ((local.dx + r) / cellW).ceil().clamp(0, n - 1);
    final minCy = ((local.dy - r) / cellH).floor().clamp(0, n - 1);
    final maxCy = ((local.dy + r) / cellH).ceil().clamp(0, n - 1);
    for (var cy = minCy; cy <= maxCy; cy++) {
      for (var cx = minCx; cx <= maxCx; cx++) {
        final idx = cy * n + cx;
        if (_grid[idx]) {
          continue;
        }
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
    if (!widget.trackRevealProgress) {
      return;
    }
    final f = _fraction();
    widget.onRevealProgress?.call(f);
    if (!_thresholdReported && f >= widget.revealThreshold) {
      _thresholdReported = true;
      if (widget.hapticFeedbackOnThreshold) {
        HapticFeedback.mediumImpact();
      }
      widget.onThresholdReached?.call(f);
      _runCompletionEffects();
    }
  }

  Future<void> _runCompletionEffects() async {
    if (_completionEffectsDone || !mounted) {
      return;
    }
    _completionEffectsDone = true;

    if (widget.playConfettiOnThreshold) {
      setState(() {
        _celebrationSession++;
        _celebrationVisible = true;
      });
    }

    if (widget.playSoundOnCompletion && _audioPlayer != null) {
      try {
        if (widget.completionSoundUrl != null) {
          await _audioPlayer!.play(UrlSource(widget.completionSoundUrl!));
        } else if (widget.completionSoundAsset != null) {
          await _audioPlayer!.play(AssetSource(widget.completionSoundAsset!));
        }
      } catch (_) {
        // Missing asset or network — ignore so the widget still works.
      }
    }
  }

  ScratchDetails _details(Offset local) {
    return ScratchDetails(
      localPosition: local,
      pointerCount: _activePointers,
      estimatedRevealFraction: widget.trackRevealProgress ? _fraction() : null,
    );
  }

  void _appendStrokePoint(Offset local) {
    if (_fullyRevealed) {
      return;
    }
    _scratchPath.lineTo(local.dx, local.dy);
    _scratchPathRevision++;
    _markGrid(local, _lastSize ?? Size.zero, widget.brushRadius);
  }

  void _handlePointerDown(PointerDownEvent e) {
    if (!widget.enabled || _fullyRevealed) {
      return;
    }
    _activePointers++;
    if (_activePointers == 1) {
      if (widget.hapticFeedbackOnStart) {
        HapticFeedback.selectionClick();
      }
      final local = e.localPosition;
      _scratchPath.moveTo(local.dx, local.dy);
      _scratchPathRevision++;

      final box = context.findRenderObject() as RenderBox?;
      final size = box?.size;
      if (size != null) {
        _lastSize = size;
        _markGrid(local, size, widget.brushRadius);
      }
      widget.onScratchStart?.call(_details(local));
      _emitProgress();
      setState(() {});
    }
  }

  void _handlePointerMove(PointerMoveEvent e) {
    if (!widget.enabled || _activePointers == 0 || _fullyRevealed) {
      return;
    }
    final local = e.localPosition;
    _appendStrokePoint(local);

    final box = context.findRenderObject() as RenderBox?;
    final size = box?.size;
    if (size != null) {
      _lastSize = size;
    }
    widget.onScratchUpdate?.call(_details(local));
    _emitProgress();
    setState(() {});
  }

  void _handlePointerUp(PointerUpEvent e) {
    if (_activePointers == 0) {
      return;
    }
    _activePointers--;
    final local = e.localPosition;
    if (_activePointers == 0) {
      widget.onScratchEnd?.call(_details(local));
    }
    setState(() {});
  }

  void _handlePointerCancel(PointerCancelEvent e) {
    if (_activePointers == 0) {
      return;
    }
    _activePointers--;
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

    final effectiveGradient =
        widget.overlayGradient ?? (widget.overlayColor == null ? gradient : null);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(
          constraints.maxWidth,
          constraints.maxHeight,
        );
        if (_lastSize != size && size.width > 0 && size.height > 0) {
          _lastSize = size;
        }

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
                      painter: ScratchPainter(
                        borderRadius: widget.borderRadius,
                        path: _scratchPath,
                        scratchPathRevision: _scratchPathRevision,
                        brushRadius: widget.brushRadius,
                        overlayColor: widget.overlayImage != null ? null : widget.overlayColor,
                        overlayGradient: widget.overlayImage != null ? null : effectiveGradient,
                        overlayImage: _resolvedOverlayImage,
                        overlayImageFit: widget.overlayImageFit,
                        brushTextureImage: _resolvedBrushTexture,
                        brushTextureLoading:
                            widget.brushTexture != null && _resolvedBrushTexture == null,
                        fullyRevealed: _fullyRevealed,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (widget.playConfettiOnThreshold && _celebrationVisible)
              Positioned.fill(
                child: IgnorePointer(
                  child: ScratchCelebrationOverlay(
                    key: ValueKey<int>(_celebrationSession),
                    areaSize: size,
                    particleCount: widget.confettiParticleCount,
                    confettiDuration: widget.confettiDuration,
                    confettiMinChipSize: widget.confettiMinChipSize,
                    confettiMaxChipSize: widget.confettiMaxChipSize,
                    onEnded: () {
                      if (mounted) {
                        setState(() => _celebrationVisible = false);
                      }
                    },
                  ),
                ),
              ),
            if (_shouldShowRevealAssistButton)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Padding(
                  padding: widget.revealAssistPadding,
                  child: Center(
                    child: Semantics(
                      button: true,
                      label: _revealAssistEffectiveLabel,
                      child: FilledButton.tonal(
                        onPressed: _fullyRevealed ? null : _revealAll,
                        child: Text(_revealAssistEffectiveLabel),
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
