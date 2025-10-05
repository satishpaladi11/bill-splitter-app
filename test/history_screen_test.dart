import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:simplify_split/screens/history_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HistoryScreen', () {
    testWidgets('shows empty state when no expenses', (WidgetTester tester) async {
      await Hive.initFlutter();
      var box = await Hive.openBox('groups');
      box.put('test-group', {
        'name': 'Test Group',
        'members': [
          {'name': 'Alice', 'avatarIndex': 0},
        ],
        'expenses': [],
      });
      await tester.pumpWidget(
        MaterialApp(
          home: HistoryScreen(groupId: 'test-group'),
        ),
      );
      expect(find.text('No expenses yet!'), findsOneWidget);
    });
  });
}
