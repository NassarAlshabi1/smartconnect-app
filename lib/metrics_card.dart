import 'package:flutter/material.dart';

class MetricsCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;

  const MetricsCard({
    super.key,
    required this.icon,
    required this.label,
    required this.count,
    this.color = Colors.orange,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 160;

        return Card(
          elevation: 3,
          color: Colors.white.withValues(alpha: 0.95),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: isSmallScreen ? 30 : 36, color: color),
                const SizedBox(height: 10),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12.5 : 14.5,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: isSmallScreen ? 20 : 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}