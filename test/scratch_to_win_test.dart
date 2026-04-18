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
}
