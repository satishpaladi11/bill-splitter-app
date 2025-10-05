import 'package:flutter/material.dart';
import '../models/expense.dart';

class ExpenseList extends StatelessWidget {
  final List<Expense> expenses;

  const ExpenseList({super.key, required this.expenses});

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) return Center(child: Text('No expenses yet'));
    return ListView.builder(
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        Expense exp = expenses[index];
        return ListTile(
          title: Text('${exp.description} - ₹${exp.amount.toStringAsFixed(2)}'),
          subtitle: Text('Paid by ${exp.paidBy}, split between ${exp.splitBetween.join(', ')}'),
          trailing: Text('${exp.date.hour}:${exp.date.minute}'),
        );
      },
    );
  }
}
