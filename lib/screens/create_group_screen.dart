// create_group_screen.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'dart:math';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({Key? key}) : super(key: key);

  @override
  _CreateGroupScreenState createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _controller = TextEditingController();

  void _createGroup() async {
    if (_controller.text.isEmpty) return;

    final box = Hive.box('groups');
    final groupId = Random().nextInt(999999).toString(); // simple code

    box.put(groupId, {
      'name': _controller.text,
      'groupId': groupId,
      'members': [/* initial members if any */],
      'expenses': [], // always initialize as empty list
    });

    Navigator.pop(context); // go back to HomeScreen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Create Group")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(labelText: "Group Name"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _createGroup,
              child: Text("Create Group"),
            ),
          ],
        ),
      ),
    );
  }
}
