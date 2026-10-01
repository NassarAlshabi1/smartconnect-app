import 'package:flutter/material.dart';
import 'package:smartconnect/local_database.dart';
import 'package:smartconnect/local_auth_service.dart';
import 'package:intl/intl.dart';

class CustomerNotificationScreen extends StatelessWidget {
  const CustomerNotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.instance.currentUser!.uid;
    final notificationsRef = LocalDatabase.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('sent_at', descending: true); // fallback field

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: notificationsRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('No notifications yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final timestamp =
                  (data['sent_at'] ?? data['timestamp']) as Timestamp?;
              final formattedDate = timestamp != null
                  ? DateFormat(
                      'dd MMM yyyy, hh:mm a',
                    ).format(timestamp.toDate())
                  : 'Unknown time';

              final isUnread = data['status'] == 'unread';

              return GestureDetector(
                onTap: () async {
                  if (isUnread) {
                    try {
                      await doc.reference.update({'status': 'read'});
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('⚠️ Failed to mark as read: $e'),
                        ),
                      );
                    }
                  }
                },
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: Stack(
                        children: [
                          const Icon(
                            Icons.notifications,
                            color: Colors.deepPurple,
                            size: 28,
                          ),
                          if (isUnread)
                            Positioned(
                              right: -2,
                              top: -2,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                      title: Text(
                        data['message'] ?? 'No message',
                        style: TextStyle(
                          fontWeight: isUnread
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        formattedDate,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      trailing: Text(
                        isUnread ? 'Unread' : 'Read',
                        style: TextStyle(
                          color: isUnread ? Colors.red : Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
