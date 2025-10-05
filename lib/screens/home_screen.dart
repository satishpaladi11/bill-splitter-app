// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'create_group_screen.dart';
import 'join_group_screen.dart';
import '../screens/group_details_screen.dart' show GroupDetailsScreen;

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Generate a MaterialColor for avatar/card based on groupId
  MaterialColor _generateColor(String input) {
    final hash = input.codeUnits.fold(0, (prev, elem) => prev + elem);
    final colors = [
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
    ];
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('groups');
    final appStateBox = Hive.box('appState'); // Stores last visited info

    // Record that HomeScreen is last visited
    appStateBox.put('lastScreen', 'home');

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Simplify Split",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: ValueListenableBuilder(
            valueListenable: box.listenable(),
            builder: (context, Box groups, _) {
              final groupKeys = groups.keys.toList();
              if (groupKeys.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.group_off, size: 80, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text("No groups yet!", style: TextStyle(color: Colors.grey, fontSize: 20, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text("Create or join a group to get started.", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: groupKeys.length,
                itemBuilder: (context, idx) {
                  final key = groupKeys[idx];
                  final group = groups.get(key) as Map? ?? {};
                  final color = _generateColor(key.toString());
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GroupDetailsScreen(groupId: key.toString()),
                        ),
                      );
                    },
                    child: Card(
                      color: color,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    group['name'] as String? ?? "Unnamed Group",
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${(group['members'] as List?)?.length ?? 0} members",
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios,
                                color: Colors.white70, size: 18),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'create',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
              );
            },
            label: const Text("Create Group"),
            icon: const Icon(Icons.add),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'join',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const JoinGroupScreen()),
              );
            },
            label: const Text("Join Group"),
            icon: const Icon(Icons.group_add),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
