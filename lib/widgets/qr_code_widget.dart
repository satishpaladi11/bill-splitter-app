import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRCodeWidget extends StatelessWidget {
  final String data;

  const QRCodeWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: QrImageView(   // <-- Use QrImageView instead of QrImage
        data: data,
        version: QrVersions.auto,
        gapless: false,
      ),
    );
  }
}
