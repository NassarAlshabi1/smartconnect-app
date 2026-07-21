import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditVoucherDialog extends StatefulWidget {
  final DocumentSnapshot document;

  const EditVoucherDialog({super.key, required this.document});

  @override
  State<EditVoucherDialog> createState() => _EditVoucherDialogState();
}

class _EditVoucherDialogState extends State<EditVoucherDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _codeController;
  String? selectedPackage;
  String? selectedNetwork;
  DateTime? expiryDate;

  List<String> networkOptions = [];
  List<String> packageOptions = [];

  bool isLoadingNetworks = true;
  bool isLoadingPackages = true;

  @override
  void initState() {
    super.initState();
    final data = widget.document.data() as Map<String, dynamic>;
    _codeController = TextEditingController(text: data['code']);
    selectedPackage = data['package'];
    selectedNetwork = data['network'];
    expiryDate = (data['expiry'] as Timestamp).toDate();
    _loadNetworkOptions();
    _loadPackageOptions();
  }

  Future<void> _loadNetworkOptions() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('networks').get();
      final names = snapshot.docs.map((doc) => doc['name'].toString()).toList();

      if (selectedNetwork != null && !names.contains(selectedNetwork)) {
        names.add(selectedNetwork!);
      }

      setState(() {
        networkOptions = names;
        isLoadingNetworks = false;
      });
    } catch (e) {
      setState(() => isLoadingNetworks = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Failed to load networks: $e')),
      );
    }
  }

  Future<void> _loadPackageOptions() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('voucher_packages').get();
      final names = snapshot.docs.map((doc) => doc['name'].toString()).toList();

      if (selectedPackage != null && !names.contains(selectedPackage)) {
        names.add(selectedPackage!);
      }

      setState(() {
        packageOptions = names;
        isLoadingPackages = false;
      });
    } catch (e) {
      setState(() => isLoadingPackages = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Failed to load packages: $e')),
      );
    }
  }

  Future<void> _updateVoucher() async {
    if (_formKey.currentState!.validate() && expiryDate != null) {
      await widget.document.reference.update({
        'code': _codeController.text.trim(),
        'package': selectedPackage,
        'network': selectedNetwork,
        'expiry': Timestamp.fromDate(expiryDate!),
      });
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = isLoadingNetworks || isLoadingPackages;

    return AlertDialog(
      title: const Text('Edit Voucher'),
      content: isLoading
          ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
          : SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _codeController,
                      decoration: const InputDecoration(labelText: 'Voucher Code'),
                      validator: (val) =>
                          val == null || val.trim().isEmpty ? 'Enter code' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedNetwork,
                      decoration: const InputDecoration(labelText: 'Network Name'),
                      items: networkOptions.map((network) {
                        return DropdownMenuItem(value: network, child: Text(network));
                      }).toList(),
                      onChanged: (val) => setState(() => selectedNetwork = val),
                      validator: (val) => val == null ? 'Choose network' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedPackage,
                      decoration: const InputDecoration(labelText: 'Package'),
                      items: packageOptions.map((pkg) {
                        return DropdownMenuItem(value: pkg, child: Text(pkg));
                      }).toList(),
                      onChanged: (val) => setState(() => selectedPackage = val),
                      validator: (val) => val == null ? 'Select package' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            expiryDate == null
                                ? 'No date selected'
                                : 'Expiry: ${expiryDate!.toLocal().toString().split(' ')[0]}',
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: expiryDate ?? DateTime.now(),
                              firstDate: DateTime.now().subtract(const Duration(days: 1)),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setState(() => expiryDate = picked);
                            }
                          },
                          child: const Text('Change Date'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: _updateVoucher, child: const Text('Update')),
      ],
    );
  }
}