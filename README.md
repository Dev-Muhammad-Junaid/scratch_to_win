# scratch_to_win

[![CI](https://github.com/Dev-Muhammad-Junaid/scratch_to_win/actions/workflows/ci.yml/badge.svg)](https://github.com/Dev-Muhammad-Junaid/scratch_to_win/actions/workflows/ci.yml)
[![style: flutter lints](https://img.shields.io/badge/style-flutter__lints-blue.svg)](https://pub.dev/packages/flutter_lints)

Flutter widget: a scratch-off layer on top of any child. Drag to reveal what is underneath. Pointer lifecycle callbacks and an optional grid-based estimate of cleared area (for thresholds and win logic).

## Install

```yaml
dependencies:
  scratch_to_win: ^0.0.1
```

*(Not yet on pub.dev — use a [git dependency](https://dart.dev/tools/pub/dependencies#git-packages) until you publish.)*

## Quick start

```dart
ScratchToWin(
  child: Center(child: Text('You won!')),
  onRevealProgress: (f) => debugPrint('cleared: $f'),
  onThresholdReached: (f) => debugPrint('threshold at $f'),
)
```

## API overview

| Area | Details |
|------|---------|
| Callbacks | `onScratchStart`, `onScratchUpdate`, `onScratchEnd`, `onScratchCancel`, `onRevealProgress`, `onThresholdReached` |
| Brush | `ScratchBrushShape.round`, `.square`, `.dots`; `brushRadius` |
| Progress | `trackRevealProgress`, `progressGridResolution`, `revealThreshold` |
| Control | `ScratchToWinController.reset()`, `enabled` |
| Surface | `overlayColor`, `overlayGradient`, `borderRadius` |

Pure Flutter (no platform channels). Optional haptics on start and when the threshold is crossed.

## Example

```bash
git clone https://github.com/Dev-Muhammad-Junaid/scratch_to_win.git
cd scratch_to_win/example
flutter pub get
flutter run
```

## Development

```bash
flutter pub get
flutter analyze
flutter test
```

Publish checks: `dart pub publish --dry-run`. See [pub.dev scoring](https://pub.dev/help/scoring) for documentation and analysis expectations.

## License

MIT. See [LICENSE](LICENSE).
