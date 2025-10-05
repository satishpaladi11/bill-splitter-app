import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'home_screen.dart';
import '../main.dart'; // import MainScreen

class ProfileSetupScreen extends StatefulWidget {
  final bool isEditing; // true if opened from Profile to edit
  const ProfileSetupScreen({super.key, this.isEditing = false});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  int? _selectedAvatarIndex;
  final List<String> _avatars = [
    "😀","😎","🦸","👩‍💻","🧑‍🎨","🐱","🐶","🐼","🐸","🐵",
    "🦊","🐯","🦁","🐰","🐨","🐧","🐢","🐬","🐳","🦄",
  ];
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      final profileBox = Hive.box('profile');
      _nameController.text = profileBox.get('name', defaultValue: '');
      _selectedAvatarIndex = profileBox.get('avatarIndex') as int?;
    }
  }

  // ...existing code...
  void _saveProfile() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your name."), backgroundColor: Colors.red),
      );
      return;
    }
    if (_selectedAvatarIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an avatar."), backgroundColor: Colors.red),
      );
      return;
    }

    final profileBox = Hive.box('profile');
    profileBox.put('name', name);
    profileBox.put('avatarIndex', _selectedAvatarIndex);

    // Update avatar for default user in all groups
    final groupsBox = Hive.box('groups');
    for (var key in groupsBox.keys) {
      final group = groupsBox.get(key);
      if (group != null && group['members'] != null) {
    final members = (group['members'] as List)
      .map((m) => Map<String, dynamic>.from(m as Map))
      .toList();
        bool updated = false;
        for (var m in members) {
          if (m['isDefaultUser'] == true) {
            m['avatarIndex'] = _selectedAvatarIndex;
            m['name'] = name;
            updated = true;
          }
        }
        if (updated) {
          groupsBox.put(key, {
            ...group,
            'members': members,
          });
        }
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(widget.isEditing ? "Profile updated!" : "Profile saved!"), backgroundColor: Colors.green),
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      if (widget.isEditing) {
        Navigator.pop(context, true);
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MainScreen(
              initialScreen: const HomeScreen(),
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isValid = _nameController.text.trim().isNotEmpty && _selectedAvatarIndex != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? "Edit Profile" : "Setup Profile"),
        automaticallyImplyLeading: widget.isEditing,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Enter your name and choose an avatar",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "Your name",
                    border: OutlineInputBorder(),
                    filled: true,
                    prefixIcon: Icon(Icons.person),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 24),
                if (_selectedAvatarIndex != null)
                  Center(
                    child: Column(
                      children: [
                        const Text("Selected Avatar", style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.indigo,
                          child: Text(_avatars[_selectedAvatarIndex!], style: const TextStyle(fontSize: 32)),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _avatars.length,
                  itemBuilder: (context, index) {
                    final selected = _selectedAvatarIndex == index;
                    return Semantics(
                      label: 'Avatar ${_avatars[index]}',
                      selected: selected,
                      button: true,
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedAvatarIndex = index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: selected ? Border.all(color: Colors.indigo, width: 3) : null,
                            boxShadow: selected
                                ? [BoxShadow(color: Colors.indigo.withOpacity(0.2), blurRadius: 8)]
                                : [],
                          ),
                          child: CircleAvatar(
                            radius: 30,
                            backgroundColor: selected ? Colors.indigo.shade100 : Colors.grey[200],
                            child: Text(
                              _avatars[index],
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isValid ? _saveProfile : null,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: Text(widget.isEditing ? "Save" : "Continue"),
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
