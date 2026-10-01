import 'package:flutter/material.dart';
import 'package:smartconnect/local_backend.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _controller = TextEditingController();
  final uid = LocalAuth.instance.currentUser!.uid;
  String? editingId;
  bool isSubmitting = false;

  void submitFeedback() async {
    final message = _controller.text.trim();
    if (message.isEmpty || isSubmitting) return;

    setState(() => isSubmitting = true);

    try {
      if (editingId != null) {
        await LocalFirestore.instance
            .collection('feedbacks')
            .doc(editingId)
            .update({'message': message});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Feedback updated successfully')),
        );
      } else {
        await LocalFirestore.instance.collection('feedbacks').add({
          'user_id': uid,
          'message': message,
          'timestamp': Timestamp.now(),
          'status': 'unread',
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Feedback sent successfully')),
        );
      }

      _controller.clear();
      setState(() => editingId = null);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Failed to submit feedback: $e')),
      );
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  void deleteFeedback(String id) async {
    await LocalFirestore.instance.collection('feedbacks').doc(id).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🗑️ Feedback deleted')),
    );
  }

  void startEditing(String id, String message) {
    _controller.text = message;
    setState(() => editingId = id);
  }

  @override
  Widget build(BuildContext context) {
    final feedbackStream = LocalFirestore.instance
        .collection('feedbacks')
        .where('user_id', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Feedback'),
        backgroundColor: const Color(0xFF6A1B9A),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF3E5F5), Color(0xFFE1BEE7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _controller,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Write your feedback...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: isSubmitting ? null : submitFeedback,
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(editingId != null ? Icons.edit : Icons.send),
                  label: Text(editingId != null ? 'Update Feedback' : 'Send Feedback'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8E24AA),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Your Previous Feedback',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: StreamBuilder<LocalQuerySnapshot>(
                  stream: feedbackStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = snapshot.data!.docs;

                    if (docs.isEmpty) {
                      return const Center(child: Text('You haven’t submitted any feedback yet.'));
                    }

                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data();
                        final message = data['message'] ?? '';
                        final timestamp = (data['timestamp'] as Timestamp).toDate();

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            title: Text(message),
                            subtitle: Text(
                              'Sent on ${timestamp.day}/${timestamp.month}/${timestamp.year}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Wrap(
                              spacing: 4,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.deepPurple),
                                  onPressed: () => startEditing(doc.id, message),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => deleteFeedback(doc.id),
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
      ),
    );
  }
}