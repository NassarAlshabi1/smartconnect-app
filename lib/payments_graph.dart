import 'package:smartconnect/local_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PaymentsGraph extends StatelessWidget {
  final DateTime selectedMonth;
  const PaymentsGraph({super.key, required this.selectedMonth});

  Future<Map<String, double>> getPaymentsPerDay() async {
    final start = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final end = DateTime(selectedMonth.year, selectedMonth.month + 1, 1);

    final query = await LocalDatabase.instance
        .collection('transactions')
        .where('status', isEqualTo: 'COMPLETED')
        .where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('created_at', isLessThan: Timestamp.fromDate(end))
        .get();

    Map<String, double> dailyTotals = {};

    for (var doc in query.docs) {
      final timestamp = doc['created_at'] as Timestamp?;
      final date = timestamp?.toDate();
      if (date == null) continue;

      final dayKey = DateFormat('d MMM').format(date); // e.g. "6 Jul"
      final amount = (doc['amount'] ?? 0.0).toDouble();

      dailyTotals[dayKey] = (dailyTotals[dayKey] ?? 0.0) + amount;
    }

    return dailyTotals;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, double>>(
      future: getPaymentsPerDay(),
      builder: (context, snapshot) {
        final data = snapshot.data ?? {};

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (data.isEmpty) {
          return Container(
            height: 180,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Text(
              'No payment data to display yet 📉',
              style: TextStyle(color: Colors.white38),
            ),
          );
        }

        final sortedKeys = data.keys.toList()
          ..sort((a, b) {
            final aDate = DateFormat('d MMM').parse(a);
            final bDate = DateFormat('d MMM').parse(b);
            return aDate.compareTo(bDate);
          });

        final barGroups = sortedKeys.map((key) {
          final index = sortedKeys.indexOf(key);
          final value = data[key]!;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: value,
                color: Colors.tealAccent,
                width: 14,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }).toList();

        return AspectRatio(
          aspectRatio: 1.6,
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: const Color(0xFF002A4A),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: BarChart(
                BarChartData(
                  barGroups: barGroups,
                  backgroundColor: Colors.transparent,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          final label = sortedKeys[value.toInt()];
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              label,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
