import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AssignVoucherToCustomerDialog extends StatefulWidget {
  final String customerUid;
  final String customerName;

  const AssignVoucherToCustomerDialog({
    super.key,
    required this.customerUid,
    required this.customerName,
  });

  @override
  State<AssignVoucherToCustomerDialog> createState() =>
      _AssignVoucherToCustomerDialogState();
}

class _AssignVoucherToCustomerDialogState
    extends State<AssignVoucherToCustomerDialog> {
  String? _selectedVoucherId;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Assign Voucher to ${widget.customerName}'),
      content: SizedBox(
        width: double.maxFinite,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('vouchers')
              .where('status', isEqualTo: 'active')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Text('No active vouchers available.');
            }
            return DropdownButtonFormField<String>(
              initialValue: _selectedVoucherId,
              decoration: const InputDecoration(
                labelText: 'Select Voucher',
                border: OutlineInputBorder(),
              ),
              items: snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return DropdownMenuItem<String>(
                  value: doc.id,
                  child: Text('${data['name'] ?? 'Voucher'} - ${data['value'] ?? 0}'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedVoucherId = value;
                });
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading || _selectedVoucherId == null
              ? null
              : () async {
                  setState(() => _isLoading = true);
                  try {
                    await FirebaseFirestore.instance
                        .collection('customer_vouchers')
                        .add({
                      'customerUid': widget.customerUid,
                      'customerName': widget.customerName,
                      'voucherId': _selectedVoucherId,
                      'assignedAt': FieldValue.serverTimestamp(),
                      'status': 'assigned',
                    });
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Voucher assigned successfully')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Assign'),
        ),
      ],
    );
  }
}
