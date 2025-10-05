import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:simplify_split/screens/group_details_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GroupDetailsScreen', () {
    testWidgets('renders group name and empty states', (WidgetTester tester) async {
      // Setup Hive mock
      await Hive.initFlutter();
      var box = await Hive.openBox('groups');
      var appBox = await Hive.openBox('appState');
      box.put('test-group', {
        'name': 'Test Group',
        'members': [],
        'expenses': [],
      });
      await tester.pumpWidget(
        MaterialApp(
          home: GroupDetailsScreen(groupId: 'test-group'),
        ),
      );
      expect(find.text('Test Group'), findsOneWidget);
      expect(find.text('No members yet!'), findsOneWidget);
      expect(find.text('No expenses yet!'), findsOneWidget);
    });
  });
}
