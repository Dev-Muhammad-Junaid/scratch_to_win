import 'package:flutter/material.dart';
import 'package:scratch_to_win/scratch_to_win.dart';

void main() {
  runApp(const ScratchToWinExampleApp());
}

class ScratchToWinExampleApp extends StatelessWidget {
  const ScratchToWinExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'scratch_to_win example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const DemoPage(),
    );
  }
}

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  final ScratchToWinController _controller = ScratchToWinController();
  double _progress = 0;
  bool _thresholdHit = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('scratch_to_win')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Scratch the card to reveal the prize.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Progress: ${(_progress * 100).toStringAsFixed(0)}% · '
              'Threshold: ${_thresholdHit ? "reached" : "not yet"}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1.2,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: ScratchToWin(
                      controller: _controller,
                      borderRadius: BorderRadius.circular(16),
                      brushRadius: 26,
                      revealThreshold: 0.5,
                      onRevealProgress: (f) => setState(() => _progress = f),
                      onThresholdReached: (_) => setState(() => _thresholdHit = true),
                      onScratchStart: (_) {},
                      child: Container(
                        alignment: Alignment.center,
                        color: Colors.amber.shade100,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.emoji_events, size: 56, color: Colors.amber.shade800),
                            const SizedBox(height: 8),
                            Text(
                              'You won!',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                _controller.reset();
                setState(() {
                  _progress = 0;
                  _thresholdHit = false;
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reset scratch card'),
            ),
          ],
        ),
      ),
    );
  }
}
