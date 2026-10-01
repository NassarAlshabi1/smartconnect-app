import 'package:flutter/material.dart';
import 'package:smartconnect/local_database.dart';

class MostFrequentPayers extends StatelessWidget {
  final DateTime month;
  final List<DocumentSnapshot> payments;

  const MostFrequentPayers({
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

    final Map<String, int> frequency = {};
    for (final doc in filtered) {
      final rawName = doc['buyer_name'];
      final name = rawName == null || rawName.toString().trim().isEmpty
          ? 'Unknown'
          : rawName.toString().trim();
      frequency[name] = (frequency[name] ?? 0) + 1;
    }

    final topPayers = frequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top5 = topPayers.take(5).toList();

    return Card(
      color: Colors.deepPurple.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🔁 Most Frequent Payers',
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
                (entry) => ListTile(
                  leading: const Icon(Icons.repeat, color: Colors.white70),
                  title: Text(
                    entry.key,
                    style: const TextStyle(color: Colors.white),
                  ),
                  trailing: Text(
                    '${entry.value} payments',
                    style: const TextStyle(
                      color: Colors.deepPurpleAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
