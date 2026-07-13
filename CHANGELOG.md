## 0.3.0

* **Scratch debris:** Optional **`showScratchDebris`** emits falling foil flakes along the brush while scratching for a more realistic scrape feel.
* **Breaking:** Removed the `audioplayers` dependency and the built-in sound fields (`playSoundOnCompletion`, `completionSoundAsset`, `completionSoundUrl`). Play completion SFX from your app via the new **`onCompletionSound`** callback — keeps the package Web/WASM-compatible and recovers pub.dev platform points.
* **SDK:** `sdk: '>=3.6.0 <4.0.0'`, `flutter: '>=3.27.0'` (required for `Color.withValues`); verified against Flutter **3.44** stable.
* **pubspec:** Shortened `description` (60–180 chars) to restore the missing convention points; kept `topics`.
* **Controller:** Documented constructor; added **`revealProgress`** (`ValueNotifier<double>`) and **`dispose()`**.
* **Scratch quality:** Interpolates pointer samples on fast strokes so the brush path does not leave gaps.
* **Docs / CI:** Platform section in README; CI runs `dart format` and `flutter analyze --fatal-infos`.

## 0.2.5

* **SDK constraints:** Fixed `sdk` from the invalid `^3.10.4` to `'>=3.6.0 <4.0.0'`; bumped minimum Flutter from `>=1.17.0` to `>=3.27.0` — required since `Color.withValues(alpha:)` (used internally) was introduced in Flutter 3.27.
* **pubspec:** Added `topics: [ui, animation, widget, game]` for better pub.dev discoverability; expanded description.
* **Docs:** Added field-level dartdoc comments to all `ScratchPainter` fields; moved the constructor inline comment on `scratchPathRevision` to a proper `///` doc.
* **CI:** Added `dart format --output=none --set-exit-if-changed` and `flutter analyze --fatal-infos` steps; added a dedicated `publish-dry-run` job.

## 0.2.4

* README: short note that GitHub Actions badges (and pub.dev’s copy of images) can lag behind a few minutes after CI goes green.

## 0.2.3

* **CI:** Removed steps for `simple_scratch_test` (directory was never in the repo). Added example `flutter test` and a **web build** smoke step so the interactive lab stays verified on Linux.
* **Docs:** README notes on pub.dev, the bundled `example/` lab, and the GitHub Pages live demo.
* **GitHub Actions:** New **Deploy example (web)** workflow publishing the example app to GitHub Pages (enable Pages with the “GitHub Actions” source).

## 0.2.2

* **Confetti:** Added `confettiDuration` (default **4s**, matching the old controller), `confettiMinChipSize` / `confettiMaxChipSize` (defaults **20×10** … **30×15**, matching legacy confetti widget chip bounds).
* **Brush:** Texture stamps are clipped to a **circle** so the scratch tip no longer looks square when using `brushTexture`.
* **Reveal assist:** `revealAssistButtonLabel` is now `String?`; empty string hides the button even when `showRevealAssistButton` is true (null still defaults the label to `Reveal`).

## 0.2.1

* Replaced the `confetti` package with a **built-in celebration overlay** so particles spawn across the **full width** of the card (rain from above + sparkle in the upper area) instead of clustering from one corner.

## 0.2.0

* **Simpler API:** Removed velocity-based brush, brush shape options (only round stroke), and confetti tuning except **`confettiParticleCount`**. Confetti uses an omnidirectional burst with built-in gravity and timing (rain-like).
* **Docs:** Expanded `progressGridResolution` documentation on [ScratchToWin].

## 0.1.0

* **Image overlay:** `overlayImage` + `overlayImageFit` to scratch off a bitmap instead of only color/gradient.
* **Brush texture:** `brushTexture` uses the image alpha (`BlendMode.dstOut`) for stamp-shaped erasing; shows plain clears while the image is still decoding.
* **Completion flair:** `playConfettiOnThreshold`, `confettiParticleCount`, and optional `playSoundOnCompletion` via `completionSoundAsset` or `completionSoundUrl` (`audioplayers`).
* **Reveal assist:** `showRevealAssistButton`, `revealAssistButtonLabel`, `revealAssistPadding`; `ScratchToWinController.revealAll()`.

## 0.0.1

* Initial release: `ScratchToWin` overlay with scratch gestures, progress estimate, threshold callback, haptics, and `ScratchToWinController` reset.
