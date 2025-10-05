import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import 'add_expense_screen.dart';

class GroupDetailsScreen extends StatelessWidget {
  final String groupId;
  const GroupDetailsScreen({super.key, required this.groupId});

  Map<String, double> calculateBalances(List<Map<String, dynamic>> expenses, List<String> members) {
    final balance = {for (var m in members) m: 0.0};
    for (final e in expenses) {
      final amount = (e['amount'] as num?)?.toDouble() ?? 0.0;
      final payer = e['payer'] as String? ?? '';
      final perPerson = members.isNotEmpty ? amount / members.length : 0.0;
      for (final m in members) {
        if (members.contains(payer)) {
          balance[m] = (balance[m] ?? 0.0) + ((m == payer) ? amount - perPerson : -perPerson);
        }
      }
    }
    return balance;
  }

  void _showShareSheet(BuildContext context, String groupId, String groupName) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).canvasColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Share Group",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 200,
                child: Center(
                  child: QrImageView(
                    data: groupId,
                    version: QrVersions.auto,
                    size: 180,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SelectableText(
                    groupId,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  IconButton(
                    tooltip: "Copy code",
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: groupId));
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text("Group code copied to clipboard")),
                      );
                    },
                  )
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.share),
                label: const Text("Share via apps"),
                onPressed: () {
                  Share.share("Join my group '$groupName' on Simplify Split.\nGroup Code: $groupId");
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('groups');
    final appBox = Hive.box('appState');
    appBox.put('lastScreen', 'group');
    appBox.put('lastGroupId', groupId);

    return WillPopScope(
      onWillPop: () async {
        appBox.put('lastScreen', 'home');
        appBox.delete('lastGroupId');
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Group Details"),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: 'Share group',
              icon: const Icon(Icons.share),
              onPressed: () {
                final group = box.get(groupId) as Map?;
                final groupName = (group?['name'] as String?) ?? "Group";
                _showShareSheet(context, groupId, groupName);
              },
            )
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'add-expense-fab',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AddExpenseScreen(groupId: groupId)),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text("Add Expense"),
        ),
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => FocusScope.of(context).unfocus(),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
              child: ValueListenableBuilder(
                valueListenable: box.listenable(),
                builder: (context, Box groups, _) {
                  final raw = groups.get(groupId);
                  if (raw == null) {
                    return const Center(child: Text("Group not found"));
                  }
                  final group = Map<String, dynamic>.from(raw as Map);
                  final members = (group['members'] as List<dynamic>?)?.map((m) => Map<String, dynamic>.from(m)).toList() ?? <Map<String, dynamic>>[];
                  final expensesRaw = (group['expenses'] as List<dynamic>?) ?? <dynamic>[];
                  final expenses = expensesRaw.map<Map<String, dynamic>>((e) {
                    if (e is Map) return Map<String, dynamic>.from(e);
                    return <String, dynamic>{
                      'desc': e.toString(),
                      'amount': 0,
                      'payer': '',
                      'timestamp': null,
                    };
                  }).toList();
                  final balances = calculateBalances(
                    expenses,
                    members.map((m) => m['name'] as String).toList(),
                  );
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        margin: EdgeInsets.zero,
                        child: Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 3,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                            child: Column(
                              children: [
                                Text(
                                  (group['name'] as String?) ?? "Unnamed Group",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 8),
                                if (members.isEmpty)
                                  Column(
                                    children: const [
                                      SizedBox(height: 24.0),
                                      Icon(Icons.group_off, size: 64, color: Colors.grey),
                                      SizedBox(height: 8.0),
                                      Text("No members yet!", style: TextStyle(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.w500)),
                                      SizedBox(height: 8.0),
                                      Text("Invite friends to join your group.", style: TextStyle(color: Colors.grey)),
                                      SizedBox(height: 12.0),
                                    ],
                                  )
                                else
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    alignment: WrapAlignment.center,
                                    children: members.map((m) {
                                      final name = m['name'] as String? ?? '';
                                      final amt = balances[name] ?? 0.0;
                                      final chipColor = amt > 0
                                          ? Colors.green.shade100
                                          : amt < 0
                                              ? Colors.red.shade100
                                              : Colors.grey.shade200;
                                      final text = amt > 0
                                          ? "$name +₹${amt.toStringAsFixed(2)}"
                                          : amt < 0
                                              ? "$name -₹${amt.abs().toStringAsFixed(2)}"
                                              : "$name ✓";
                                      final List<String> avatars = [
                                        "😀","😎","🧸","👩‍💻","🧑‍🎨","🐱","🐶","🐼","🐸","🐵",
                                        "🦊","🐯","🦁","🐰","🐨","🐧","🐢","🐬","🐳","🦄",
                                      ];
                                      final avatarIndex = m['avatarIndex'] ?? 0;
                                      return Chip(
                                        backgroundColor: chipColor,
                                        avatar: CircleAvatar(
                                          radius: 18,
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              avatars[avatarIndex],
                                              style: const TextStyle(fontSize: 22),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                        label: Text(text),
                                      );
                                    }).toList(),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text("Expenses", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      if (expenses.isEmpty)
                        Center(
                          child: Column(
                            children: const [
                              SizedBox(height: 24.0),
                              Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                              SizedBox(height: 8.0),
                              Text("No expenses yet!", style: TextStyle(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.w500)),
                              SizedBox(height: 8.0),
                              Text("Add your first expense to get started.", style: TextStyle(color: Colors.grey)),
                              SizedBox(height: 12.0),
                            ],
                          ),
                        )
                      else
                        Column(
                          children: expenses.reversed.map((e) {
                            final desc = e['desc'] ?? 'No description';
                            final payer = e['payer'] ?? '';
                            final amount = (e['amount'] as num?)?.toDouble() ?? 0.0;
                            final ts = e['timestamp'] != null ? DateTime.tryParse(e['timestamp'].toString()) : null;
                            final subtitle = payer.isNotEmpty ? "Paid by: $payer" : null;
                            final subtitleWidget = subtitle != null ? Text(subtitle) : null;
                            final dateText = ts != null ? " • ${ts.toLocal().toString().split(' ')[0]}" : "";
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 1.5,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue.shade50,
                                  child: const Text(
                                    "₹",
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(child: Text(desc)),
                                  ],
                                ),
                                subtitle: subtitleWidget != null
                                    ? Row(children: [
                                        Expanded(child: subtitleWidget),
                                        Text(dateText)
                                      ])
                                    : (dateText.isNotEmpty ? Text(dateText) : null),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.attach_money, size: 18, color: Colors.green),
                                    SizedBox(width: 4),
                                    Text("₹ ${amount.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 32),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
