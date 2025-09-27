import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.indigo,
              child: Icon(Icons.person, size: 60, color: Colors.white),
            ),
            SizedBox(height: 20),
            Text(
              "Your profile info will appear here",
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
