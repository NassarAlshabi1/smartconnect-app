import 'package:flutter/material.dart';
import 'package:smartconnect/local_auth_service.dart';
import 'package:smartconnect/local_database.dart';
import 'package:intl/intl.dart';
import 'customer_notification_screen.dart'; // hakikisha ume-import

class CustomerDashboardScreen extends StatefulWidget {
  const CustomerDashboardScreen({super.key});

  @override
  State<CustomerDashboardScreen> createState() =>
      _CustomerDashboardScreenState();
}

class _CustomerDashboardScreenState extends State<CustomerDashboardScreen> {
  int _selectedIndex = 0;
  final uid = AuthService.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
  }

  void setupPushNotifications() {}
  void listenToForegroundMessages() {}

  Widget build(BuildContext context) {
    final userStream = LocalDatabase.instance
        .collection('users')
        .doc(uid)
        .snapshots();
    final vouchersStream = LocalDatabase.instance
        .collection('vouchers')
        .where('assigned_to', isEqualTo: uid)
        .snapshots();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F0FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF7043),
        elevation: 0,
        title: Row(
          children: [
            Image.asset('assets/icon/connect.png', height: 32),
            const SizedBox(width: 8),
            const Text(
              'SmartConnect',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: LocalDatabase.instance
                .collection('users')
                .doc(uid)
                .collection('notifications')
                .where('status', isEqualTo: 'unread')
                .snapshots(),
            builder: (context, snapshot) {
              int unreadCount = snapshot.data?.docs.length ?? 0;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_none,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CustomerNotificationScreen(),
                        ),
                      );
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Center(
                          child: Text(
                            '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await AuthService.instance.signOut();
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/login', (route) => false);
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: userStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final name = snapshot.data!['full_name'] ?? 'Customer';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Section
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundImage: AssetImage('assets/icon/user.png'),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, $name 👋🏾',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Welcome back!',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // 📊 Metrics Cards
                StreamBuilder<QuerySnapshot>(
                  stream: vouchersStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = snapshot.data!.docs;

                    final used = docs
                        .where((d) => d['status'] == 'used')
                        .length;
                    final expired = docs.where((d) {
                      final expiry = (d['expiry'] as Timestamp?)?.toDate();
                      return expiry != null && expiry.isBefore(DateTime.now());
                    }).length;

                    final total = docs.length;

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _metricCard(
                          'My Vouchers',
                          total,
                          Icons.vpn_key,
                          Colors.deepPurple,
                        ),
                        _metricCard(
                          'Used',
                          used,
                          Icons.check_circle,
                          Colors.orangeAccent,
                        ),
                        _metricCard(
                          'Expired',
                          expired,
                          Icons.warning_amber,
                          Colors.pinkAccent,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // 🕓 Recent Activity
                const Text(
                  'Recent Activity',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                StreamBuilder<QuerySnapshot>(
                  stream: vouchersStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = snapshot.data!.docs;

                    if (docs.isEmpty) {
                      return const Text('No recent activity');
                    }

                    return Column(
                      children: docs.take(5).map((doc) {
                        final code = doc['code'];
                        final status = doc['status'];
                        final expiry = (doc['expiry'] as Timestamp?)?.toDate();
                        final expiryText = expiry != null
                            ? 'Expires: ${DateFormat('dd MMM yyyy').format(expiry)}'
                            : 'No expiry';

                        return ListTile(
                          leading: const Icon(Icons.receipt_long),
                          title: Text('Voucher $code'),
                          subtitle: Text('Status: $status • $expiryText'),
                        );
                      }).toList(),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Quick Actions
                const Text(
                  'Quick Actions',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _actionTile(
                      icon: Icons.shopping_cart,
                      label: 'Buy Voucher',
                      color: Colors.orange,
                      onTap: () => Navigator.pushNamed(context, '/buy'),
                    ),
                    _actionTile(
                      icon: Icons.help,
                      label: 'Help',
                      color: Colors.deepPurple,
                      onTap: () => Navigator.pushNamed(context, '/help'),
                    ),
                    _actionTile(
                      icon: Icons.feedback,
                      label: 'Feedback',
                      color: Colors.pinkAccent,
                      onTap: () => Navigator.pushNamed(context, '/feedback'),
                    ),
                    _actionTile(
                      icon: Icons.person,
                      label: 'Profile',
                      color: Colors.grey,
                      onTap: () => Navigator.pushNamed(context, '/profile'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() => _selectedIndex = index);

          if (index == 1) {
            Navigator.pushNamed(context, '/help');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/feedback');
          } else if (index == 3) {
            Navigator.pushNamed(context, '/profile');
          }
        },

        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.help), label: 'Help'),
          BottomNavigationBarItem(
            icon: Icon(Icons.feedback),
            label: 'Feedback',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _metricCard(String label, int count, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.15),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 8),
              Text(
                '$count',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(label, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: Colors.white),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
