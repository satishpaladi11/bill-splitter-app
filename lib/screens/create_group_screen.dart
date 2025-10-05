// lib/screens/create_group_screen.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  _CreateGroupScreenState createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _memberController = TextEditingController();
  final List<Map<String, dynamic>> members = []; // store name + avatar

  @override
  void initState() {
    super.initState();
    _loadDefaultUser(); // Ensure default user is loaded
  }

  // ...existing code...
  void _loadDefaultUser() {
    final profileBox = Hive.box('profile');
    final userName = profileBox.get('name', defaultValue: "You");
    final avatarIndex = profileBox.get('avatarIndex', defaultValue: 0);
    // add logged-in user automatically as first member
    members.add({
      "name": userName,
      "avatarIndex": avatarIndex,
      "isDefaultUser": true,
    });
  }

  // ...existing code...
  void _addMember(String name) {
    if (name.trim().isEmpty) return;
    final List<String> avatars = [
      "😀","😎","🧸","👩‍💻","🧑‍🎨","🐱","🐶","🐼","🐸","🐵",
      "🦊","🐯","🦁","🐰","🐨","🐧","🐢","🐬","🐳","🦄",
    ];
    // Pick a random avatar index for new member
    final usedIndices = members.map((m) => m['avatarIndex'] as int?).whereType<int>().toSet();
    int avatarIndex = 0;
    for (int i = 0; i < avatars.length; i++) {
      if (!usedIndices.contains(i)) {
        avatarIndex = i;
        break;
      }
    }
    setState(() {
      members.add({
        "name": name.trim(),
        "avatarIndex": avatarIndex,
        "isDefaultUser": false,
      });
      _memberController.clear(); // Clear the member input after adding
    });
  }

  void _createGroup() async {
    final name = _groupNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a group name."), backgroundColor: Colors.red),
      );
      return;
    }
    if (members.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add at least one member."), backgroundColor: Colors.red),
      );
      return;
    }

    final box = Hive.box('groups');
    final groupId = const Uuid().v4();

    await box.put(groupId, {
      'groupId': groupId,
      'name': name,
      'members': members,
      'expenses': [],
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Group created!"), backgroundColor: Colors.green),
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Group"),
        centerTitle: true,
        elevation: 2,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Create a new group",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _groupNameController,
                  decoration: const InputDecoration(
                    labelText: "Group Name",
                    filled: true,
                    prefixIcon: Icon(Icons.group),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _memberController,
                  decoration: InputDecoration(
                    labelText: "Add Member",
                    filled: true,
                    prefixIcon: const Icon(Icons.person_add),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => _addMember(_memberController.text),
                    ),
                  ),
                  onSubmitted: _addMember,
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  children: members
                      .map(
                        (m) {
                          final List<String> avatars = [
                            "😀","😎","🧸","👩‍💻","🧑‍🎨","🐱","🐶","🐼","🐸","🐵",
                            "🦊","🐯","🦁","🐰","🐨","🐧","🐢","🐬","🐳","🦄",
                          ];
                          final avatarIndex = m['avatarIndex'] ?? 0;
                          return Chip(
                            avatar: CircleAvatar(
                              radius: 18,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  avatars[avatarIndex],
                                  style: const TextStyle(fontSize: 22),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            label: Text(m['name']),
                            onDeleted: m['isDefaultUser']
                                ? null // can't delete logged-in user
                                : () {
                                  setState(() => members.remove(m));
                                },
                          );
                        },
                      )
                      .toList(),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text("Create Group"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: _createGroup,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}