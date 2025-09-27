// lib/screens/add_expense_screen.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class AddExpenseScreen extends StatefulWidget {
  final String groupId;
  const AddExpenseScreen({Key? key, required this.groupId}) : super(key: key);

  @override
  _AddExpenseScreenState createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String? selectedPayer;

  void _addMemberDialog(List<String> members) {
    final TextEditingController _newMemberController = TextEditingController();
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text("Add Member"),
              content: TextField(
                controller: _newMemberController,
                decoration: const InputDecoration(labelText: "Member Name"),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = _newMemberController.text.trim();
                    if (name.isEmpty) return;
                    final box = Hive.box('groups');
                    final group = box.get(widget.groupId);
                    final updatedMembers =
                        List<String>.from(group['members'] ?? []);
                    updatedMembers.add(name);
                    box.put(widget.groupId, {
                      ...group,
                      'members': updatedMembers,
                    });
                    setState(() => selectedPayer = name);
                    Navigator.pop(context);
                  },
                  child: const Text("Add"),
                ),
              ],
            ));
  }

  void _saveExpense() async {
    final desc = _descController.text.trim();
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText) ?? 0;

    if (desc.isEmpty || amount <= 0 || selectedPayer == null) return;

    final box = Hive.box('groups');
    final group = box.get(widget.groupId);

    final expenses = List<Map<String, dynamic>>.from(group['expenses'] ?? []);
    expenses.add({
      'desc': desc,
      'amount': amount,
      'payer': selectedPayer,
      'timestamp': DateTime.now().toIso8601String(),
    });

    await box.put(widget.groupId, {
      ...group,
      'expenses': expenses,
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('groups');
    final group = box.get(widget.groupId);
    final members = List<String>.from(group['members'] ?? []);

    return Scaffold(
      appBar: AppBar(title: const Text("Add Expense")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: selectedPayer,
              hint: const Text("Select payer"),
              items: [
                ...members.map(
                  (m) => DropdownMenuItem(
                    value: m,
                    child: Row(
                      children: [
                        CircleAvatar(
                          child: Text(m[0]),
                          radius: 14,
                        ),
                        const SizedBox(width: 8),
                        Text(m),
                      ],
                    ),
                  ),
                ),
                const DropdownMenuItem<String>(
                  value: "__add_member__",
                  child: Text("+ Add Member"),
                ),
              ],
              onChanged: (val) {
                if (val == "__add_member__") {
                  _addMemberDialog(members);
                } else {
                  setState(() => selectedPayer = val);
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: "Description",
                filled: true,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Amount",
                filled: true,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveExpense,
                icon: const Icon(Icons.save),
                label: const Text("Save Expense"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.blue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
