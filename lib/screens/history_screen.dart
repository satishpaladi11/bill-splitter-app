// history_screen.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class HistoryScreen extends StatelessWidget {
  final String groupId;
  const HistoryScreen({Key? key, required this.groupId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final group = Hive.box('groups').get(groupId);
    final expenses = group['expenses'] as List<dynamic>;

    return Scaffold(
      appBar: AppBar(title: Text("${group['name']} Expenses")),
      body: expenses.isEmpty
          ? Center(child: Text("No expenses yet"))
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
