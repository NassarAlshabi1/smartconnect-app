import 'package:flutter/material.dart';
import 'package:smartconnect/local_database.dart';
import 'package:fl_chart/fl_chart.dart';

class PaymentMethodBreakdown extends StatelessWidget {
  final DateTime month;
  final List<DocumentSnapshot> payments;

  const PaymentMethodBreakdown({
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

    if (filtered.isEmpty) {
      return const Card(
        color: Colors.blueGrey,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'No completed payments found for this month.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    final Map<String, int> channelCounts = {};
    for (final doc in filtered) {
      final rawChannel = doc['channel'];
      final channel = rawChannel == null || rawChannel.toString().trim().isEmpty
          ? 'Unknown'
          : rawChannel.toString().trim();
      channelCounts[channel] = (channelCounts[channel] ?? 0) + 1;
    }

    final total = channelCounts.values.fold<int>(0, (a, b) => a + b);
    final colors = [Colors.teal, Colors.orange, Colors.purple, Colors.blue];

    return Card(
      color: Colors.blueGrey.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 Payment Method Breakdown',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: channelCounts.entries.mapIndexed((index, entry) {
                    final percentage = (entry.value / total * 100)
                        .toStringAsFixed(1);
                    return PieChartSectionData(
                      color: colors[index % colors.length],
                      value: entry.value.toDouble(),
                      title: '${entry.key}\n$percentage%',
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 30,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension<E> on Iterable<E> {
  Iterable<T> mapIndexed<T>(T Function(int index, E item) f) {
    var index = 0;
    return map((e) => f(index++, e));
  }
}
