// lib/screens/qr_scanner_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerScreen extends StatelessWidget {
  final Function(String) onCodeScanned;

  const QRScannerScreen({super.key, required this.onCodeScanned});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan QR Code")),
      body: MobileScanner(
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            final code = barcodes.first.rawValue ?? "";
            if (code.isNotEmpty) {
              onCodeScanned(code);
              Navigator.pop(context); // Go back after scanning
            }
          }
        },
      ),
    );
  }
}
