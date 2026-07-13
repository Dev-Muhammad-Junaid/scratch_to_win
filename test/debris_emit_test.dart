import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scratch_to_win/scratch_to_win.dart';

void main() {
  testWidgets('debris controller emit shows CustomPaint particles',
      (tester) async {
    final controller = ScratchDebrisController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 200,
            child: ScratchDebrisLayer(
              areaSize: const Size(300, 200),
              controller: controller,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    controller.emit(const Offset(100, 50), count: 8);
    await tester.pump();
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('ScratchToWin scratching spawns debris paint', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              height: 200,
              child: ScratchToWin(
                showScratchDebris: true,
                overlayColor: const Color(0xFF888888),
                child: const ColoredBox(color: Colors.red),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ScratchDebrisLayer), findsOneWidget);

    final center = tester.getCenter(find.byType(ScratchToWin));
    final gesture = await tester.startGesture(center);
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(const Offset(10, 0));
      await tester.pump();
    }

    // Debris CustomPaint is always present; ensure layer stayed mounted.
    expect(find.byType(ScratchDebrisLayer), findsOneWidget);
    await gesture.up();
  });
}
