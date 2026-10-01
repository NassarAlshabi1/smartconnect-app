import 'package:flutter/material.dart';
import 'package:smartconnect/local_database.dart';
import 'package:smartconnect/local_auth_service.dart';
import 'send_message_service.dart';

class AdminMessageScreen extends StatefulWidget {
  const AdminMessageScreen({super.key});

  @override
  State<AdminMessageScreen> createState() => _AdminMessageScreenState();
}

class _AdminMessageScreenState extends State<AdminMessageScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Message to All Customers'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Message',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter your message here...',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.send),
                label: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Send Message'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                ),
                onPressed: _isSending ? null : _handleSendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a message before sending.')),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      await SendMessageService.sendMessageToAllCustomers(message: message);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Message sent to all customers!')),
      );

      _messageController.clear();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('⚠️ Failed to send message: $e')));
    } finally {
      setState(() => _isSending = false);
    }
  }
}
