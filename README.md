# scratch_to_win

[![CI](https://github.com/Dev-Muhammad-Junaid/scratch_to_win/actions/workflows/ci.yml/badge.svg)](https://github.com/Dev-Muhammad-Junaid/scratch_to_win/actions/workflows/ci.yml)
[![Pages](https://github.com/Dev-Muhammad-Junaid/scratch_to_win/actions/workflows/deploy_example_web.yml/badge.svg)](https://github.com/Dev-Muhammad-Junaid/scratch_to_win/actions/workflows/deploy_example_web.yml)
[![pub package](https://img.shields.io/pub/v/scratch_to_win.svg)](https://pub.dev/packages/scratch_to_win)
[![style: flutter lints](https://img.shields.io/badge/style-flutter__lints-blue.svg)](https://pub.dev/packages/flutter_lints)

*CI / Pages badges reflect the latest GitHub Actions run; if they look wrong on pub.dev, wait a few minutes and hard-refresh — image caches can lag.*

Flutter scratch-off overlay: hide any widget, drag to reveal it, track progress, fire threshold callbacks, optional confetti and haptics. Pure Flutter painting — **no audio plugin dependency** (Web / WASM friendly).

## Install

```yaml
dependencies:
  scratch_to_win: ^0.3.1
```

## Platforms

Works on **Android, iOS, Web, Windows, macOS, and Linux**. Minimum Flutter **3.27** (uses `Color.withValues`). Tested against current stable (**3.44**).

## Try the interactive example

- **Live (web):** [GitHub Pages demo](https://dev-muhammad-junaid.github.io/scratch_to_win/)
- **In the package:** [`example/`](example/) is a full settings lab for every API option
- On **pub.dev**, open the repository link or copy `example/` from your pub cache after `dart pub get`

## Quick start

```dart
ScratchToWin(
  child: Center(child: Text('You won!')),
  playConfettiOnThreshold: true,
  onRevealProgress: (f) => debugPrint('cleared: $f'),
  onThresholdReached: (f) => debugPrint('threshold at $f'),
  // Play SFX in your app (keeps this package WASM-clean):
  onCompletionSound: () async {
    // await player.play(AssetSource('sounds/win.mp3'));
  },
)
```

## API overview

| Area | Details |
|------|---------|
| Callbacks | `onScratchStart`, `onScratchUpdate`, `onScratchEnd`, `onScratchCancel`, `onRevealProgress`, `onThresholdReached`, `onCompletionSound` |
| Brush | Round stroke: `brushRadius`; optional `brushTexture`; optional `showScratchDebris` (falling flakes while scraping) |
| Progress | `trackRevealProgress`, `progressGridResolution`, `revealThreshold`; `controller.revealProgress` (`ValueNotifier`) |
| Control | `ScratchToWinController.reset()`, `revealAll()`, `dispose()`, `enabled` |
| Surface | `overlayColor`, `overlayGradient`, `overlayImage`, `overlayImageFit`, `borderRadius` |
| Completion | `playConfettiOnThreshold`, `confettiParticleCount`, `confettiDuration`, `confettiMinChipSize`, `confettiMaxChipSize` |
| Accessibility | `showRevealAssistButton`, `revealAssistButtonLabel` (`''` hides if switch on), `revealAssistPadding` |

## Example (local)

```bash
git clone https://github.com/Dev-Muhammad-Junaid/scratch_to_win.git
cd scratch_to_win/example
flutter pub get
flutter run
```

See [example/README.md](example/README.md).

## Development

```bash
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos
flutter test
```

Publish checks: `dart pub publish --dry-run`.

## License

MIT. See [LICENSE](LICENSE).
