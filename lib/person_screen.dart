import 'package:flutter/material.dart';
import 'package:smartconnect/local_backend.dart';

class PersonScreen extends StatelessWidget {
  const PersonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Feedback'),
        backgroundColor: Colors.teal.shade700,
      ),
      body: StreamBuilder<LocalQuerySnapshot>(
        stream: LocalFirestore.instance
            .collection('feedbacks')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final messages = snapshot.data?.docs ?? [];

          if (messages.isEmpty) {
            return const Center(
              child: Text(
                '📭 No messages from customers',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            );
          }

          return ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final doc = messages[index];
              final data = doc.data();

              final message = data['message'] ?? '';
              final timestamp = data['timestamp'] as Timestamp?;
              final isUnread = data['status'] == 'unread';
              final userId = data['user_id'] ?? 'Unknown';

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: isUnread ? Colors.teal.shade50 : Colors.grey.shade100,
                child: ListTile(
                  leading: Icon(
                    isUnread ? Icons.markunread : Icons.mail,
                    color: isUnread ? Colors.redAccent : Colors.grey,
                  ),
                  title: Text(
                    message,
                    style: TextStyle(
                      fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    'User ID: $userId',
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  trailing: Text(
                    _formatTimestamp(timestamp),
                    style: const TextStyle(fontSize: 11, color: Colors.black45),
                  ),
                  onTap: () {
                    if (isUnread) {
                      doc.reference.update({'status': 'read'});
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}