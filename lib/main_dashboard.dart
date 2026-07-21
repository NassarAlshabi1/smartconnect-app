import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'customer_analysis_screen.dart';
import 'activate_deactivate_screen.dart';
import 'home_admin_screen.dart';
import 'search_screen.dart';
import 'person_screen.dart';
import 'admin_message_screen.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _currentImageIndex = 0;

  final List<String> _imageList = [
    'assets/images/slide1.jpg',
    'assets/images/slide2.jpg',
    'assets/images/slide3.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _startSlideshow();
  }

  void _startSlideshow() {
    Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      setState(() {
        _currentImageIndex = (_currentImageIndex + 1) % _imageList.length;
      });
    });
  }

  void _promptForPassword(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.blueGrey[900],
        title: const Text(
          '🔐 Enter Access Password',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          obscureText: true,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter password',
            hintStyle: TextStyle(color: Colors.white54),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.redAccent)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            onPressed: () {
              final input = controller.text.trim();
              if (input == '0910') {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ActivateDeactivateScreen(),
                  ),
                );
              } else {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('❌ Incorrect password'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text('Enter', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF001F3F),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 48, bottom: 20),
            color: Colors.black,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.wifi, color: Colors.white, size: 28),
                SizedBox(width: 8),
                Text(
                  'SmartConnect',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    letterSpacing: 1.5,
                    shadows: [
                      Shadow(
                        color: Colors.cyanAccent,
                        blurRadius: 12,
                        offset: Offset(0, 0),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: Colors.blueGrey.shade900,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navIcon(Icons.search, 'search'),
                _navIcon(Icons.message, 'message'),
                _navIcon(Icons.person, 'person'),
                _navIcon(Icons.home, 'home'),
              ],
            ),
          ),
          Expanded(
            child: GridView.count(
              padding: const EdgeInsets.all(16),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _dashboardTile(
                  title: 'Manage Voucher Packages',
                  icon: Icons.card_giftcard,
                  color: Colors.teal,
                  onTap: () {
                    Navigator.pushNamed(context, '/speed-test');
                  },
                ),
                _dashboardTile(
                  title: 'Payments Made',
                  icon: Icons.payments,
                  color: Colors.deepPurple,
                  onTap: () {
                    Navigator.pushNamed(context, '/payments');
                  },
                ),
                _dashboardTile(
                  title: 'Customer Analysis',
                  icon: Icons.analytics,
                  color: Colors.orange,
                  onTap: () async {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => const Center(child: CircularProgressIndicator()),
                    );

                    try {
                      final snapshot = await FirebaseFirestore.instance
                          .collection('transactions')
                          .orderBy('created_at', descending: true)
                          .get();

                      final allTransactions = snapshot.docs;

                      Navigator.pop(context);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CustomerAnalysisScreen(allTransactions: allTransactions),
                        ),
                      );
                    } catch (e) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('⚠️ Failed to load transactions: $e')),
                      );
                    }
                  },
                ),
                _dashboardTile(
                  title: 'Activate / Deactivate',
                  icon: Icons.power_settings_new,
                  color: Colors.redAccent,
                  onTap: () {
                    _promptForPassword(context);
                  },
                ),
              ],
            ),
          ),
          Container(
            height: 160,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white10,
              image: DecorationImage(
                image: AssetImage(_imageList[_currentImageIndex]),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dashboardTile({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: Colors.white),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _navIcon(IconData icon, String iconType) {
    if (iconType == 'person') {
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('feedbacks')
            .where('status', isEqualTo: 'unread')
            .snapshots(),
        builder: (context, snapshot) {
          int unreadCount = snapshot.data?.docs.length ?? 0;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PersonScreen()),
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.teal.withValues(alpha: 0.2),
                  ),
                  child: Icon(icon, color: Colors.white),
                ),
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 0,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
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
      );
    }

    return GestureDetector(
      onTap: () {
        if (iconType == 'home') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HomeAdminScreen()),
          );         } else if (iconType == 'search') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SearchScreen()),
          );
        } else if (iconType == 'message') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminMessageScreen()),
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.teal.withValues(alpha: 0.2),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}