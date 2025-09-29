import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/add_expense_screen.dart';
import 'screens/group_details_screen.dart'; // import for GroupDetailsScreen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('groups');
  await Hive.openBox('appState'); // box to store last visited screen
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  Future<Widget> _getInitialScreen() async {
    final appBox = Hive.box('appState');
    final lastScreen = appBox.get('lastScreen', defaultValue: 'home');
    if (lastScreen == 'group') {
      final lastGroupId = appBox.get('lastGroupId') as String?;
      if (lastGroupId != null) {
        return GroupDetailsScreen(groupId: lastGroupId);
      }
    }
    return const HomeScreen();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _getInitialScreen(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: MainScreen(initialScreen: snapshot.data!),
          );
        }
        // Splash/loading while deciding initial screen
        return const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(body: Center(child: CircularProgressIndicator())),
        );
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  final Widget initialScreen;
  const MainScreen({Key? key, required this.initialScreen}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeScreen(),
      const PlaceholderWidget(label: "Select a group first"), // Activity placeholder
      const ReportsScreen(),
      const ProfileScreen(),
    ];

    // Determine initial selected index based on initialScreen
    if (widget.initialScreen is HomeScreen) {
      _selectedIndex = 0;
    } else if (widget.initialScreen is GroupDetailsScreen) {
      // For group details, we can show home as selected and navigate immediately
      _selectedIndex = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => widget.initialScreen),
        );
      });
    }
  }

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
