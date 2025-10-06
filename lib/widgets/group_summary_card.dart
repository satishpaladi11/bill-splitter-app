import 'package:flutter/material.dart';
import 'dart:ui';

// Painter for confetti/abstract background
class ConfettiPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFE0E0E0).withOpacity(0.18);
    for (int i = 0; i < 30; i++) {
      final dx = (size.width * (i % 10) / 10) + (i * 7 % 20);
      final dy = (size.height * (i ~/ 10) / 3) + (i * 13 % 30);
      canvas.drawCircle(Offset(dx, dy), 8 + (i % 4), paint);
    }
    // Add some abstract lines
    final linePaint = Paint()
      ..color = const Color(0xFFB39DDB).withOpacity(0.15)
      ..strokeWidth = 3;
    for (int i = 0; i < 6; i++) {
      canvas.drawLine(
        Offset(size.width * (i + 1) / 7, 0),
        Offset(size.width * (i + 1) / 7, size.height),
        linePaint,
      );
    }
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class GroupSummaryCard extends StatelessWidget {
  final Map<String, double> balances;
  final List<Map<String, dynamic>> expenses;
  final List<Map<String, dynamic>> members;

  const GroupSummaryCard({
    super.key,
    required this.balances,
    required this.expenses,
    required this.members, required groupName,
  });

  @override
  Widget build(BuildContext context) {
    final balancesScrollController = ScrollController();
    final avatars = [
      "😀","😎","🧸","👩‍💻","🧑‍🎨","🐱","🐶","🐼","🐸","🐵",
      "🦊","🐯","🦁","🐰","🐨","🐧","🐢","🐬","🐳","🦄",
    ];

    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      margin: const EdgeInsets.all(12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Beautiful confetti/abstract illustration background
            CustomPaint(
              painter: ConfettiPainter(),
              child: Container(),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Members avatars
                    SizedBox(
                      height: 56,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: members.length,
                        itemBuilder: (context, idx) {
                          final m = members[idx];
                          final avatarIndex = m['avatarIndex'] ?? 0;
                          return Column(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                child: Text(avatars[avatarIndex], style: const TextStyle(fontSize: 18)),
                              ),
                              Text(m['name'] ?? '', style: const TextStyle(fontSize: 12)),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Expenses summary
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Expenses', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          ...expenses.take(3).map((e) {
                            final desc = e['desc'] ?? 'No description';
                            final amount = (e['amount'] as num?)?.toDouble() ?? 0.0;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2.0),
                              child: Text('• $desc: ₹${amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13)),
                            );
                          }),
                          if (expenses.length > 3)
                            Text('+${expenses.length - 3} more', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Balances summary, scrollable if too many
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      constraints: const BoxConstraints(maxHeight: 120),
                      child: Scrollbar(
                        thumbVisibility: true,
                        controller: balancesScrollController,
                        child: ListView(
                          controller: balancesScrollController,
                          shrinkWrap: true,
                          children: [
                            const Text('Balances', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            ...balances.entries.map((entry) {
                              final name = entry.key;
                              final amt = entry.value;
                              final color = amt > 0 ? Colors.green : amt < 0 ? Colors.red : Colors.grey;
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2.0),
                                child: Text('$name: ${amt > 0 ? '+' : amt < 0 ? '-' : ''}₹${amt.abs().toStringAsFixed(2)}', style: TextStyle(fontSize: 13, color: color)),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Icon(Icons.celebration, color: Colors.amber, size: 36),
                    const Text('Share your group summary!', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
