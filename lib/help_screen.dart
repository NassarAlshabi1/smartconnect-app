import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8), // Soft blue-gray
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: const Color(0xFF0277BD), // Blue
        elevation: 0,
      ),
      body: FadeInUp(
        duration: const Duration(milliseconds: 600),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Need Assistance?',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'If you have any questions or need help using SmartConnect, feel free to reach out to us. We’re here to support you.',
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 30),
              const Text(
                'Contact Us',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              _contactTile('+255 676 424 664'),
              const SizedBox(height: 10),
              _contactTile('+255 766 929 683'),
              const SizedBox(height: 8),
              _contactTile('+255 655 124 365'),
              const Spacer(),
              Center(child: Image.asset('assets/icon/help.png', height: 120)),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _contactTile(String phone) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.phone, color: Color(0xFF0277BD)),
          const SizedBox(width: 12),
          Expanded(
            child: SelectableText(
              phone,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
