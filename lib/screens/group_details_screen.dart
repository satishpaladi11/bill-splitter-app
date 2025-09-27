// group_details_screen.dart
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
      appBar: AppBar(title: const Text("Group Details")),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box groups, _) {
          final group = groups.get(groupId);
          if (group == null) return const Center(child: Text("Group not found"));
          
          final members = (group['members'] as List<dynamic>?)?.cast<String>() ?? [];
          final expenses = (group['expenses'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
          final balances = calculateBalances(expenses, members);

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  "Group: ${group['name']}",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text("Code: ${group['groupId']}"),
                const SizedBox(height: 20),
                QrImageView(data: group['groupId'] ?? '', size: 180),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddExpenseScreen(groupId: groupId),
                      ),
                    );
                  },
                  child: const Text("Add Expense"),
                ),
                const SizedBox(height: 20),
                const Text("Expenses", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Expanded(
                  child: expenses.isEmpty
                      ? const Center(child: Text("No expenses yet"))
                      : ListView.builder(
                          itemCount: expenses.length,
                          itemBuilder: (_, i) {
                            final e = expenses[i] ?? {};
                            final desc = e['desc']?.toString() ?? '';
                            final payer = e['payer']?.toString() ?? '';
                            final amount = (e['amount'] as num?)?.toDouble() ?? 0.0;

                            return ListTile(
                              title: Text(desc.isNotEmpty ? desc : 'No description'),
                              subtitle: Text(payer.isNotEmpty ? "Paid by: $payer" : "No payer"),
                              trailing: Text("₹ ${amount.toStringAsFixed(2)}"),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 10),
                const Text("Balances", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: balances.entries.map((e) {
                    final name = e.key;
                    final amt = e.value;
                    if (amt > 0) {
                      return Text("$name should receive ₹${amt.toStringAsFixed(2)}");
                    } else if (amt < 0) {
                      return Text("$name owes ₹${(-amt).toStringAsFixed(2)}");
                    } else {
                      return Text("$name is settled");
                    }
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
