import 'package:flutter/material.dart';
import 'package:smartconnect/local_database.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;

  Future<void> _checkPhoneAndProceed() async {
    final phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your phone number')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final snapshot = await LocalDatabase.instance
          .collection('users')
          .where('phone_number', isEqualTo: phone)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Account not found')));
        setState(() => _isLoading = false);
        return;
      }

      final userDoc = snapshot.docs.first;
      final uid = userDoc.id;

      Navigator.pushNamed(
        context,
        '/reset-password',
        arguments: {'uid': uid, 'phone': phone},
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Something went wrong: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Enter your phone number to reset your password',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.phone),
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _checkPhoneAndProceed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[700],
                      ),
                      child: const Text('Continue'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
