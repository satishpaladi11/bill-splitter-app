import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
// import 'group_details_screen.dart';
import '../screens/group_details_screen.dart' show GroupDetailsScreen;

class JoinGroupScreen extends StatefulWidget {
  const JoinGroupScreen({super.key});

  @override
  _JoinGroupScreenState createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  bool _isScanning = true;
  String _manualCode = '';
  MobileScannerController controller = MobileScannerController();

  void _onDetect(BarcodeCapture capture) async {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final code = barcodes.first.rawValue;
    if (code != null) {
      _joinGroup(code);
    }
  }

  void _joinGroup(String code) {
    final box = Hive.box('groups');
    if (box.containsKey(code)) {
      // Fetch group
      final group = Map<String, dynamic>.from(box.get(code));

      // Members as list of objects
      List<dynamic> members = List<dynamic>.from(group['members'] ?? []);

      // Get current user profile
      final profileBox = Hive.box('profile');
      final userName = profileBox.get('name', defaultValue: "You");
      final avatarIndex = profileBox.get('avatarIndex', defaultValue: 0);
      final currentUser = {
        "name": userName,
        "avatarIndex": avatarIndex,
        "isDefaultUser": true,
      };

      // Add user if not already in group
      final alreadyMember = members.any((m) => m['name'] == userName);
      if (!alreadyMember) {
        members.add(currentUser);
        group['members'] = members;
        box.put(code, group);
      }

      // Navigate to group details
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => GroupDetailsScreen(groupId: code)),
      );
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Invalid group code")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Join Group")),
      body: Column(
        children: [
          Expanded(
            child: _isScanning
                ? MobileScanner(
                    controller: controller,
                    onDetect: _onDetect,
                  )
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        TextField(
                          decoration: const InputDecoration(
                            labelText: 'Enter Group Code',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (val) => _manualCode = val,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _joinGroup(_manualCode),
                          child: const Text("Join Group"),
                        ),
                      ],
                    ),
                  ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _isScanning = !_isScanning;
              });
            },
            child: Text(_isScanning ? "Enter code manually" : "Scan QR code"),
          ),
        ],
      ),
    );
  }
}
