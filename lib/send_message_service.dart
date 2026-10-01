import 'package:smartconnect/local_database.dart';

class SendMessageService {
  static Future<void> sendMessageToAllCustomers({
    required String message,
  }) async {
    final usersRef = LocalDatabase.instance.collection('users');
    final customers = await usersRef.where('role', isEqualTo: 'customer').get();

    final batch = LocalDatabase.instance.batch();
    final now = DateTime.now();

    for (final doc in customers.docs) {
      final userId = doc.id;
      final notifRef = usersRef.doc(userId).collection('notifications').doc();

      batch.set(notifRef, {
        'message': message,
        'status': 'unread',
        'sent_at': Timestamp.fromDate(now),
        'sender': 'admin',
        'type': 'broadcast',
      });
    }

    await batch.commit();
  }
}
