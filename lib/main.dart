import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/add_expense_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('groups');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Using nullable/placeholder for screens that require a groupId
  late final List<Widget> _screens = [
    HomeScreen(), // Groups list
    const PlaceholderWidget(label: "Select a group first"), // Activity placeholder
    const ReportsScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  void _openAddExpense() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Select a group first to add expense")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddExpense,
        backgroundColor: Colors.indigo,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.group), label: "Groups"),
            BottomNavigationBarItem(icon: Icon(Icons.receipt), label: "Activity"),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Reports"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          ],
        ),
      ),
    );
  }
}

class PlaceholderWidget extends StatelessWidget {
  final String label;
  const PlaceholderWidget({Key? key, required this.label}) : super(key: key);

  @override
  Widget build(BuildContext context) => Center(child: Text(label));
}
