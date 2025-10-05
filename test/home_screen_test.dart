import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:simplify_split/screens/home_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HomeScreen', () {
    testWidgets('shows empty state and action buttons', (WidgetTester tester) async {
      await Hive.initFlutter();
      var box = await Hive.openBox('groups');
      box.clear();
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(),
        ),
      );
      expect(find.text('No groups yet!'), findsOneWidget);
      expect(find.text('Create Group'), findsOneWidget);
      expect(find.text('Join Group'), findsOneWidget);
    });
  });
}
