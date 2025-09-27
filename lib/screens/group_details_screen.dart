// lib/screens/group_details_screen.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'add_expense_screen.dart';

class GroupDetailsScreen extends StatelessWidget {
  final String groupId;
  const GroupDetailsScreen({Key? key, required this.groupId}) : super(key: key);

  /// Calculate who owes/receives how much
  Map<String, double> calculateBalances(List<Map<String, dynamic>> expenses, List<String> members) {
    final balance = {for (var m in members) m: 0.0};

    for (var e in expenses) {
      final amount = (e['amount'] as num?)?.toDouble() ?? 0.0;
      final payer = e['payer'] as String? ?? '';
      final perPerson = members.isNotEmpty ? amount / members.length : 0.0;

      for (var m in members) {
        balance[m] = (balance[m] ?? 0.0) + ((m == payer) ? amount - perPerson : -perPerson);
      }
    }
    return balance;
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('groups');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Group Details"),
        centerTitle: true,
      ),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box groups, _) {
          final group = groups.get(groupId);
          if (group == null) return const Center(child: Text("Group not found"));

          final members = (group['members'] as List<dynamic>?)?.cast<String>() ?? [];
          final expenses = (group['expenses'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
          final balances = calculateBalances(expenses, members);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Group Info
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          group['name'] ?? "Unnamed Group",
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text("Code: ${group['groupId']}", style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 16),
                        QrImageView(data: group['groupId'] ?? '', size: 160),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Add Expense Button
                Center(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddExpenseScreen(groupId: groupId),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text("Add Expense"),
                  ),
                ),
                const SizedBox(height: 24),

                // Expenses Timeline
                const Text("Expenses", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                expenses.isEmpty
                    ? const Center(child: Text("No expenses yet"))
                    : Column(
                        children: expenses.map((e) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey.shade100,
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue.shade100,
                                child: const Icon(Icons.attach_money, color: Colors.blue),
                              ),
                              title: Text(e['desc'] ?? "No description"),
                              subtitle: Text("Paid by: ${e['payer']}"),
                              trailing: Text(
                                "₹ ${e['amount'] ?? 0}",
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                const SizedBox(height: 24),

                // Balances Section
                const Text("Balances", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: balances.entries.map((e) {
                    final amt = e.value;
                    Color chipColor;
                    String text;

                    if (amt > 0) {
                      chipColor = Colors.green.shade100;
                      text = "${e.key} should receive ₹${amt.toStringAsFixed(2)}";
                    } else if (amt < 0) {
                      chipColor = Colors.red.shade100;
                      text = "${e.key} owes ₹${(-amt).toStringAsFixed(2)}";
                    } else {
                      chipColor = Colors.grey.shade200;
                      text = "${e.key} is settled";
                    }

                    return Chip(
                      backgroundColor: chipColor,
                      label: Text(text),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
