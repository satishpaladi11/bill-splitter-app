import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/rendering.dart';

import 'add_expense_screen.dart';
import '../widgets/group_summary_card.dart';

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
            ),
            IconButton(
              tooltip: 'Share summary card',
              icon: const Icon(Icons.card_giftcard),
              onPressed: () async {
                final raw = box.get(groupId);
                if (raw == null) return;
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

                final cardKey = GlobalKey();
                await showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  builder: (ctx) {
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                        left: 12, right: 12, top: 24,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RepaintBoundary(
                            key: cardKey,
                            child: GroupSummaryCard(
                              groupName: group['name'] ?? '',
                              members: members,
                              expenses: expenses,
                              balances: balances,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.share),
                            label: const Text('Share as Image'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () async {
                              try {
                                RenderRepaintBoundary boundary = cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
                                var image = await boundary.toImage(pixelRatio: 3.0);
                                ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
                                if (byteData != null) {
                                  final pngBytes = byteData.buffer.asUint8List();
                                  final tempDir = await Directory.systemTemp.createTemp();
                                  final file = await File('${tempDir.path}/group_summary.png').writeAsBytes(pngBytes);
                                  await Share.shareXFiles([XFile(file.path)], text: 'Group summary from Simplify Split');
                                } else {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(content: Text('Failed to capture image.')),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(content: Text('Failed to share image: $e')),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
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
                                    children: [
                                      ...members.map((m) {
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
                        : name;
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

                                      // Add member chip
                                      ActionChip(
                                        label: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: const [
                                            Icon(Icons.add, size: 18),
                                            SizedBox(width: 6),
                                            Text('Add'),
                                          ],
                                        ),
                                        backgroundColor: Colors.blue.shade50,
                                        onPressed: () {
                                          final TextEditingController _newMemberController = TextEditingController();
                                          showDialog<void>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text('Add member'),
                                              content: TextField(
                                                controller: _newMemberController,
                                                decoration: const InputDecoration(labelText: 'Member name'),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(ctx),
                                                  child: const Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    final name = _newMemberController.text.trim();
                                                    if (name.isEmpty) return;
                                                    final box = Hive.box('groups');
                                                    final raw = box.get(groupId);
                                                    if (raw == null) return;
                                                    final g = Map<String, dynamic>.from(raw as Map);
                                                    final updatedMembers = (g['members'] as List<dynamic>?)?.map((m) => m is Map ? Map<String,dynamic>.from(m) : {'name': m.toString()}).toList() ?? <Map<String,dynamic>>[];
                                                    updatedMembers.add({'name': name, 'avatarIndex': 0, 'isDefaultUser': false, 'invited': false});
                                                    box.put(groupId, {...g, 'members': updatedMembers});
                                                    Navigator.pop(ctx);
                                                  },
                                                  child: const Text('Add locally'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    final name = _newMemberController.text.trim();
                                                    if (name.isEmpty) return;
                                                    final box = Hive.box('groups');
                                                    final raw = box.get(groupId);
                                                    if (raw == null) return;
                                                    final g = Map<String, dynamic>.from(raw as Map);
                                                    final updatedMembers = (g['members'] as List<dynamic>?)?.map((m) => m is Map ? Map<String,dynamic>.from(m) : {'name': m.toString()}).toList() ?? <Map<String,dynamic>>[];
                                                    updatedMembers.add({'name': name, 'avatarIndex': 0, 'isDefaultUser': false, 'invited': true});
                                                    box.put(groupId, {...g, 'members': updatedMembers});
                                                    // Share invite
                                                    Share.share("Join my group '${g['name'] ?? ''}' on Simplify Split. Group Code: $groupId");
                                                    Navigator.pop(ctx);
                                                  },
                                                  child: const Text('Invite & Add'),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text("Expenses", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Expanded(
                        child: expenses.isEmpty
                            ? Center(
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
                            : ListView(
                                padding: EdgeInsets.zero,
                                children: expenses.reversed.map((e) {
                                  final rawDesc = e['desc'] as String?;
                                  final desc = (rawDesc != null && rawDesc.trim().isNotEmpty) ? rawDesc.trim() : null;
                                  final payer = (e['payer'] as String?) ?? '';
                                  final amount = (e['amount'] as num?)?.toDouble() ?? 0.0;
                                  final ts = e['timestamp'] != null ? DateTime.tryParse(e['timestamp'].toString()) : null;

                                  String? dateTimeText;
                                  if (ts != null) {
                                    final local = ts.toLocal();
                                    final y = local.year.toString().padLeft(4, '0');
                                    final mo = local.month.toString().padLeft(2, '0');
                                    final d = local.day.toString().padLeft(2, '0');
                                    final h = local.hour.toString().padLeft(2, '0');
                                    final min = local.minute.toString().padLeft(2, '0');
                                    dateTimeText = '$y-$mo-$d $h:$min';
                                  }

                                  // Leading avatar: use payer initial if available, otherwise 'E'
                                  final leadText = (payer.isNotEmpty) ? payer[0].toUpperCase() : 'E';

                                  // Title: show 'Paid to <payer>' when payer is present
                                  final titleWidget = Text(payer.isNotEmpty ? 'Paid by $payer' : 'Expense');

                                  // Subtitle: show date/time first, then description below (if any)
                                  final List<Widget> subtitleChildren = [];
                                  if (dateTimeText != null) {
                                    subtitleChildren.add(Text(dateTimeText, style: const TextStyle(color: Colors.grey, fontSize: 12)));
                                  }
                                  if (desc != null) {
                                    subtitleChildren.add(const SizedBox(height: 6));
                                    subtitleChildren.add(Text(desc, style: TextStyle(color: Colors.grey[800])));
                                  }

                                  final subtitleWidget = subtitleChildren.isNotEmpty
                                      ? Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: subtitleChildren,
                                        )
                                      : null;

                                  // Amount style: match page typography and remain neutral
                                  final amountStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ) ??
                                      const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black87);

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    elevation: 1.5,
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.blue.shade50,
                                        child: Text(
                                          leadText,
                                          style: const TextStyle(
                                            color: Colors.blue,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                      title: titleWidget,
                                      subtitle: subtitleWidget,
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '₹ ${amount.toStringAsFixed(2)}',
                                            style: amountStyle,
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(Icons.edit, size: 20),
                                            tooltip: 'Edit expense',
                                            onPressed: () {
                                              // find original index in the expenses list
                                              final raw = box.get(groupId);
                                              if (raw == null) return;
                                              final currentGroup = Map<String, dynamic>.from(raw as Map);
                                              final List<dynamic> exRaw = (currentGroup['expenses'] as List<dynamic>?) ?? <dynamic>[];
                                              final List<Map<String, dynamic>> exList = exRaw.map<Map<String, dynamic>>((it) => it is Map ? Map<String, dynamic>.from(it) : <String, dynamic>{'desc': it.toString(), 'amount': 0, 'payer': '', 'timestamp': null}).toList();
                                              final originalIndex = exList.indexWhere((item) {
                                                // try to match by timestamp first, then by content
                                                final aTs = item['timestamp']?.toString();
                                                final bTs = e['timestamp']?.toString();
                                                if (aTs != null && bTs != null && aTs == bTs) return true;
                                                if (item['amount'] == e['amount'] && (item['desc'] ?? '') == (e['desc'] ?? '') && (item['payer'] ?? '') == (e['payer'] ?? '')) return true;
                                                return false;
                                              });
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(builder: (_) => AddExpenseScreen(groupId: groupId, expense: e, expenseIndex: originalIndex >= 0 ? originalIndex : null)),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
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
