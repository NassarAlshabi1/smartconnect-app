import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CustomerManagementScreen extends StatefulWidget {
  const CustomerManagementScreen({super.key});

  @override
  State<CustomerManagementScreen> createState() => _CustomerManagementScreenState();
}

class _CustomerManagementScreenState extends State<CustomerManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';

  @override
  Widget build(BuildContext context) {
    final usersRef = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'customer');

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/customer_bg.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            color: Colors.black.withValues(alpha: 0.65),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
                child: Column(
                  children: [
                    const Text(
                      'Customer Overview',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 16),

                    // 🔢 Metrics
                    StreamBuilder<QuerySnapshot>(
                      stream: usersRef.snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator(color: Colors.green));
                        }
                        final docs = snapshot.data!.docs;
                        final total = docs.length;
                        final active = docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return data['is_active'] == true;
                        }).length;
                        final inactive = docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return data['is_active'] == false;
                        }).length;

                        return Row(
                          children: [
                            Expanded(child: _buildMetricCard(Icons.group, 'Total', '$total', Colors.blue)),
                            const SizedBox(width: 10),
                            Expanded(child: _buildMetricCard(Icons.check_circle, 'Active', '$active', Colors.green)),
                            const SizedBox(width: 10),
                            Expanded(child: _buildMetricCard(Icons.pause_circle_filled, 'Inactive', '$inactive', Colors.orange)),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // 🔍 Search Field
                    TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchTerm = val.toLowerCase()),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search customers...',
                        hintStyle: const TextStyle(color: Colors.white54),
                        prefixIcon: const Icon(Icons.search, color: Colors.green),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.green.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.green),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.white10,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 👥 Customer List
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: usersRef.orderBy('full_name').snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(child: CircularProgressIndicator(color: Colors.green));
                          }

                          final filtered = snapshot.data!.docs.where((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final name = (data['full_name'] ?? '').toString().toLowerCase();
                            final phone = (data['phone_number'] ?? '').toString().toLowerCase();
                            return name.contains(_searchTerm) || phone.contains(_searchTerm);
                          }).toList();

                          if (filtered.isEmpty) {
                            return const Center(
                              child: Text('No customers found.', style: TextStyle(color: Colors.white54)),
                            );
                          }

                          return ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final doc = filtered[index];
                              final data = doc.data() as Map<String, dynamic>;
                              final created = (data['created_at'] as Timestamp?)?.toDate();
                              final dateStr = created != null
                                  ? DateFormat('yyyy-MM-dd').format(created)
                                  : 'Unknown';

                              return Card(
                                color: Colors.white.withValues(alpha: 0.05),
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                child: ListTile(
                                  leading: const Icon(Icons.person, color: Colors.green),
                                  title: Text(
                                    data['full_name'] ?? 'Unknown',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  subtitle: Text(
                                    data['phone_number'] ?? 'No phone number',
                                    style: const TextStyle(color: Colors.white70),
                                  ),
                                  trailing: Text(
                                    dateStr,
                                    style: const TextStyle(color: Colors.white60, fontSize: 12),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 30, color: Colors.white),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }
}