// lib/screens/add_expense_screen.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class AddExpenseScreen extends StatefulWidget {
  final String groupId;
  const AddExpenseScreen({super.key, required this.groupId});

  @override
  _AddExpenseScreenState createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String? selectedPayer;

  void _addMemberDialog(List<String> members) {
    final TextEditingController newMemberController = TextEditingController();
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text("Add Member"),
              content: TextField(
                controller: newMemberController,
                decoration: const InputDecoration(labelText: "Member Name"),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = newMemberController.text.trim();
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

    if (desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a description."), backgroundColor: Colors.red),
      );
      return;
    }
    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter an amount."), backgroundColor: Colors.red),
      );
      return;
    }
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid amount."), backgroundColor: Colors.red),
      );
      return;
    }
    if (selectedPayer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a payer."), backgroundColor: Colors.red),
      );
      return;
    }

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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Expense added!"), backgroundColor: Colors.green),
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
  final box = Hive.box('groups');
  final group = box.get(widget.groupId);
  final members = (group['members'] as List<dynamic>?)?.map((m) => Map<String, dynamic>.from(m)).toList() ?? <Map<String, dynamic>>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Expense"),
        centerTitle: true,
        elevation: 2,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Add a new expense",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedPayer,
                  hint: const Text("Select payer"),
                  items: [
                    ...members.map(
                      (m) {
                        final List<String> avatars = [
                          "😀","😎","🧸","👩‍💻","🧑‍🎨","🐱","🐶","🐼","🐸","🐵",
                          "🦊","🐯","🦁","🐰","🐨","🐧","🐢","🐬","🐳","🦄",
                        ];
                        final avatarIndex = m['avatarIndex'] ?? 0;
                        final name = m['name'] as String? ?? '';
                        return DropdownMenuItem(
                          value: name,
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                child: Text(avatars[avatarIndex]),
                              ),
                              const SizedBox(width: 8),
                              Text(name),
                            ],
                          ),
                        );
                      },
                    ),
                    const DropdownMenuItem<String>(
                      value: "__add_member__",
                      child: Text("+ Add Member"),
                    ),
                  ],
                  onChanged: (val) {
                    if (val == "__add_member__") {
                      _addMemberDialog(members.map((m) => m['name'] as String).toList());
                    } else {
                      setState(() => selectedPayer = val);
                    }
                  },
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Amount",
                    filled: true,
                    prefixIcon: Icon(Icons.currency_rupee),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: "Description",
                    filled: true,
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 32),
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
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
