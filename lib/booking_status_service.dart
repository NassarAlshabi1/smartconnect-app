import 'package:smartconnect/local_backend.dart';

class BookingStatusService {
  /// ✅ Check status by reading Firestore transaction document
  static Future<String> checkStatus(String orderTrackingId) async {
    try {
      final doc = await LocalFirestore.instance
          .collection('transactions')
          .doc(orderTrackingId)
          .get();

      if (!doc.exists) return "NOT_FOUND";

      final status = doc.data()?['status']?.toString().toUpperCase();

      if (status == "COMPLETED" || status == "SUCCESS") {
        return "COMPLETED";
      } else if (status == "PENDING" || status == "INITIATED" || status == "PROCESSING") {
        return "PENDING";
      } else if (status == "FAIL" || status == "FAILED" || status == "CANCELLED") {
        return "FAIL";
      } else {
        return "UNKNOWN";
      }
    } catch (e) {
      print('❌ Exception in checkStatus: $e');
      return "ERROR";
    }
  }

  /// ✅ Fetch transaction details from Firestore
  static Future<Map<String, dynamic>> fetchDetails(String orderTrackingId) async {
    try {
      final doc = await LocalFirestore.instance
          .collection('transactions')
          .doc(orderTrackingId)
          .get();

      if (!doc.exists) return {};

      final data = doc.data()!;

      if (data['assigned_voucher'] == null || data['assigned_voucher'] == '') {
        print('⚠️ No voucher assigned yet for order $orderTrackingId');
      }

      return {
        'transid': data['transid'] ?? '',
        'channel': data['channel'] ?? '',
        'msisdn': data['phone'] ?? '',
        'reference': data['reference'] ?? data['order_id'] ?? '',
        'amount': data['amount'] ?? 0,
        'network': data['network'] ?? '',
        'package': data['package'] ?? '',
        'status': data['status'] ?? '',
        'assigned_voucher': data['assigned_voucher'] ?? '',
        'assigned_at': data['assigned_at'] != null
            ? (data['assigned_at'] as Timestamp).toDate()
            : DateTime.now().add(const Duration(days: 1)), // fallback expiry
      };
    } catch (e) {
      print('❌ Exception in fetchDetails: $e');
      return {};
    }
  }
}