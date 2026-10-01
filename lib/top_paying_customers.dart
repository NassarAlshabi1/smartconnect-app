import 'package:flutter/material.dart';
import 'package:smartconnect/local_database.dart';

class TopPayingCustomers extends StatelessWidget {
  final DateTime month;
  final List<DocumentSnapshot> payments;

  const TopPayingCustomers({
    super.key,
    required this.month,
    required this.payments,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = payments.where((doc) {
      final raw = doc['created_at'];
      if (raw is! Timestamp) return false;
      final date = raw.toDate();
      return date.month == month.month && date.year == month.year;
    }).toList();

    final Map<String, double> totals = {};
    for (final doc in filtered) {
      final rawName = doc['buyer_name'];
      final name = rawName == null || rawName.toString().trim().isEmpty
          ? 'Unknown'
          : rawName.toString().trim();

      final amount = (doc['amount'] is num) ? doc['amount'].toDouble() : 0.0;
      totals[name] = (totals[name] ?? 0) + amount;
    }

    final topCustomers = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top5 = topCustomers.take(5).toList();

    return Card(
      color: Colors.teal.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🏆 Top Paying Customers',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            if (top5.isEmpty)
              const Text(
                'No completed payments found.',
                style: TextStyle(color: Colors.white70),
              )
            else
              ...top5.map(
                (entry) => Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person, color: Colors.white70),
                      title: Text(
                        entry.key,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                      trailing: Text(
                        'TSh ${entry.value.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.tealAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const Divider(color: Colors.white12, thickness: 0.5),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
