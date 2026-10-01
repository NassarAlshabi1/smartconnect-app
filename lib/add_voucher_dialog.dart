import 'package:flutter/material.dart';
import 'package:smartconnect/local_backend.dart';

class AddVoucherDialog extends StatefulWidget {
  const AddVoucherDialog({super.key});

  @override
  State<AddVoucherDialog> createState() => _AddVoucherDialogState();
}

class _AddVoucherDialogState extends State<AddVoucherDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();

  String? selectedNetwork;
  String? selectedPackage;
  DateTime? expiryDate;

  List<String> networkOptions = [];
  List<String> packageOptions = [];

  bool isLoadingNetworks = true;
  bool isLoadingPackages = true;

  @override
  void initState() {
    super.initState();
    _loadNetworkOptions();
    _loadPackageOptions();
  }

  Future<void> _loadNetworkOptions() async {
    try {
      final snapshot = await LocalFirestore.instance.collection('networks').get();
      final names = snapshot.docs.map((doc) => doc['name'].toString()).toList();
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
      final snapshot = await LocalFirestore.instance.collection('voucher_packages').get();
      final names = snapshot.docs.map((doc) => doc['name'].toString()).toList();
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

  Future<void> _submitVoucher() async {
    if (_formKey.currentState!.validate() && expiryDate != null) {
      await LocalFirestore.instance.collection('vouchers').add({
        'code': _codeController.text.trim(),
        'network': selectedNetwork,
        'package': selectedPackage,
        'status': 'available',
        'expiry': Timestamp.fromDate(expiryDate!),
        'created_at': Timestamp.now(),
      });

      Navigator.pop(context); // close dialog
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = isLoadingNetworks || isLoadingPackages;

    return AlertDialog(
      title: const Text('Add New Voucher'),
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
                      value: selectedNetwork,
                      decoration: const InputDecoration(labelText: 'Network Name'),
                      items: networkOptions.map((network) {
                        return DropdownMenuItem(value: network, child: Text(network));
                      }).toList(),
                      onChanged: (val) => setState(() => selectedNetwork = val),
                      validator: (val) => val == null ? 'Choose network' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedPackage,
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
                              initialDate: DateTime.now().add(const Duration(days: 1)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setState(() => expiryDate = picked);
                            }
                          },
                          child: const Text('Pick Expiry Date'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: _submitVoucher, child: const Text('Add')),
      ],
    );
  }
}