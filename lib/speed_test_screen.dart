import 'package:flutter/material.dart';
import 'package:smartconnect/local_backend.dart';

class ManageVoucherPackagesScreen extends StatefulWidget {
  const ManageVoucherPackagesScreen({super.key});

  @override
  State<ManageVoucherPackagesScreen> createState() => _ManageVoucherPackagesScreenState();
}

class _ManageVoucherPackagesScreenState extends State<ManageVoucherPackagesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();

  Future<void> _addPackage() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final price = int.parse(_priceController.text.trim());

      await LocalFirestore.instance.collection('voucher_packages').add({
        'name': name,
        'price': price,
        'created_at': Timestamp.now(),
      });

      _nameController.clear();
      _priceController.clear();
      Navigator.of(context).pop();
    }
  }

  Future<void> _editPackage(String docId, String currentName, int currentPrice) async {
    _nameController.text = currentName;
    _priceController.text = currentPrice.toString();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Package'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Package Name'),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Enter name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Price (TZS)'),
                  validator: (val) => val == null || int.tryParse(val) == null ? 'Enter valid price' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final newName = _nameController.text.trim();
                final newPrice = int.parse(_priceController.text.trim());

                await LocalFirestore.instance.collection('voucher_packages').doc(docId).update({
                  'name': newName,
                  'price': newPrice,
                });

                _nameController.clear();
                _priceController.clear();
                Navigator.of(context).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePackage(String docId) async {
    await LocalFirestore.instance.collection('voucher_packages').doc(docId).delete();
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Package'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Package Name'),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Enter name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Price (TZS)'),
                  validator: (val) => val == null || int.tryParse(val) == null ? 'Enter valid price' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(onPressed: _addPackage, child: const Text('Add')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Voucher Packages'),
        backgroundColor: Colors.deepPurple,
        actions: [
          Tooltip(
            message: 'Add Package',
            child: IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: _showAddDialog,
            ),
          ),
        ],
      ),
      body: StreamBuilder<LocalQuerySnapshot>(
        stream: LocalFirestore.instance.collection('voucher_packages').orderBy('created_at').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No packages yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final data = docs[i];
              final docId = data.id;
              final map = data.data();
              final name = map['name'];
              final price = map['price'];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                elevation: 2,
                child: ListTile(
                  title: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Text(
                    'TZS $price',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editPackage(docId, name, price),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deletePackage(docId),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}