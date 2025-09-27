import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AddExpenseScreen extends StatefulWidget {
  final String groupId;
  const AddExpenseScreen({Key? key, required this.groupId}) : super(key: key);

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedPayer;
  double? _amount;
  String? _description;
  List<String> members = [];

  @override
  void initState() {
    super.initState();
    final group = Hive.box('groups').get(widget.groupId);
    members = List<String>.from(group?['members'] ?? []);
    if (members.isNotEmpty) _selectedPayer = members.first;
  }

  void _saveExpense() {
    if (_formKey.currentState!.validate() && _selectedPayer != null) {
      _formKey.currentState!.save();

      final box = Hive.box('groups');
      var group = box.get(widget.groupId);

      // If group doesn't exist, create it
      if (group == null) {
        group = {'members': [], 'expenses': []};
      }

      // Initialize expenses safely
      List<Map<String, dynamic>> expenses =
          List<Map<String, dynamic>>.from(group['expenses'] ?? []);

      expenses.add({
        'payer': _selectedPayer,
        'amount': _amount ?? 0,
        'description': _description ?? '',
        'timestamp': DateTime.now().toIso8601String(),
      });

      group['expenses'] = expenses;

      // Save updated group back to Hive
      box.put(widget.groupId, group);

      Navigator.pop(context); // back to GroupDetailsScreen
    }
  }



  Future<void> _addMemberDialog() async {
    final newMember = await showDialog<String>(
      context: context,
      builder: (_) {
        String memberName = '';
        return AlertDialog(
          title: const Text("Add Member"),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(hintText: "Member Name"),
            onChanged: (v) => memberName = v,
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel")),
            ElevatedButton(
                onPressed: () => Navigator.pop(context, memberName.trim()),
                child: const Text("Add")),
          ],
        );
      },
    );

    if (newMember != null && newMember.isNotEmpty) {
      final box = Hive.box('groups');
      final group = box.get(widget.groupId);
      members.add(newMember);
      group['members'] = members;
      box.put(widget.groupId, group);

      setState(() {
        _selectedPayer = newMember; // auto-select newly added member
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Expense")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Dropdown to select payer or add new member
              DropdownButtonFormField<String>(
                value: _selectedPayer,
                items: [
                  ...members.map((m) =>
                      DropdownMenuItem(value: m, child: Text(m))),
                  const DropdownMenuItem(
                      value: 'add_member', child: Text('+ Add Member')),
                ],
                hint: const Text("Select Payer"),
                onChanged: (val) async {
                  if (val == 'add_member') {
                    await _addMemberDialog();
                  } else {
                    setState(() => _selectedPayer = val);
                  }
                },
              ),
              const SizedBox(height: 16),
              // Amount input (mandatory)
              TextFormField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Amount"),
                validator: (v) {
                  if (v == null || v.isEmpty) return "Enter amount";
                  if (double.tryParse(v) == null || double.parse(v) <= 0) {
                    return "Amount must be greater than 0";
                  }
                  return null;
                },
                onSaved: (v) => _amount = double.tryParse(v ?? '0'),
              ),
              const SizedBox(height: 16),
              // Description input (optional)
              TextFormField(
                decoration: const InputDecoration(labelText: "Description"),
                onSaved: (v) => _description = v,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveExpense,
                child: const Text("Save Expense"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
