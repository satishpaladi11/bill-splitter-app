// lib/utils/insights.dart
import 'dart:math';

/// Lightweight insights generator for group summaries.
/// Inputs:
/// - expenses: list of maps with 'amount' and 'payer'
/// - members: list of maps with 'name' and optional metadata
Map<String, dynamic> generateInsights(List<Map<String, dynamic>> expenses, List<Map<String, dynamic>> members, Map<String, double> balances) {
  final total = expenses.fold<double>(0.0, (p, e) => p + ((e['amount'] as num?)?.toDouble() ?? 0.0));
  final expenseCount = expenses.length;
  final avgExpense = expenseCount > 0 ? total / expenseCount : 0.0;
  String biggestDesc = '';
  double biggestAmt = 0.0;
  for (final e in expenses) {
    final amt = (e['amount'] as num?)?.toDouble() ?? 0.0;
    if (amt > biggestAmt) {
      biggestAmt = amt;
      biggestDesc = (e['desc'] as String?) ?? '';
    }
  }

  // total paid per member
  final Map<String, double> paid = {for (var m in members) (m['name'] as String? ?? ''): 0.0};
  for (final e in expenses) {
    final payer = (e['payer'] as String?) ?? '';
    final amt = (e['amount'] as num?)?.toDouble() ?? 0.0;
    if (!paid.containsKey(payer)) paid[payer] = 0.0;
    paid[payer] = (paid[payer] ?? 0.0) + amt;
  }

  String topSpender = '';
  String lowestSpender = '';
  double topAmt = 0.0;
  double lowAmt = double.infinity;
  if (paid.isNotEmpty) {
    paid.forEach((k, v) {
      if (v > topAmt) {
        topAmt = v;
        topSpender = k;
      }
      if (v < lowAmt) {
        lowAmt = v;
        lowestSpender = k;
      }
    });
    if (lowAmt == double.infinity) lowAmt = 0.0;
  }

  // percentages of total spent
  final Map<String, double> spentPercent = {};
  if (total > 0) {
    paid.forEach((k, v) => spentPercent[k] = (v / total) * 100.0);
  } else {
    paid.forEach((k, v) => spentPercent[k] = 0.0);
  }

  // ensure lowestSpender is set even if all paid zeros
  if (lowestSpender.isEmpty && paid.isNotEmpty) {
    lowestSpender = paid.keys.first;
  }

  // who owes most (negative balance) and who is owed most (positive)
  String mostOwes = '';
  String mostOwed = '';
  double mostOwesAmt = 0.0;
  double mostOwedAmt = 0.0;
  balances.forEach((k, v) {
    if (v < mostOwesAmt) {
      mostOwesAmt = v;
      mostOwes = k;
    }
    if (v > mostOwedAmt) {
      mostOwedAmt = v;
      mostOwed = k;
    }
  });

  // friendly quotes pool
  // Simpler, India-friendly short quotes (light-hearted, non-offensive)
  final Map<String, List<String>> quotes = {
    'top': [
      "Arre {name}, sabse zyada kharcha kiya! Next party tere ghar? 😄",
      "{name}, top spender! Chai treat kab de raha hai? ☕",
      "{name}, group ka Ambani! Thanks for spending. 🙌",
      "{name}, bill ka baap! Sabko impress kar diya. 🤑",
      "{name}, kharchi machine! Group ka hero. 🦸",
      "{name}, paisa udane me no.1! Ab savings bhi sikho. 😂",
      "{name}, kharchi king! Sabko party chahiye ab. 🎉",
      "{name}, group ka ATM! Sabko treat milni chahiye. 🏦",
      "{name}, kharchi ke baare me sabko puchho! 😅",
    ],
    'low': [
      "{name}, bachat ka baap! Sabko sikha diya kaise paisa bachate hain. 😎",
      "{name}, pocket-saver! Frugal king/queen. 💪",
      "{name}, jugaadu spending — respect! 👍",
      "{name}, paisa bachane ka sahi tareeka dikhaya! 👏",
      "{name}, group ka Lakshman — hamesha budget me! 🛡️",
      "{name}, bachat ke chakkar me party miss mat karna! 😜",
      "{name}, paisa bachane me master! Next time treat tu de. 🍽️",
      "{name}, group ka accountant! Sabko budget sikha diya. 📊",
      "{name}, bachat ke baare me TED talk de sakte ho! 🎤",
    ],
    'settle': [
      "Oye {name}, ab settle karle, warna group me meme ban jayega! 😂",
      "{name}, payment bhej de, group ka balance sahi ho jayega.",
      "{name}, ek transfer kar, sab khush ho jayenge! 💸",
      "{name}, ab to UPI kar de, sab intezaar kar rahe hain! 📲",
      "{name}, settle nahi kiya to next time treat double! 🍽️",
      "{name}, ab to paisa bhej de, warna group se nikal denge! 😆",
      "{name}, payment pending hai, sabko tension ho rahi hai! 😬",
      "{name}, settle kar, warna group me roast ho jayega! 🔥",
      "{name}, ab to transfer kar, sabko peace milega! 🕊️",
    ],
    'neutral': [
      "Sab milke theek kar rahe hain — nice teamwork! 🤝",
      "Balance sahi hai — keep it up! 🎉",
      "Sab fit hai — koi jhagde nahi. 😄",
      "Group mast hai, sab chill hai! 😌",
      "Koi tension nahi, sab sahi chal raha hai. 👍",
      "Group me sab shaant hai, mast vibe hai! 🧘",
      "Sab log milke kharch kar rahe hain, sahi hai! 👏",
      "Group me sab ekdum sorted hai, no drama! 🎬",
      "Sab log milke enjoy kar rahe hain, full masti! 🥳",
    ],
    'busy': [
      "Group mast chal raha hai — bahut saare kharche! 🔥",
      "Roz roz kharcha — party chal rahi hai! 🎊",
      "Expenses ka railway station — sab aa rahe hain. 🚂",
      "Group me aaj kal full on activity hai! 🕺",
      "Kharche dekh ke lagta hai, sab log foodie hain! 🍕",
      "Group me har din naya kharcha, full on masti! 🤩",
      "Group ka kharcha dekh ke lagta hai, sab log rich hai! 💰",
      "Group me kharcha ka tsunami aa gaya hai! 🌊",
      "Group me har din party, sab log bindass! 🥂",
    ],
  };

  final rand = Random();
  String pickQuote(String tag, {String member = ''}) {
    final list = quotes[tag] ?? quotes['neutral']!;
    var q = list[rand.nextInt(list.length)];
    if (q.contains('{name}')) {
      q = q.replaceAll('{name}', member);
    }
    return q;
  }

  // Choose quote with clearer precedence and thresholds so 'settle' isn't overused
  const oweThreshold = 100.0; // require meaningful owe to use settle quotes
  final topPct = (spentPercent[topSpender] ?? 0.0);
  final lowestPct = (spentPercent[lowestSpender] ?? 0.0);

  String quote;
  if (total <= 0.0) {
    quote = pickQuote('neutral');
  } else if (topPct >= 50.0 && topSpender.isNotEmpty) {
    quote = pickQuote('top', member: topSpender);
  } else if (expenseCount >= 10 && avgExpense > 2000) {
    quote = pickQuote('busy');
  } else if ((lowestPct) < 5.0 && lowestSpender.isNotEmpty) {
    quote = pickQuote('low', member: lowestSpender);
  } else if (mostOwesAmt <= -oweThreshold && mostOwes.isNotEmpty) {
    quote = pickQuote('settle', member: mostOwes);
  } else {
    quote = pickQuote('neutral');
  }

  return {
    'totalSpent': total,
    'paidTotals': paid,
    'spentPercent': spentPercent,
    'topSpender': topSpender,
    'topAmount': topAmt,
    'lowestSpender': lowestSpender,
    'lowestAmount': lowAmt == double.infinity ? 0.0 : lowAmt,
    'mostOwes': mostOwes,
    'mostOwesAmt': mostOwesAmt,
    'mostOwed': mostOwed,
    'mostOwedAmt': mostOwedAmt,
  'quote': quote,
  'expenseCount': expenseCount,
  'avgExpense': avgExpense,
  'biggestExpense': {'desc': biggestDesc, 'amount': biggestAmt},
  };
}
