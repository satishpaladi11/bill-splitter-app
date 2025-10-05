import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simplify_split/screens/reports_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReportsScreen', () {
    testWidgets('shows empty state message', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ReportsScreen(),
        ),
      );
      expect(find.text('Reports will be shown here'), findsOneWidget);
    });
  });
}
