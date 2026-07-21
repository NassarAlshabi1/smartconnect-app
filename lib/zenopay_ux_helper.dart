import 'package:flutter/material.dart';

class ZenopayUXHelper {
  /// ⏳ Show a SnackBar when USSD request is assumed sent but no response yet
  static void showUSSDWaitingMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⏳ Request sent. Waiting for USSD confirmation...'),
        duration: Duration(seconds: 6),
      ),
    );
  }

  /// ❌ Show a graceful fallback when Zenopay fails to respond
  static void handleTimeoutGracefully(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Network Delay'),
        content: const Text(
          'Zenopay is taking longer than expected to respond. Please wait for the USSD prompt on your phone. If it doesn’t arrive, you may retry.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  /// ✅ Show confirmation when payment is completed
  static void showPaymentCompleted(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Payment completed successfully!'),
        duration: Duration(seconds: 4),
      ),
    );
  }

  /// 🔁 Show retry option when payment is still pending
  static void showRetryOption(BuildContext context, VoidCallback onRetry) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Payment Pending'),
        content: const Text(
          'Your payment is still pending. Would you like to retry checking the status?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry();
            },
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }
}