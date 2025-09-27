import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'group_details_screen.dart';

class JoinGroupScreen extends StatefulWidget {
  const JoinGroupScreen({Key? key}) : super(key: key);

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
      // Add current user as member if not already
      final group = Map<String, dynamic>.from(box.get(code));
      List<String> members = List<String>.from(group['members'] ?? []);
      const currentUser = "Me"; // Replace with actual username logic
      if (!members.contains(currentUser)) members.add(currentUser);
      group['members'] = members;
      box.put(code, group);

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
