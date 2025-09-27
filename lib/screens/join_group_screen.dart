// join_group_screen.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'group_details_screen.dart';

class JoinGroupScreen extends StatefulWidget {
  const JoinGroupScreen({Key? key}) : super(key: key);

  @override
  _JoinGroupScreenState createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();

  void _joinGroup() {
    final box = Hive.box('groups');
    final group = box.get(_codeController.text);

    if (group == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Group not found")),
      );
      return;
    }

    // Add member if not already present
    final name = _nameController.text;
    if (!group['members'].contains(name)) {
      group['members'].add(name);
      box.put(_codeController.text, group);
    }

    // Navigate to group details
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GroupDetailsScreen(groupId: _codeController.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Join Group")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: "Your Name"),
            ),
            TextField(
              controller: _codeController,
              decoration: InputDecoration(labelText: "Group Code"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _joinGroup,
              child: Text("Join Group"),
            ),
          ],
        ),
      ),
    );
  }
}
