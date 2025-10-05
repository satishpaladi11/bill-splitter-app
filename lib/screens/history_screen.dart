// history_screen.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class HistoryScreen extends StatelessWidget {
  final String groupId;
  const HistoryScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    final group = Hive.box('groups').get(groupId);
    final expenses = group['expenses'] as List<dynamic>;

    return Scaffold(
      appBar: AppBar(title: Text("${group['name']} Expenses")),
      body: expenses.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text("No expenses yet!", style: TextStyle(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.w500)),
                  SizedBox(height: 8),
                  Text("Add your first expense to see history.", style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              itemCount: expenses.length,
              itemBuilder: (_, i) {
                final e = expenses[i];
                return ListTile(
                  title: Text("${e['desc']}"),
                  subtitle: Text("Paid by: ${e['payer']}"),
                  trailing: Text("₹ ${e['amount']}"),
                );
              },
            ),
    );
  }
}
