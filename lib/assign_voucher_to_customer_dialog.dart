import 'package:flutter/material.dart';

class AssignVoucherToCustomerDialog extends StatelessWidget {
  final String customerUid;
  const AssignVoucherToCustomerDialog({super.key, required this.customerUid});
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Assign voucher'),
    content: const Text('Voucher assignment is unavailable in offline mode.'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Close'),
      ),
    ],
  );
}
