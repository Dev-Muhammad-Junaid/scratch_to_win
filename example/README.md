# scratch_to_win example — interactive lab

This app is a **full settings panel** for every public option on [`ScratchToWin`](../lib/src/scratch_to_win.dart): overlay surface, brush, progress, confetti, sound, reveal assist, and callback logging.

## Run locally

```bash
cd example
flutter pub get
flutter run            # pick a device, or use -d chrome / -d macos
```

Web:

```bash
flutter run -d chrome
```

## Live demo (GitHub Pages)

After [GitHub Pages](https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site#publishing-with-a-custom-github-actions-workflow) is enabled for this repository (**Settings → Pages → GitHub Actions**), the workflow **Deploy example (web)** publishes the same UI:

**https://dev-muhammad-junaid.github.io/scratch_to_win/**

*(Replace the hostname with your own GitHub Pages URL if you fork the repo.)*

## pub.dev

The published package on [pub.dev](https://pub.dev/packages/scratch_to_win) ships this `example/` folder inside the package archive. After you add `scratch_to_win` to a project and run `dart pub get`, you can copy the `example/` tree from your pub cache (…`hosted/pub.dev/scratch_to_win-<version>/example/`) or clone this repository. The pub.dev package page also links to the repository for browsing source online.
