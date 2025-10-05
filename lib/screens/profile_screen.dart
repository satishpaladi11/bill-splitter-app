import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'profile_setup_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late String userName;
  late int avatarIndex;
  final List<String> avatars = [
    "😀","😎","🧸","👩‍💻","🧑‍🎨","🐱","🐶","🐼","🐸","🐵",
    "🦊","🐯","🦁","🐰","🐨","🐧","🐢","🐬","🐳","🦄",
  ];

  void _loadProfile() {
    final profileBox = Hive.box('profile');
    userName = profileBox.get('name', defaultValue: "Unknown User");
    avatarIndex = profileBox.get('avatarIndex', defaultValue: 0);
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.indigo,
              child: Text(
                avatars[avatarIndex],
                style: const TextStyle(fontSize: 48),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              userName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "This is your saved profile",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProfileSetupScreen(isEditing: true),
                  ),
                );
                if (result == true) {
                  setState(() {
                    _loadProfile();
                  });
                }
              },
              icon: const Icon(Icons.edit),
              label: const Text("Edit Profile"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            )
          ],
        ),
      ),
    );
  }
}
