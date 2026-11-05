import 'package:flutter_test/flutter_test.dart';
import 'package:signal_zero/main.dart';

void main() {
  testWidgets('guest can open foundation shell without account or network', (
    tester,
  ) async {
    await tester.pumpWidget(const SignalZeroApp());
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('SIGNAL ZERO'), findsOneWidget);
    expect(find.text('Fondasi Flutter + Flame'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
