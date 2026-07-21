import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewVoucherDialog extends StatelessWidget {
  final Map<String, dynamic> voucher;

  const ViewVoucherDialog({super.key, required this.voucher});

  @override
  Widget build(BuildContext context) {
    final expiry = (voucher['expiry'] as Timestamp).toDate();

    return AlertDialog(
      title: const Text('Voucher Details'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Code: ${voucher['code']}'),
          Text('Network: ${voucher['network']}'),
          Text('Package: ${voucher['package']}'),
          Text('Status: ${voucher['status']}'),
          Text('Expiry: ${expiry.toLocal().toString().split(' ')[0]}'),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
      ],
    );
  }
}