// home_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'group_details_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('groups');

    return Scaffold(
      appBar: AppBar(title: Text("My Groups")),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box groups, _) {
          if (groups.isEmpty) {
            return Center(child: Text("No groups yet, create one!"));
          }
          return ListView(
            children: groups.values.map((group) {
              return ListTile(
                title: Text(group['name']),
                subtitle: Text("Code: ${group['groupId']}"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GroupDetailsScreen(
                        groupId: group['groupId'],
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'create',
            child: Icon(Icons.add),
            onPressed: () => Navigator.pushNamed(context, '/create-group'),
            tooltip: 'Create Group',
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'join',
            child: Icon(Icons.qr_code_scanner),
            onPressed: () => Navigator.pushNamed(context, '/join-group'),
            tooltip: 'Join Group',
          ),
        ],
      ),
    );
  }
}
