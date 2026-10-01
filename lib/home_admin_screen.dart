import 'package:flutter/material.dart';
import 'package:smartconnect/local_database.dart';

class HomeAdminScreen extends StatefulWidget {
  const HomeAdminScreen({super.key});

  @override
  State<HomeAdminScreen> createState() => _HomeAdminScreenState();
}

class _HomeAdminScreenState extends State<HomeAdminScreen> {
  final _networkController = TextEditingController();
  bool _isSaving = false;

  Future<void> _saveNetworkName() async {
    final name = _networkController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a network name')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await LocalDatabase.instance.collection('networks').add({
        'name': name,
        'created_at': FieldValue.serverTimestamp(),
      });

      _networkController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Network saved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Failed to save network')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _assignPackages(String networkName) async {
    final snapshot = await LocalDatabase.instance
        .collection('voucher_packages')
        .get();
    final allPackages = snapshot.docs
        .map((doc) => doc['name'].toString())
        .toList();

    final assignmentSnapshot = await LocalDatabase.instance
        .collection('network_packages')
        .where('network', isEqualTo: networkName)
        .limit(1)
        .get();

    List<String> selectedPackages = [];
    String? docId;

    if (assignmentSnapshot.docs.isNotEmpty) {
      final data = assignmentSnapshot.docs.first.data()!;
      selectedPackages = List<String>.from(data['packages']);
      docId = assignmentSnapshot.docs.first.id;
    }

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Assign Packages to $networkName'),
              content: SingleChildScrollView(
                child: Column(
                  children: allPackages.map((pkg) {
                    final isSelected = selectedPackages.contains(pkg);
                    return CheckboxListTile(
                      title: Text(pkg),
                      value: isSelected,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            selectedPackages.add(pkg);
                          } else {
                            selectedPackages.remove(pkg);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (docId != null) {
                      await LocalDatabase.instance
                          .collection('network_packages')
                          .doc(docId)
                          .update({'packages': selectedPackages});
                    } else {
                      await LocalDatabase.instance
                          .collection('network_packages')
                          .add({
                            'network': networkName,
                            'packages': selectedPackages,
                            'assigned_at': FieldValue.serverTimestamp(),
                          });
                    }
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✅ Packages assigned')),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteNetwork(String docId) async {
    await LocalDatabase.instance.collection('networks').doc(docId).delete();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('🗑️ Network deleted')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF001F3F),
      appBar: AppBar(title: const Text('Home'), backgroundColor: Colors.teal),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '➕ Add Network Name',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _networkController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g. SmartConnect-Makumbusho',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.blueGrey.shade800,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveNetworkName,
                icon: const Icon(Icons.save),
                label: _isSaving
                    ? const Text('Saving...')
                    : const Text('Save Network'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent,
                  foregroundColor: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '📡 Existing Networks',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: LocalDatabase.instance
                    .collection('networks')
                    .orderBy('created_at', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());

                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty)
                    return const Text(
                      'No networks yet',
                      style: TextStyle(color: Colors.white70),
                    );

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (_, i) {
                      final doc = docs[i];
                      final name = doc['name'];
                      final docId = doc.id;

                      return Card(
                        color: Colors.blueGrey.shade900,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          title: Text(
                            name,
                            style: const TextStyle(color: Colors.white),
                          ),
                          trailing: Wrap(
                            spacing: 8,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.tealAccent,
                                ),
                                onPressed: () => _assignPackages(name),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () => _deleteNetwork(docId),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
