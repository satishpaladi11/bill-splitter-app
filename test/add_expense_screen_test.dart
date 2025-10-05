import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:simplify_split/screens/add_expense_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AddExpenseScreen', () {
    testWidgets('renders add expense form', (WidgetTester tester) async {
      await Hive.initFlutter();
      var box = await Hive.openBox('groups');
      box.put('test-group', {
        'name': 'Test Group',
        'members': [
          {'name': 'Alice', 'avatarIndex': 0},
          {'name': 'Bob', 'avatarIndex': 1},
        ],
        'expenses': [],
      });
      await tester.pumpWidget(
        MaterialApp(
          home: AddExpenseScreen(groupId: 'test-group'),
        ),
      );
      expect(find.text('Add Expense'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
      expect(find.text('Amount'), findsOneWidget);
    });
  });
}
