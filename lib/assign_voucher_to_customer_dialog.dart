import 'package:flutter/material.dart';
import 'package:smartconnect/local_backend.dart';

/// Dialog that assigns one of the available vouchers to a customer.
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
  bool _isLoading = true;
  bool _isAssigning = false;
  List<LocalQueryDocSnapshot> _availableVouchers = [];
  String? _selectedVoucherId;

  @override
  void initState() {
    super.initState();
    _loadAvailableVouchers();
  }

  Future<void> _loadAvailableVouchers() async {
    try {
      final snapshot = await LocalFirestore.instance
          .collection('vouchers')
          .where('status', isEqualTo: 'available')
          .get();

      if (!mounted) return;
      setState(() {
        _availableVouchers = snapshot.docs;
        _isLoading = false;
        if (_availableVouchers.isNotEmpty) {
          _selectedVoucherId = _availableVouchers.first.id;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Failed to load vouchers: $e')),
      );
    }
  }

  Future<void> _assignVoucher() async {
    if (_selectedVoucherId == null) return;

    setState(() => _isAssigning = true);

    try {
      await LocalFirestore.instance
          .collection('vouchers')
          .doc(_selectedVoucherId)
          .update({
        'assigned_to': widget.customerUid,
        'status': 'assigned',
        'assigned_at': Timestamp.now(),
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '✅ Voucher assigned to ${widget.customerName} successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAssigning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Failed to assign voucher: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Assign Voucher to ${widget.customerName}'),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading
            ? const Center(
                child: SizedBox(
                  height: 32,
                  width: 32,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : _availableVouchers.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'No available vouchers. Add vouchers first.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _availableVouchers.length,
                    itemBuilder: (context, index) {
                      final voucher = _availableVouchers[index];
                      final selected = voucher.id == _selectedVoucherId;
                      return ListTile(
                        leading: Icon(
                          selected
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: selected ? Colors.orange : Colors.grey,
                        ),
                        title: Text(
                          voucher['code']?.toString() ?? 'Voucher',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${voucher['network'] ?? ''} - ${voucher['package'] ?? ''}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        onTap: () =>
                            setState(() => _selectedVoucherId = voucher.id),
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
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange[700],
          ),
          onPressed:
              (_isLoading || _isAssigning || _selectedVoucherId == null)
                  ? null
                  : _assignVoucher,
          child: _isAssigning
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Assign'),
        ),
      ],
    );
  }
}
