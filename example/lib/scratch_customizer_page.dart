import 'package:flutter/material.dart';
import 'package:scratch_to_win/scratch_to_win.dart';

/// Interactive panel for every [ScratchToWin] option — add new knobs here when the API grows.
class ScratchCustomizerPage extends StatefulWidget {
  const ScratchCustomizerPage({super.key});

  @override
  State<ScratchCustomizerPage> createState() => _ScratchCustomizerPageState();
}

enum _SurfaceMode { packageDefault, solid, gradient, image }

class _ScratchCustomizerPageState extends State<ScratchCustomizerPage> {
  final ScratchToWinController _controller = ScratchToWinController();

  // --- Surface & frame ---
  _SurfaceMode _surfaceMode = _SurfaceMode.image;
  Color _solidColor = const Color(0xFF607D8B);
  Color _gradientA = const Color(0xFF5C6BC0);
  Color _gradientB = const Color(0xFFFFB74D);
  final TextEditingController _overlayImageUrl = TextEditingController(
    text: 'https://picsum.photos/seed/scratchcard/800/600',
  );
  BoxFit _overlayImageFit = BoxFit.cover;
  double _borderRadius = 16;

  // --- Child (prize) ---
  final TextEditingController _prizeText = TextEditingController(text: 'You won!');

  // --- Brush ---
  double _brushRadius = 24;
  bool _useBrushTexture = true;
  final TextEditingController _brushTextureUrl = TextEditingController(
    text: 'https://picsum.photos/seed/scratchbrush/128/128',
  );

  // --- Progress & threshold ---
  bool _trackRevealProgress = true;
  double _revealThreshold = 0.55;
  double _progressGridResolution = 28;

  // --- Interaction ---
  bool _scratchEnabled = true;
  bool _hapticFeedbackOnStart = true;
  bool _hapticFeedbackOnThreshold = true;

  // --- Completion ---
  bool _playConfettiOnThreshold = true;
  double _confettiParticles = 24;

  bool _playSoundOnCompletion = false;
  final TextEditingController _completionSoundAsset = TextEditingController();
  final TextEditingController _completionSoundUrl = TextEditingController();

  // --- Reveal assist ---
  bool _showRevealAssistButton = true;
  final TextEditingController _revealAssistLabel = TextEditingController(text: 'Reveal prize');
  double _assistPadLeft = 0;
  double _assistPadRight = 0;
  double _assistPadTop = 0;
  double _assistPadBottom = 12;

  // --- Callback logging ---
  bool _logCallbacks = true;
  bool _logMoveEvents = false;
  int _moveLogCounter = 0;
  final List<String> _eventLog = <String>[];

  // --- Live state ---
  double _progress = 0;
  bool _thresholdHit = false;

  @override
  void dispose() {
    _overlayImageUrl.dispose();
    _brushTextureUrl.dispose();
    _prizeText.dispose();
    _completionSoundAsset.dispose();
    _completionSoundUrl.dispose();
    _revealAssistLabel.dispose();
    super.dispose();
  }

  void _log(String line) {
    if (!_logCallbacks) {
      return;
    }
    final ts = TimeOfDay.now().format(context);
    setState(() {
      _eventLog.insert(0, '$ts · $line');
      if (_eventLog.length > 48) {
        _eventLog.removeLast();
      }
    });
  }

  void _resetScratchState() {
    _controller.reset();
    setState(() {
      _progress = 0;
      _thresholdHit = false;
      _moveLogCounter = 0;
    });
    _log('reset()');
  }

  void _restoreDefaults() {
    setState(() {
      _surfaceMode = _SurfaceMode.image;
      _solidColor = const Color(0xFF607D8B);
      _gradientA = const Color(0xFF5C6BC0);
      _gradientB = const Color(0xFFFFB74D);
      _overlayImageUrl.text = 'https://picsum.photos/seed/scratchcard/800/600';
      _overlayImageFit = BoxFit.cover;
      _borderRadius = 16;
      _prizeText.text = 'You won!';
      _brushRadius = 24;
      _useBrushTexture = true;
      _brushTextureUrl.text = 'https://picsum.photos/seed/scratchbrush/128/128';
      _trackRevealProgress = true;
      _revealThreshold = 0.55;
      _progressGridResolution = 28;
      _scratchEnabled = true;
      _hapticFeedbackOnStart = true;
      _hapticFeedbackOnThreshold = true;
      _playConfettiOnThreshold = true;
      _confettiParticles = 24;
      _playSoundOnCompletion = false;
      _completionSoundAsset.clear();
      _completionSoundUrl.clear();
      _showRevealAssistButton = true;
      _revealAssistLabel.text = 'Reveal prize';
      _assistPadLeft = 0;
      _assistPadRight = 0;
      _assistPadTop = 0;
      _assistPadBottom = 12;
    });
    _resetScratchState();
  }

  Color? get _overlayColor {
    switch (_surfaceMode) {
      case _SurfaceMode.packageDefault:
      case _SurfaceMode.gradient:
      case _SurfaceMode.image:
        return null;
      case _SurfaceMode.solid:
        return _solidColor;
    }
  }

  Gradient? get _overlayGradient {
    switch (_surfaceMode) {
      case _SurfaceMode.gradient:
        return LinearGradient(colors: [_gradientA, _gradientB]);
      case _SurfaceMode.packageDefault:
      case _SurfaceMode.solid:
      case _SurfaceMode.image:
        return null;
    }
  }

  ImageProvider? get _overlayImage {
    if (_surfaceMode != _SurfaceMode.image) {
      return null;
    }
    final url = _overlayImageUrl.text.trim();
    if (url.isEmpty) {
      return null;
    }
    return NetworkImage(url);
  }

  ImageProvider? get _brushTexture {
    if (!_useBrushTexture) {
      return null;
    }
    final url = _brushTextureUrl.text.trim();
    if (url.isEmpty) {
      return null;
    }
    return NetworkImage(url);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderRadius = BorderRadius.circular(_borderRadius);
    final gridRes = _progressGridResolution.round().clamp(4, 96);

    final soundConfigured = _completionSoundAsset.text.trim().isNotEmpty ||
        _completionSoundUrl.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('scratch_to_win lab'),
        actions: [
          IconButton(
            tooltip: 'Restore default options',
            onPressed: _restoreDefaults,
            icon: const Icon(Icons.settings_backup_restore),
          ),
          IconButton(
            tooltip: 'Reset scratch layer',
            onPressed: _resetScratchState,
            icon: const Icon(Icons.restart_alt),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              'Progress ${_progressPercent()} · threshold ${_thresholdHit ? "hit" : "open"}',
              style: theme.textTheme.titleMedium,
            ),
          ),
          if (_playSoundOnCompletion && !soundConfigured)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Sound is on but no asset or URL is set — add one below or turn sound off.',
                          style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _playSoundOnCompletion = false),
                        child: const Text('Turn off'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          SizedBox(
            height: 280,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: borderRadius,
                child: ScratchToWin(
                  key: ValueKey<int>(
                    Object.hash(
                      _surfaceMode,
                      _solidColor.toARGB32(),
                      _gradientA.toARGB32(),
                      _gradientB.toARGB32(),
                      _overlayImageUrl.text,
                    ),
                  ),
                  controller: _controller,
                  borderRadius: borderRadius,
                  overlayColor: _overlayColor,
                  overlayGradient: _overlayGradient,
                  overlayImage: _overlayImage,
                  overlayImageFit: _overlayImageFit,
                  brushRadius: _brushRadius,
                  brushTexture: _brushTexture,
                  revealThreshold: _revealThreshold,
                  trackRevealProgress: _trackRevealProgress,
                  progressGridResolution: gridRes,
                  hapticFeedbackOnStart: _hapticFeedbackOnStart,
                  hapticFeedbackOnThreshold: _hapticFeedbackOnThreshold,
                  enabled: _scratchEnabled,
                  playConfettiOnThreshold: _playConfettiOnThreshold,
                  confettiParticleCount: _confettiParticles.round().clamp(1, 120),
                  playSoundOnCompletion: _playSoundOnCompletion,
                  completionSoundAsset: _nullableAsset(_completionSoundAsset.text),
                  completionSoundUrl: _nullableUrl(_completionSoundUrl.text),
                  showRevealAssistButton: _showRevealAssistButton,
                  revealAssistButtonLabel: _revealAssistLabel.text.trim().isEmpty
                      ? 'Reveal'
                      : _revealAssistLabel.text.trim(),
                  revealAssistPadding: EdgeInsets.only(
                    left: _assistPadLeft,
                    right: _assistPadRight,
                    top: _assistPadTop,
                    bottom: _assistPadBottom,
                  ),
                  onScratchStart: (d) => _log('onScratchStart (${d.pointerCount} pointers)'),
                  onScratchUpdate: (d) {
                    if (!_logMoveEvents) {
                      return;
                    }
                    _moveLogCounter++;
                    if (_moveLogCounter % 12 == 0) {
                      _log('onScratchUpdate ~${(d.estimatedRevealFraction ?? 0).toStringAsFixed(2)}');
                    }
                  },
                  onScratchEnd: (d) {
                    _moveLogCounter = 0;
                    _log('onScratchEnd');
                  },
                  onScratchCancel: (d) => _log('onScratchCancel'),
                  onRevealProgress: (f) {
                    setState(() => _progress = f);
                    if (_logMoveEvents) {
                      return;
                    }
                  },
                  onThresholdReached: (f) {
                    setState(() => _thresholdHit = true);
                    _log('onThresholdReached (${f.toStringAsFixed(3)})');
                  },
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.amber.shade100,
                          Colors.orange.shade50,
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.emoji_events, size: 56, color: Colors.amber.shade800),
                        const SizedBox(height: 8),
                        Text(
                          _prizeText.text.isEmpty ? 'Prize' : _prizeText.text,
                          style: theme.textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                _section(
                  context,
                  title: 'Surface & frame',
                  children: [
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Scratch surface',
                        border: OutlineInputBorder(),
                        helperText: 'Default uses the package’s built‑in grey gradient.',
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<_SurfaceMode>(
                          isExpanded: true,
                          value: _surfaceMode,
                          items: const [
                            DropdownMenuItem(
                              value: _SurfaceMode.packageDefault,
                              child: Text('Package default gradient'),
                            ),
                            DropdownMenuItem(
                              value: _SurfaceMode.solid,
                              child: Text('Solid color'),
                            ),
                            DropdownMenuItem(
                              value: _SurfaceMode.gradient,
                              child: Text('Two‑color gradient'),
                            ),
                            DropdownMenuItem(
                              value: _SurfaceMode.image,
                              child: Text('Network image'),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _surfaceMode = v);
                            }
                          },
                        ),
                      ),
                    ),
                    if (_surfaceMode == _SurfaceMode.solid) ...[
                      const SizedBox(height: 8),
                      _colorTile('Solid color', _solidColor, (c) => setState(() => _solidColor = c)),
                    ],
                    if (_surfaceMode == _SurfaceMode.gradient) ...[
                      const SizedBox(height: 8),
                      _colorTile('Gradient A', _gradientA, (c) => setState(() => _gradientA = c)),
                      _colorTile('Gradient B', _gradientB, (c) => setState(() => _gradientB = c)),
                    ],
                    if (_surfaceMode == _SurfaceMode.image) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: _overlayImageUrl,
                        decoration: const InputDecoration(
                          labelText: 'Overlay image URL',
                          border: OutlineInputBorder(),
                          helperText: 'HTTPS network image; empty falls back to non-image modes',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                    const SizedBox(height: 8),
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Overlay image fit',
                        border: OutlineInputBorder(),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<BoxFit>(
                          isExpanded: true,
                          value: _overlayImageFit,
                          items: BoxFit.values
                              .map((f) => DropdownMenuItem(value: f, child: Text(f.name)))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _overlayImageFit = v);
                            }
                          },
                        ),
                      ),
                    ),
                    _sliderTile(
                      'Corner radius',
                      _borderRadius,
                      0,
                      48,
                      (v) => setState(() => _borderRadius = v),
                    ),
                    TextField(
                      controller: _prizeText,
                      decoration: const InputDecoration(
                        labelText: 'Prize text (child)',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
                _section(
                  context,
                  title: 'Brush',
                  children: [
                    _sliderTile(
                      'Brush radius (round stroke)',
                      _brushRadius,
                      4,
                      72,
                      (v) => setState(() => _brushRadius = v),
                    ),
                    SwitchListTile(
                      title: const Text('Brush texture (network image)'),
                      subtitle: const Text('Fully opaque pixels erase; empty URL disables.'),
                      value: _useBrushTexture,
                      onChanged: (v) => setState(() => _useBrushTexture = v),
                    ),
                    if (_useBrushTexture)
                      TextField(
                        controller: _brushTextureUrl,
                        decoration: const InputDecoration(
                          labelText: 'Brush texture URL',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                  ],
                ),
                _section(
                  context,
                  title: 'Progress & threshold',
                  children: [
                    SwitchListTile(
                      title: const Text('Track reveal progress'),
                      subtitle: const Text('Off disables grid, progress, and threshold.'),
                      value: _trackRevealProgress,
                      onChanged: (v) => setState(() => _trackRevealProgress = v),
                    ),
                    _sliderTile(
                      'Reveal threshold',
                      _revealThreshold,
                      0.05,
                      1,
                      (v) => setState(() => _revealThreshold = v),
                    ),
                    _sliderTile(
                      'Progress grid resolution',
                      _progressGridResolution,
                      8,
                      64,
                      (v) => setState(() => _progressGridResolution = v),
                      valueLabel: (v) => v.round().toString(),
                      helperText:
                          'Scratch area is split into n×n cells; progress ≈ cleared cells / n². '
                          'Higher n = smoother estimate, slightly more work. Try 24–32.',
                    ),
                  ],
                ),
                _section(
                  context,
                  title: 'Interaction',
                  children: [
                    SwitchListTile(
                      title: const Text('Scratch layer enabled'),
                      subtitle: const Text('Off lets taps pass through to the child.'),
                      value: _scratchEnabled,
                      onChanged: (v) => setState(() => _scratchEnabled = v),
                    ),
                    SwitchListTile(
                      title: const Text('Haptic on scratch start'),
                      value: _hapticFeedbackOnStart,
                      onChanged: (v) => setState(() => _hapticFeedbackOnStart = v),
                    ),
                    SwitchListTile(
                      title: const Text('Haptic on threshold'),
                      value: _hapticFeedbackOnThreshold,
                      onChanged: (v) => setState(() => _hapticFeedbackOnThreshold = v),
                    ),
                  ],
                ),
                _section(
                  context,
                  title: 'Completion effects',
                  children: [
                    SwitchListTile(
                      title: const Text('Confetti on threshold / reveal all'),
                      subtitle: const Text(
                        'Particles spread across the full card (rain + sparkle), then fade.',
                      ),
                      value: _playConfettiOnThreshold,
                      onChanged: (v) => setState(() => _playConfettiOnThreshold = v),
                    ),
                    _sliderTile(
                      'Confetti particle count',
                      _confettiParticles,
                      1,
                      80,
                      (v) => setState(() => _confettiParticles = v),
                      valueLabel: (v) => v.round().toString(),
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: const Text('Play completion sound'),
                      subtitle: const Text('URL takes precedence over asset path.'),
                      value: _playSoundOnCompletion,
                      onChanged: (v) => setState(() => _playSoundOnCompletion = v),
                    ),
                    TextField(
                      controller: _completionSoundAsset,
                      decoration: const InputDecoration(
                        labelText: 'Asset path (host app pubspec)',
                        hintText: 'assets/sounds/win.mp3',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    TextField(
                      controller: _completionSoundUrl,
                      decoration: const InputDecoration(
                        labelText: 'Sound URL',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
                _section(
                  context,
                  title: 'Reveal assist',
                  children: [
                    SwitchListTile(
                      title: const Text('Show assist button'),
                      value: _showRevealAssistButton,
                      onChanged: (v) => setState(() => _showRevealAssistButton = v),
                    ),
                    TextField(
                      controller: _revealAssistLabel,
                      decoration: const InputDecoration(
                        labelText: 'Button label',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    _sliderTile('Assist padding left', _assistPadLeft, 0, 32, (v) {
                      setState(() => _assistPadLeft = v);
                    }),
                    _sliderTile('Assist padding right', _assistPadRight, 0, 32, (v) {
                      setState(() => _assistPadRight = v);
                    }),
                    _sliderTile('Assist padding top', _assistPadTop, 0, 32, (v) {
                      setState(() => _assistPadTop = v);
                    }),
                    _sliderTile('Assist padding bottom', _assistPadBottom, 0, 48, (v) {
                      setState(() => _assistPadBottom = v);
                    }),
                  ],
                ),
                _section(
                  context,
                  title: 'Callback log',
                  children: [
                    SwitchListTile(
                      title: const Text('Log callbacks'),
                      value: _logCallbacks,
                      onChanged: (v) => setState(() => _logCallbacks = v),
                    ),
                    SwitchListTile(
                      title: const Text('Verbose move logging'),
                      subtitle: const Text('Logs throttled onScratchUpdate samples.'),
                      value: _logMoveEvents,
                      onChanged: (v) => setState(() => _logMoveEvents = v),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => setState(_eventLog.clear),
                        child: const Text('Clear log'),
                      ),
                    ),
                    ..._eventLog.map(
                      (e) => SelectableText(e, style: theme.textTheme.bodySmall),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Tip: when you add new ScratchToWin fields, wire them in '
                    'scratch_customizer_page.dart so this lab stays complete.',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _progressPercent() => '${(_progress * 100).clamp(0, 100).toStringAsFixed(0)}%';

  Widget _section(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return ExpansionTile(
      initiallyExpanded: title == 'Surface & frame',
      title: Text(title, style: Theme.of(context).textTheme.titleSmall),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _sliderTile(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged, {
    String Function(double value)? valueLabel,
    String? helperText,
  }) {
    final display = valueLabel?.call(value) ?? value.toStringAsFixed(2);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(display),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          onChanged: onChanged,
        ),
        if (helperText != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              helperText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
      ],
    );
  }

  Widget _colorTile(String label, Color current, ValueChanged<Color> onPick) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: GestureDetector(
        onTap: () async {
          final picked = await showDialog<Color>(
            context: context,
            builder: (ctx) => _SimpleColorDialog(initial: current),
          );
          if (picked != null) {
            onPick(picked);
          }
        },
        child: CircleAvatar(backgroundColor: current),
      ),
    );
  }

}

String? _nullableAsset(String raw) {
  final s = raw.trim();
  return s.isEmpty ? null : s;
}

String? _nullableUrl(String raw) {
  final s = raw.trim();
  return s.isEmpty ? null : s;
}

class _SimpleColorDialog extends StatefulWidget {
  const _SimpleColorDialog({required this.initial});

  final Color initial;

  @override
  State<_SimpleColorDialog> createState() => _SimpleColorDialogState();
}

class _SimpleColorDialogState extends State<_SimpleColorDialog> {
  late double _r;
  late double _g;
  late double _b;

  @override
  void initState() {
    super.initState();
    _r = widget.initial.r;
    _g = widget.initial.g;
    _b = widget.initial.b;
  }

  Color get _color => Color.fromARGB(
        255,
        (_r * 255.0).round().clamp(0, 255),
        (_g * 255.0).round().clamp(0, 255),
        (_b * 255.0).round().clamp(0, 255),
      );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pick color'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text('R ${_r.toStringAsFixed(2)}'),
                Expanded(
                  child: Slider(value: _r, onChanged: (v) => setState(() => _r = v)),
                ),
              ],
            ),
            Row(
              children: [
                Text('G ${_g.toStringAsFixed(2)}'),
                Expanded(
                  child: Slider(value: _g, onChanged: (v) => setState(() => _g = v)),
                ),
              ],
            ),
            Row(
              children: [
                Text('B ${_b.toStringAsFixed(2)}'),
                Expanded(
                  child: Slider(value: _b, onChanged: (v) => setState(() => _b = v)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            CircleAvatar(radius: 28, backgroundColor: _color),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, _color), child: const Text('Use')),
      ],
    );
  }
}
