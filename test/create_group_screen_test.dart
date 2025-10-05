import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:simplify_split/screens/create_group_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CreateGroupScreen', () {
    testWidgets('renders create group form', (WidgetTester tester) async {
      await Hive.initFlutter();
      await Hive.openBox('groups');
      await tester.pumpWidget(
        MaterialApp(
          home: CreateGroupScreen(),
        ),
      );
      expect(find.text('Create Group'), findsOneWidget);
      expect(find.text('Group Name'), findsOneWidget);
      expect(find.text('Add Member'), findsOneWidget);
    });
  });
}
