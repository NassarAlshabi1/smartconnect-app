import 'package:flutter/material.dart';
import 'package:smartconnect/local_database.dart';

class InactiveCustomers extends StatelessWidget {
  final DateTime currentMonth;
  final List<DocumentSnapshot> payments;

  const InactiveCustomers({
    super.key,
    required this.currentMonth,
    required this.payments,
  });

  @override
  Widget build(BuildContext context) {
    final currentStart = DateTime(currentMonth.year, currentMonth.month, 1);
    final currentEnd = DateTime(currentMonth.year, currentMonth.month + 1, 1);
    final previousStart = DateTime(
      currentMonth.year,
      currentMonth.month - 1,
      1,
    );
    final previousEnd = DateTime(currentMonth.year, currentMonth.month, 1);

    final previousCustomers = <String, String>{};
    final currentCustomerIds = <String>{};

    for (final doc in payments) {
      final raw = doc['created_at'];
      if (raw is! Timestamp) continue;
      final date = raw.toDate();
      final status = doc['status']?.toString() ?? '';
      if (status != 'COMPLETED') continue;

      final id = doc['customer_id']?.toString() ?? '';
      final rawName = doc['buyer_name'];
      final name = rawName == null || rawName.toString().trim().isEmpty
          ? 'Unknown'
          : rawName.toString().trim();

      if (id.isEmpty) continue;

      if (date.isAfter(previousStart) && date.isBefore(previousEnd)) {
        previousCustomers[id] = name;
      }

      if (date.isAfter(currentStart) && date.isBefore(currentEnd)) {
        currentCustomerIds.add(id);
      }
    }

    final inactive =
        previousCustomers.entries
            .where((entry) => !currentCustomerIds.contains(entry.key))
            .toList()
          ..sort((a, b) => a.value.compareTo(b.value));

    return Card(
      color: Colors.orange.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🕒 Inactive Customers (Compared to Last Month)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            if (inactive.isEmpty)
              const Text(
                '✅ All previous customers have paid this month.',
                style: TextStyle(color: Colors.greenAccent),
              )
            else
              ...inactive.map(
                (entry) => ListTile(
                  leading: const Icon(Icons.person_off, color: Colors.white70),
                  title: Text(
                    entry.value,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    'ID: ${entry.key}',
                    style: const TextStyle(color: Colors.white54),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
