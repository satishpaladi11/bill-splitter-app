import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/home_screen.dart';
import 'screens/group_details_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('groups');
  await Hive.openBox('appState');
  await Hive.openBox('profile'); // box for storing user profile

  final profileBox = Hive.box('profile');
  final bool hasProfile = profileBox.containsKey('name');

  runApp(MyApp(showProfileSetup: !hasProfile));
}

class MyApp extends StatelessWidget {
  final bool showProfileSetup;
  const MyApp({super.key, required this.showProfileSetup});

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
            title: 'Simplify Split',
            theme: ThemeData(primarySwatch: Colors.indigo),
            home: showProfileSetup
                ? ProfileSetupScreen()
                : MainScreen(initialScreen: snapshot.data!),
          );
        }
        // Loading/splash while determining initial screen
        return const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        );
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  final Widget initialScreen;
  const MainScreen({super.key, required this.initialScreen});

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
      const HomeScreen(), // Groups
      const ProfileScreen(), // Profile
      const PlaceholderWidget(label: "Feedback"), // Feedback
    ];

    // Navigate to last visited screen if it's a GroupDetailsScreen
    if (widget.initialScreen is GroupDetailsScreen) {
      _selectedIndex = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => widget.initialScreen),
        );
      });
    } else {
      _selectedIndex = 0;
    }
  }

  // Navigation logic is handled by updating _selectedIndex, which switches the displayed screen.


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.group), label: "Groups"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          BottomNavigationBarItem(icon: Icon(Icons.feedback), label: "Feedback"),
        ],
      ),
    );
  }
}

class PlaceholderWidget extends StatelessWidget {
  final String label;
  const PlaceholderWidget({super.key, required this.label});

  @override
  Widget build(BuildContext context) => Center(child: Text(label));
}
