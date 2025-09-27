class Expense {
  String description;
  double amount;
  String paidBy;
  List<String> splitBetween;
  DateTime date;

  Expense({
    required this.description,
    required this.amount,
    required this.paidBy,
    required this.splitBetween,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'description': description,
        'amount': amount,
        'paidBy': paidBy,
        'splitBetween': splitBetween,
        'date': date.toIso8601String(),
      };

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        description: json['description'],
        amount: json['amount'],
        paidBy: json['paidBy'],
        splitBetween: List<String>.from(json['splitBetween']),
        date: DateTime.parse(json['date']),
      );
}
