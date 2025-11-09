// lib/screens/add_expense_screen.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../utils/avatars.dart';

class AddExpenseScreen extends StatefulWidget {
  final String groupId;
  final Map<String, dynamic>? expense; // existing expense when editing
  final int? expenseIndex;
  const AddExpenseScreen({
    super.key,
    required this.groupId,
    this.expense,
    this.expenseIndex,
  });

  @override
  _AddExpenseScreenState createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  bool _useCustomSplit = false;
  // percentage per member name (0-100)
  final Map<String, double> _percentages = {};
  DateTime _selectedDateTime = DateTime.now();
  String? selectedPayer;

  @override
  void initState() {
    super.initState();
    // If editing an existing expense, prefill fields
    if (widget.expense != null) {
      final exp = widget.expense!;
      _descController.text = (exp['desc'] as String?) ?? '';
      final amt = exp['amount'];
      _amountController.text = amt != null ? amt.toString() : '';
      selectedPayer = (exp['payer'] as String?) ?? selectedPayer;
      // prefill timestamp and splits if provided
      if (exp['timestamp'] != null) {
        final parsed = DateTime.tryParse(exp['timestamp'].toString());
        if (parsed != null) _selectedDateTime = parsed;
      }
      if (exp['splits'] is Map) {
        _useCustomSplit = true;
        final sp = Map<String, dynamic>.from(exp['splits'] as Map);
        sp.forEach((k, v) {
          final dv = (v is num) ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0;
          _percentages[k] = dv;
        });
      }
    }
  }

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
              final updatedMembers = List<String>.from(group['members'] ?? []);
              updatedMembers.add(name);
              box.put(widget.groupId, {...group, 'members': updatedMembers});
              setState(() => selectedPayer = name);
              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$y-$mo-$d $h:$min';
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
    if (time == null) return;
    setState(() {
      _selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  void _saveExpense() async {
    final desc = _descController.text.trim();
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText) ?? 0;

    // Description is optional now; allow empty description
    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter an amount."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a valid amount."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (selectedPayer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a payer."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // if custom split is used, ensure percentages sum to ~100%
    if (_useCustomSplit) {
      final sum = _percentages.values.fold<double>(0.0, (p, e) => p + e);
      if ((sum - 100.0).abs() > 0.01) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Custom split percentages must total 100%."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    final box = Hive.box('groups');
    final group = box.get(widget.groupId);
  final expenses = List<Map<String, dynamic>>.from(group['expenses'] ?? []);
  final members = (group['members'] as List<dynamic>?)?.map((m) => Map<String, dynamic>.from(m)).toList() ?? <Map<String, dynamic>>[];
    // Ensure stable id for each expense so edits are deterministic
    final uuid = const Uuid();
    final existingId = widget.expense != null
        ? (widget.expense!['id'] as String?)
        : null;

    final newEntry = {
      'id': existingId ?? uuid.v4(),
      'desc': desc,
      'amount': amount,
      'payer': selectedPayer,
      'timestamp': _selectedDateTime.toIso8601String(),
    };

    // attach splits (percentages) if custom split used
    if (_useCustomSplit) {
      // ensure members list order keys
      final Map<String, double> out = {};
      for (final m in members) {
        final name = m['name'] as String? ?? '';
        out[name] = _percentages[name] ?? 0.0;
      }
      newEntry['splits'] = out;
    } else {
      // default equal split percentages
      final per = members.isNotEmpty ? 100.0 / members.length : 0.0;
      final Map<String, double> out = {};
      for (final m in members) {
        final name = m['name'] as String? ?? '';
        out[name] = per;
      }
      newEntry['splits'] = out;
    }

    int? indexToUpdate = widget.expenseIndex;
    // If we don't have an index but we have an expense with an id, try to find its index
    if (indexToUpdate == null && existingId != null) {
      indexToUpdate = expenses.indexWhere(
        (it) => (it['id']?.toString() ?? '') == existingId,
      );
    }
    // Fallback: try to match by timestamp or content if still not found
    if ((indexToUpdate == null || indexToUpdate < 0) &&
        widget.expense != null) {
      final candidateTs = widget.expense!['timestamp']?.toString();
      indexToUpdate = expenses.indexWhere((it) {
        final its = it['timestamp']?.toString();
        if (its != null && candidateTs != null && its == candidateTs) {
          return true;
        }
        if ((it['amount'] == widget.expense!['amount']) &&
            ((it['desc'] ?? '') == (widget.expense!['desc'] ?? '')) &&
            ((it['payer'] ?? '') == (widget.expense!['payer'] ?? ''))) {
          return true;
        }
        return false;
      });
    }

    if (indexToUpdate != null &&
        indexToUpdate >= 0 &&
        indexToUpdate < expenses.length) {
      expenses[indexToUpdate] = newEntry;
    } else {
      expenses.add(newEntry);
    }

    await box.put(widget.groupId, {...group, 'expenses': expenses});

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.expenseIndex != null ? "Expense updated!" : "Expense added!",
        ),
        backgroundColor: Colors.green,
      ),
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('groups');
    final group = box.get(widget.groupId);
    final members =
        (group['members'] as List<dynamic>?)
            ?.map((m) => Map<String, dynamic>.from(m))
            .toList() ??
        <Map<String, dynamic>>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.expense != null ? "Edit Expense" : "Add Expense"),
        centerTitle: true,
        elevation: 2,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 24.0,
            ),
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
                    ...members.map((m) {
                      final avatarIndex = m['avatarIndex'] ?? 0;
                      final name = m['name'] as String? ?? '';
                      return DropdownMenuItem(
                        value: name,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              child: Text(appAvatars[avatarIndex]),
                            ),
                            const SizedBox(width: 8),
                            Text(name),
                          ],
                        ),
                      );
                    }),
                  ],
                  onChanged: (val) {
                    if (val == "__add_member__") {
                      _addMemberDialog(
                        members.map((m) => m['name'] as String).toList(),
                      );
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
                    labelText: "What's this expense for? (optional)",
                    filled: true,
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // Date/time (optional) - default to now, user can pick original date/time
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Date & time', style: TextStyle(fontWeight: FontWeight.w500)),
                    TextButton.icon(
                      onPressed: _pickDateTime,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_formatDateTime(_selectedDateTime)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Split options: equal or custom percentages
                SwitchListTile(
                  title: const Text('Custom split (adjust percentages)'),
                  value: _useCustomSplit,
                  onChanged: (v) {
                    setState(() {
                      _useCustomSplit = v;
                      if (v && _percentages.isEmpty) {
                        // initialize equal percentages
                        final per = members.isNotEmpty ? 100.0 / members.length : 0.0;
                        for (final m in members) {
                          final name = m['name'] as String? ?? '';
                          _percentages[name] = per;
                        }
                      }
                    });
                  },
                ),

                if (_useCustomSplit)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      ...members.map((m) {
                        final name = m['name'] as String? ?? '';
                        final avatarIndex = m['avatarIndex'] ?? 0;
                        final controller = TextEditingController(text: (_percentages[name] ?? 0).toString());
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Row(
                            children: [
                              CircleAvatar(radius: 14, child: Text(appAvatars[avatarIndex])),
                              const SizedBox(width: 8),
                              Expanded(child: Text(name)),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 90,
                                child: TextField(
                                  controller: controller,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(suffixText: '%'),
                                  onChanged: (txt) {
                                    final v = double.tryParse(txt) ?? 0.0;
                                    _percentages[name] = v;
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 6),
                      Builder(builder: (ctx) {
                        final sum = _percentages.values.fold<double>(0.0, (p, e) => p + e);
                        final ok = (sum - 100.0).abs() < 0.01;
                        return Row(
                          children: [
                            Text('Total: ${sum.toStringAsFixed(1)}%'),
                            const SizedBox(width: 12),
                            if (!ok) Text('Total must be 100%', style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
                          ],
                        );
                      }),
                      const SizedBox(height: 12),
                    ],
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saveExpense,
                    icon: const Icon(Icons.save),
                    label: Text(
                      widget.expense != null
                          ? "Update Expense"
                          : "Save Expense",
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
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
