import 'package:flutter/material.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reports")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.bar_chart, size: 80, color: Colors.indigo),
            SizedBox(height: 20),
            Text(
              "Reports will be shown here",
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
