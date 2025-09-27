import 'expense.dart';

class Group {
  String id;
  String name;
  List<String> members;
  List<Expense> expenses;

  Group({
    required this.id,
    required this.name,
    required this.members,
    required this.expenses,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'members': members,
        'expenses': expenses.map((e) => e.toJson()).toList(),
      };

  factory Group.fromJson(Map<String, dynamic> json) => Group(
        id: json['id'],
        name: json['name'],
        members: List<String>.from(json['members']),
        expenses: (json['expenses'] as List)
            .map((e) => Expense.fromJson(e))
            .toList(),
      );
}
