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
