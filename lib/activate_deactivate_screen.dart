import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ActivateDeactivateScreen extends StatefulWidget {
  const ActivateDeactivateScreen({super.key});

  @override
  State<ActivateDeactivateScreen> createState() => _ActivateDeactivateScreenState();
}

class _ActivateDeactivateScreenState extends State<ActivateDeactivateScreen>
    with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  bool _showAdminsOnly = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF001F3F),
      appBar: AppBar(
        title: const Text('Activate / Deactivate'),
        backgroundColor: Colors.redAccent,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Active'),
            Tab(text: 'Inactive'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search customer...',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: Colors.blueGrey.shade800,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim().toLowerCase();
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Switch(
                  value: _showAdminsOnly,
                  activeThumbColor: Colors.orangeAccent,
                  onChanged: (value) {
                    setState(() {
                      _showAdminsOnly = value;
                    });
                  },
                ),
                const Text(
                  'Show Admins Only',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .orderBy('full_name')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allDocs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['full_name'] ?? '').toString().toLowerCase();
                  final isAdmin = data['is_admin'] == true;
                  return name.contains(_searchQuery) &&
                      (!_showAdminsOnly || isAdmin);
                }).toList();

                final activeDocs = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['is_active'] == true;
                }).toList();

                final inactiveDocs = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['is_active'] == false;
                }).toList();

                final tabs = [allDocs, activeDocs, inactiveDocs];

                return TabBarView(
                  controller: _tabController,
                  children: tabs.map((docs) {
                    if (docs.isEmpty) {
                      return const Center(
                        child: Text(
                          'No customers found.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final name = data['full_name']?.toString().trim();
                        final displayName = (name == null || name.isEmpty)
                            ? data['phone_number'] ?? data['uid'] ?? 'Unknown'
                            : name;
                        final isActive = data['is_active'] == true;
                        final isAdmin = data['is_admin'] == true;
                        final phone = data['phone_number'] ?? '';

                        return Card(
                          color: isActive
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.red.withValues(alpha: 0.1),
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          child: ListTile(
                            leading: Icon(
                              isActive ? Icons.check_circle : Icons.cancel,
                              color: isActive ? Colors.green : Colors.red,
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    displayName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isAdmin)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 8),
                                    child: Chip(
                                      label: Text('Admin',
                                          style: TextStyle(
                                              fontSize: 10, color: Colors.white)),
                                      backgroundColor: Colors.orange,
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Text(
                              phone,
                              style: const TextStyle(color: Colors.white54),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Switch(
                                  value: isActive,
                                  activeThumbColor: Colors.greenAccent,
                                  onChanged: (value) {
                                    FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(doc.id)
                                        .update({'is_active': value});
                                  },
                                ),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, color: Colors.white),
                                  onSelected: (value) {
                                    if (value == 'make_admin') {
                                      FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(doc.id)
                                          .update({
                                            'is_admin': true,
                                            'role': 'admin',
                                          });
                                    } else if (value == 'remove_admin') {
                                      FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(doc.id)
                                          .update({
                                            'is_admin': false,
                                            'role': 'customer',
                                          });
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    if (!isAdmin)
                                      const PopupMenuItem(
                                          value: 'make_admin',
                                          child: Text('Make Admin')),
                                    if (isAdmin)
                                      const PopupMenuItem(
                                          value: 'remove_admin',
                                          child: Text('Remove Admin')),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}