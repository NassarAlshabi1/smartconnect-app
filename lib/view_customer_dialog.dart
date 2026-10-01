import 'package:flutter/material.dart';
import 'package:smartconnect/local_backend.dart';
import 'package:intl/intl.dart';
import 'package:smartconnect/assign_voucher_to_customer_dialog.dart';

class ViewCustomerDialog extends StatelessWidget {
  final LocalDocSnapshot document;

  const ViewCustomerDialog({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    final data = document.data() as Map<String, dynamic>;
    final uid = document.id;
    final name = data['full_name'] ?? 'Unknown';
    final phone = data['phone_number'] ?? 'N/A';
    final joined = (data['created_at'] as Timestamp?)?.toDate();
    final joinedFormatted =
        joined != null ? DateFormat('yyyy-MM-dd – kk:mm').format(joined) : 'N/A';
    final status = (data['status'] ?? 'active').toString();

    return AlertDialog(
      scrollable: true,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Customer Details'),
          Chip(
            label: Text(
              status.toUpperCase(),
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: status == 'active' ? Colors.green : Colors.red,
          ),
        ],
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow('Full Name', name),
          _infoRow('Phone Number', phone),
          _infoRow('Joined At', joinedFormatted),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => ViewVoucherHistoryDialog(customerUid: uid),
              );
            },
            child: const Text(
              'View voucher history',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 13,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            showDialog(
              context: context,
              builder: (_) => AssignVoucherToCustomerDialog(
                customerUid: uid,
                customerName: name,
              ),
            );
          },
          child: const Text('Assign Voucher'),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: status == 'active' ? Colors.red : Colors.green,
          ),
          onPressed: () async {
            final newStatus = status == 'active' ? 'inactive' : 'active';
            await LocalFirestore.instance
                .collection('users')
                .doc(uid)
                .update({'status': newStatus});
            Navigator.pop(context);
          },
          icon: Icon(status == 'active' ? Icons.block : Icons.check_circle),
          label: Text(status == 'active' ? 'Deactivate' : 'Reactivate'),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class ViewVoucherHistoryDialog extends StatelessWidget {
  final String customerUid;

  const ViewVoucherHistoryDialog({super.key, required this.customerUid});

  @override
  Widget build(BuildContext context) {
    final vouchersRef = LocalFirestore.instance
        .collection('vouchers')
        .where('assigned_to.uid', isEqualTo: customerUid);

    return AlertDialog(
      title: const Text('Voucher History'),
      content: SizedBox(
        width: double.maxFinite,
        child: StreamBuilder<LocalQuerySnapshot>(
          stream: vouchersRef.snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator(strokeWidth: 2));
            }

            final docs = snapshot.data!.docs;

            if (docs.isEmpty) {
              return const Text(
                'No vouchers assigned.',
                style: TextStyle(color: Colors.black54),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final v = docs[index].data();
                final code = v['code'] ?? '';
                final pkg = v['package'] ?? '';
                final net = v['network'] ?? '';
                final status = v['status'] ?? '';
                final assignedAt = (v['assigned_at'] as Timestamp?)?.toDate();
                final dateStr = assignedAt != null
                    ? DateFormat('yyyy-MM-dd').format(assignedAt)
                    : 'N/A';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Code: $code', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('Package: $pkg'),
                        Text('Network: $net'),
                        Text('Status: $status'),
                        Text('Assigned: $dateStr'),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}