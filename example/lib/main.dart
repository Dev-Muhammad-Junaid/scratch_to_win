import 'package:flutter/material.dart';

import 'scratch_customizer_page.dart';

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
      home: const ScratchCustomizerPage(),
    );
  }
}
