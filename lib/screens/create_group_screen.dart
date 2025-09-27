// lib/screens/create_group_screen.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({Key? key}) : super(key: key);

  @override
  _CreateGroupScreenState createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _memberController = TextEditingController();
  final List<String> members = [];

  void _addMember(String name) {
    if (name.trim().isEmpty) return;
    setState(() {
      members.add(name.trim());
      _memberController.clear();
    });
  }

  void _createGroup() async {
    if (_groupNameController.text.trim().isEmpty || members.isEmpty) return;

    final box = Hive.box('groups');
    final groupId = const Uuid().v4();

    await box.put(groupId, {
      'groupId': groupId,
      'name': _groupNameController.text.trim(),
      'members': members,
      'expenses': [],
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Group")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _groupNameController,
              decoration: const InputDecoration(
                labelText: "Group Name",
                filled: true,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _memberController,
              decoration: InputDecoration(
                labelText: "Add Member",
                filled: true,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _addMember(_memberController.text),
                ),
              ),
              onSubmitted: _addMember,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: members
                  .map((m) => Chip(
                        label: Text(m),
                        onDeleted: () {
                          setState(() {
                            members.remove(m);
                          });
                        },
                      ))
                  .toList(),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _createGroup,
                child: const Text("Create Group"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  backgroundColor: Colors.blue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
