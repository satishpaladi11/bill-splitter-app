import 'package:flutter/material.dart';
import '../utils/avatars.dart';
import '../utils/insights.dart';

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
    required this.members,
    required groupName,
  });

  @override
  Widget build(BuildContext context) {
  // Removed unused balancesScrollController
    // Use centralized avatar list

    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      margin: const EdgeInsets.all(12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Beautiful confetti/abstract illustration background
            CustomPaint(painter: ConfettiPainter(), child: Container()),
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
                                child: Text(
                                  appAvatars[avatarIndex],
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ),
                              Text(
                                m['name'] ?? '',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Small stats block (replaces expense listing in shared card)
                    Builder(builder: (stCtx) {
                      final insights = generateInsights(expenses, members, balances);
                      final expenseCount = (insights['expenseCount'] as int?) ?? 0;
                      final avgExpense = (insights['avgExpense'] as double?) ?? 0.0;
                      final biggest = (insights['biggestExpense'] as Map?) ?? {};
                      final biggestDesc = (biggest['desc'] as String?) ?? '';
                      final biggestAmt = (biggest['amount'] as double?) ?? 0.0;

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.78),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Quick stats', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Text('Expenses: $expenseCount', style: const TextStyle(fontSize: 13)),
                            const SizedBox(height: 4),
                            Text('Avg expense: ₹${avgExpense.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13)),
                            const SizedBox(height: 4),
                            Text('Biggest: ${biggestDesc.isNotEmpty ? biggestDesc : 'No note'} • ₹${biggestAmt.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 10),
                    // Insights summary (total, top/low spender, quick tip)
                    Builder(builder: (ctx) {
                      final insights = generateInsights(expenses, members, balances);
                      final total = (insights['totalSpent'] as double?) ?? 0.0;
                      final top = insights['topSpender'] as String? ?? '';
                      final topAmt = (insights['topAmount'] as double?) ?? 0.0;
                      final topPct = ((insights['spentPercent'] as Map?)?[top] as double?) ?? 0.0;
                      final low = insights['lowestSpender'] as String? ?? '';
                      final quote = insights['quote'] as String? ?? '';
                      final mostOwes = insights['mostOwes'] as String? ?? '';
                      final mostOwesAmt = (insights['mostOwesAmt'] as double?) ?? 0.0;

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total spend: ₹${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            if (top.isNotEmpty)
                              Text('Highest payer: $top • ₹${topAmt.toStringAsFixed(2)} (${topPct.toStringAsFixed(1)}%)', style: const TextStyle(fontSize: 13)),
                            if (low.isNotEmpty) const SizedBox(height: 4),
                            if (low.isNotEmpty)
                              Text('Saved most: $low', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                            const SizedBox(height: 8),
                            if (mostOwes.isNotEmpty && mostOwesAmt < -0.01)
                              Text('$mostOwes owes ₹${mostOwesAmt.abs().toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, color: Colors.orange)),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.indigo.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(quote, style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 10),
                    // Compact balances summary: only top 2, rest as 'see app'
                    Builder(builder: (ctx) {
                      if (balances.isEmpty) return const SizedBox.shrink();
                      final entries = balances.entries.toList();
                      entries.sort((a, b) => b.value.compareTo(a.value));
                      final mostOwed = entries.first;
                      final mostOwes = entries.last;
                      final showOthers = entries.length > 6;
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Balances', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            Text('${mostOwed.key}: +₹${mostOwed.value.abs().toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, color: Colors.green)),
                            Text('${mostOwes.key}: -₹${mostOwes.value.abs().toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, color: Colors.red)),
                            if (showOthers)
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text('Others: see app for details', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    const Icon(
                      Icons.celebration,
                      color: Colors.amber,
                      size: 36,
                    ),
                    const Text(
                      'Share your group summary!',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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
