import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:simplify_split/screens/profile_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ProfileScreen', () {
    testWidgets('shows profile info and edit button', (WidgetTester tester) async {
      await Hive.initFlutter();
      var box = await Hive.openBox('profile');
      box.put('profile', {
        'name': 'Test User',
        'avatarIndex': 1,
      });
      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(),
        ),
      );
      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('Edit Profile'), findsOneWidget);
    });
  });
}
