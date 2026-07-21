import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartconnect/add_voucher_dialog.dart';
import 'package:smartconnect/edit_voucher_dialog.dart';
import 'package:smartconnect/view_voucher_dialog.dart';

class VoucherManagementScreen extends StatefulWidget {
  const VoucherManagementScreen({super.key});

  @override
  State<VoucherManagementScreen> createState() => _VoucherManagementScreenState();
}

class _VoucherManagementScreenState extends State<VoucherManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';
  String _statusFilter = 'all';
  String _packageFilter = 'all';
  List<String> packageOptions = [];

  @override
  void initState() {
    super.initState();
    _fetchPackageOptions();
  }

  void _fetchPackageOptions() async {
    final snapshot = await FirebaseFirestore.instance.collection('voucher_packages').get();
    final names = snapshot.docs.map((doc) {
      final data = doc.data();
      return data['name']?.toString() ?? '';
    }).where((name) => name.isNotEmpty).toList();

    setState(() {
      packageOptions = names;
    });
  }

  @override
  Widget build(BuildContext context) {
    final voucherStream = FirebaseFirestore.instance
        .collection('vouchers')
        .orderBy('created_at', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Voucher Management',
          style: TextStyle(color: Colors.green),
        ),
        backgroundColor: Colors.black.withValues(alpha: 0.7),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.green),
            tooltip: 'Add Voucher',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const AddVoucherDialog(),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchTerm = val.toLowerCase()),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Colors.green),
                hintText: 'Search vouchers...',
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.green),
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Flexible(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    initialValue: _statusFilter,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: ['all', 'available', 'assigned', 'used', 'expired'].map((status) {
                      return DropdownMenuItem(value: status, child: Text(status));
                    }).toList(),
                    onChanged: (val) => setState(() => _statusFilter = val ?? 'all'),
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    initialValue: _packageFilter,
                    decoration: const InputDecoration(labelText: 'Package'),
                    isExpanded: true,
                    items: ['all', ...packageOptions].map((pkg) {
                      return DropdownMenuItem(value: pkg, child: Text(pkg));
                    }).toList(),
                    onChanged: (val) => setState(() => _packageFilter = val ?? 'all'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: voucherStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final docs = snapshot.data!.docs;
                final filtered = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final code = data['code']?.toString().toLowerCase() ?? '';
                  final package = data['package']?.toString().toLowerCase() ?? '';
                  final network = data['network']?.toString().toLowerCase() ?? '';
                  final status = data['status']?.toString().toLowerCase() ?? '';

                  final matchText = code.contains(_searchTerm) || package.contains(_searchTerm) || network.contains(_searchTerm);
                  final matchStatus = _statusFilter == 'all' || status == _statusFilter;
                  final matchPackage = _packageFilter == 'all' || package == _packageFilter.toLowerCase();

                  return matchText && matchStatus && matchPackage;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No vouchers match that filter.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    final voucher = doc.data() as Map<String, dynamic>;
                    final expiry = (voucher['expiry'] as Timestamp).toDate();

                    return Card(
                      child: ListTile(
                        onTap: () => showDialog(
                          context: context,
                          builder: (_) => ViewVoucherDialog(voucher: voucher),
                        ),
                        leading: const Icon(Icons.vpn_key),
                        title: Text(voucher['code'] ?? ''),
                        subtitle: Text(
                          '${voucher['package']} • ${voucher['network']}\nExpires: ${expiry.toLocal().toString().split(' ')[0]}',
                        ),
                        trailing: Wrap(
                          spacing: 4,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.green),
                              tooltip: 'Edit',
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => EditVoucherDialog(document: doc),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Delete',
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Delete Voucher?'),
                                    content: const Text('Are you sure you want to delete this voucher?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          await doc.reference.delete();
                                          Navigator.pop(context);
                                        },
                                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

}
