// lib/screens/group_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'add_expense_screen.dart';

class GroupDetailsScreen extends StatelessWidget {
  final String groupId;
  const GroupDetailsScreen({Key? key, required this.groupId}) : super(key: key);

  /// Calculate who owes/receives how much
  Map<String, double> calculateBalances(List<Map<String, dynamic>> expenses, List<String> members) {
    final balance = {for (var m in members) m: 0.0};

    for (final e in expenses) {
      final amount = (e['amount'] as num?)?.toDouble() ?? 0.0;
      final payer = e['payer'] as String? ?? '';
      final perPerson = members.isNotEmpty ? amount / members.length : 0.0;

      for (final m in members) {
        balance[m] = (balance[m] ?? 0.0) + ((m == payer) ? amount - perPerson : -perPerson);
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
                height: 200,
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
    
    // Save that this group screen is last visited
    final box = Hive.box('groups');
    final appBox = Hive.box('appState');
    appBox.put('lastScreen', 'group');
    appBox.put('lastGroupId', groupId);

    return Scaffold(
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
      body: SafeArea(
        child: ValueListenableBuilder(
          valueListenable: box.listenable(),
          builder: (context, Box groups, _) {
            final raw = groups.get(groupId);
            if (raw == null) {
              return const Center(child: Text("Group not found"));
            }

            final group = Map<String, dynamic>.from(raw as Map);
            final members = (group['members'] as List<dynamic>?)?.cast<String>() ?? <String>[];
            final expensesRaw = (group['expenses'] as List<dynamic>?) ?? <dynamic>[];
            final expenses = expensesRaw.map<Map<String, dynamic>>((e) {
              if (e is Map) return Map<String, dynamic>.from(e as Map);
              return <String, dynamic>{
                'desc': e.toString(),
                'amount': 0,
                'payer': '',
                'timestamp': null,
              };
            }).toList();

            final balances = calculateBalances(expenses, members);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Group header: big name, members with balances
                  Container(
                    width: double.infinity, // ensures full width
                    margin: EdgeInsets.zero, // remove card margin
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
                            if (members.isNotEmpty)
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                alignment: WrapAlignment.center,
                                children: members.map((m) {
                                  final amt = balances[m] ?? 0.0;
                                  final chipColor = amt > 0
                                      ? Colors.green.shade100
                                      : amt < 0
                                          ? Colors.red.shade100
                                          : Colors.grey.shade200;
                                  final text = amt > 0
                                      ? "$m +₹${amt.toStringAsFixed(2)}"
                                      : amt < 0
                                          ? "$m -₹${amt.abs().toStringAsFixed(2)}"
                                          : "$m ✓";
                                  return Chip(
                                    backgroundColor: chipColor,
                                    avatar: CircleAvatar(child: Text(m.isNotEmpty ? m[0].toUpperCase() : '?')),
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

                  // Expenses
                  const Text("Expenses", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (expenses.isEmpty)
                    Center(
                      child: Column(
                        children: const [
                          SizedBox(height: 24),
                          Icon(Icons.receipt_long, size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text("No expenses yet", style: TextStyle(color: Colors.grey)),
                          SizedBox(height: 12),
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
                        final dateText = ts != null ? " • ${_formatDate(ts)}" : "";
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
                            title: Text(desc),
                            subtitle: subtitleWidget != null
                                ? Row(children: [Expanded(child: subtitleWidget), Text(dateText)])
                                : (dateText.isNotEmpty ? Text(dateText) : null),
                            trailing: Text("₹ ${amount.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    }
    if (dt.year == now.year) {
      return "${dt.day} ${_monthShort(dt.month)}";
    }
    return "${dt.day} ${_monthShort(dt.month)} ${dt.year}";
  }

  static String _monthShort(int month) {
    const names = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return names[month - 1];
  }
}
