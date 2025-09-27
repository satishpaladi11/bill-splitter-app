import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/home_screen.dart';
import 'screens/create_group_screen.dart';
import 'screens/join_group_screen.dart';
import 'screens/group_details_screen.dart';
import 'screens/add_expense_screen.dart';
import 'screens/history_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('groups'); // stores all groups offline
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Offline Money Split',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => HomeScreen(),
        '/create-group': (context) => CreateGroupScreen(),
        '/join-group': (context) => JoinGroupScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/group-details') {
          final args = settings.arguments as String; // groupId
          return MaterialPageRoute(
            builder: (context) => GroupDetailsScreen(groupId: args),
          );
        } else if (settings.name == '/add-expense') {
          final args = settings.arguments as String; // groupId
          return MaterialPageRoute(
            builder: (context) => AddExpenseScreen(groupId: args),
          );
        }
        return null;
      },
    );
  }
}
