# scratch_to_win

[![CI](https://github.com/Dev-Muhammad-Junaid/scratch_to_win/actions/workflows/ci.yml/badge.svg)](https://github.com/Dev-Muhammad-Junaid/scratch_to_win/actions/workflows/ci.yml)
[![Pages](https://github.com/Dev-Muhammad-Junaid/scratch_to_win/actions/workflows/deploy_example_web.yml/badge.svg)](https://github.com/Dev-Muhammad-Junaid/scratch_to_win/actions/workflows/deploy_example_web.yml)
[![pub package](https://img.shields.io/pub/v/scratch_to_win.svg)](https://pub.dev/packages/scratch_to_win)
[![style: flutter lints](https://img.shields.io/badge/style-flutter__lints-blue.svg)](https://pub.dev/packages/flutter_lints)

*CI / Pages badges reflect the latest GitHub Actions run; if they look wrong on pub.dev, wait a few minutes and hard-refresh — image caches can lag.*

Flutter widget: a scratch-off layer on top of any child. Drag to reveal what is underneath. Pointer lifecycle callbacks and an optional grid-based estimate of cleared area (for thresholds and win logic).

## Install

```yaml
dependencies:
  scratch_to_win: ^0.2.4
```

## Try the interactive example

- **Live (web):** [GitHub Pages demo](https://dev-muhammad-junaid.github.io/scratch_to_win/) — enable **Settings → Pages → GitHub Actions** in this repo on first use; the **Deploy example (web)** workflow must succeed once.
- **In the package:** the published tarball includes the [`example/`](example/) Flutter project (interactive “lab” for every API option).
- On **pub.dev**, open the package’s repository link to browse `example/` online, or use your pub cache after `dart pub get`.

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
| Brush | Round stroke: `brushRadius`; optional `brushTexture` (`ImageProvider`) |
| Progress | `trackRevealProgress`, `progressGridResolution` (see class docs), `revealThreshold` |
| Control | `ScratchToWinController.reset()`, `revealAll()`, `enabled` |
| Surface | `overlayColor`, `overlayGradient`, `overlayImage`, `overlayImageFit`, `borderRadius` |
| Completion | `playConfettiOnThreshold`, `confettiParticleCount`, `confettiDuration`, `confettiMinChipSize`, `confettiMaxChipSize`; optional sound |
| Accessibility | `showRevealAssistButton`, `revealAssistButtonLabel` (`''` hides if switch on), `revealAssistPadding` |

Pure Flutter drawing for the scratch layer; built-in full-card confetti (no extra package). Optional [`audioplayers`](https://pub.dev/packages/audioplayers) for completion SFX. Optional haptics on start and when the threshold is crossed.

## Example (local)

```bash
git clone https://github.com/Dev-Muhammad-Junaid/scratch_to_win.git
cd scratch_to_win/example
flutter pub get
flutter run
```

See [example/README.md](example/README.md) for the lab app, web build, and pub.dev layout.

## Development

```bash
flutter pub get
flutter analyze
flutter test
```

Publish checks: `dart pub publish --dry-run`. See [pub.dev scoring](https://pub.dev/help/scoring) for documentation and analysis expectations.

## License

MIT. See [LICENSE](LICENSE).
