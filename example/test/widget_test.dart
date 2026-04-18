import 'package:flutter_test/flutter_test.dart';

import 'package:scratch_to_win_example/main.dart';

void main() {
  testWidgets('example app builds', (WidgetTester tester) async {
    await tester.pumpWidget(const ScratchToWinExampleApp());

    expect(find.text('scratch_to_win lab'), findsOneWidget);
  });
}
