import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:scratch_to_win/scratch_to_win.dart';

void main() {
  testWidgets('ScratchToWin stacks overlay above child', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 200,
              height: 120,
              child: ScratchToWin(
                child: Text('secret', key: Key('secret')),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('secret')), findsOneWidget);
  });

  testWidgets('controller revealAll updates progress notifier', (tester) async {
    final controller = ScratchToWinController();
    addTearDown(controller.dispose);

    var soundCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 200,
              height: 120,
              child: ScratchToWin(
                controller: controller,
                revealThreshold: 0.5,
                onCompletionSound: () async {
                  soundCalls++;
                },
                child: const Text('prize'),
              ),
            ),
          ),
        ),
      ),
    );

    expect(controller.revealProgress.value, 0);
    controller.revealAll();
    await tester.pump();

    expect(controller.revealProgress.value, 1);
    expect(soundCalls, 1);
    expect(find.text('prize'), findsOneWidget);
  });

  testWidgets('empty reveal assist label hides button', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 200,
              height: 120,
              child: ScratchToWin(
                showRevealAssistButton: true,
                revealAssistButtonLabel: '',
                child: Text('hidden'),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(FilledButton), findsNothing);
  });
}
