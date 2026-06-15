import 'package:debt_advanced/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Debt Advanced starts', (tester) async {
    await tester.pumpWidget(const DebtAdvancedApp());
    expect(find.text('دفتر الديون المتقدم'), findsOneWidget);
  });
}
