import 'package:flutter/material.dart';
import 'package:smartconnect/local_backend.dart';
import 'package:intl/intl.dart';

class UsageHistoryScreen extends StatelessWidget {
  final String userId;

  const UsageHistoryScreen({required this.userId, super.key});

  @override
  Widget build(BuildContext context) {
    final usageRef = LocalFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('usageHistory')
        .orderBy('timestamp', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Usage History'),
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder<LocalQuerySnapshot>(
        stream: usageRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) return const Center(child: Text('No usage history found.'));

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
              final formattedDate = timestamp != null
                  ? DateFormat('dd MMM yyyy, hh:mm a').format(timestamp)
                  : 'Unknown time';

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: Icon(Icons.history, color: Colors.deepPurple),
                  title: Text(data['type'] ?? 'Unknown'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['description'] ?? ''),
                      const SizedBox(height: 4),
                      Text('$formattedDate • ${data['channel'] ?? 'Unknown'}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  trailing: Chip(
                    label: Text(data['status'] ?? 'Pending',
                        style: const TextStyle(color: Colors.white)),
                    backgroundColor: _statusColor(data['status']),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'success':
        return Colors.green;
      case 'failed':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}