import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _isLoading = false;
  bool _isSuccess = false;

  late String uid;
  late String phone;
  late AnimationController _successController;

  @override
  void initState() {
    super.initState();
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _successController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    uid = args?['uid'] ?? '';
    phone = args?['phone'] ?? '';
  }

  Future<void> _submitNewPassword() async {
    if (!_formKey.currentState!.validate()) return;

    final newPassword = _passwordController.text.trim();
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('https://smartconnect-pesapal-api.onrender.com/api/reset-password/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uid': uid,
          'new_password': newPassword,
        }),
      );

      final result = jsonDecode(response.body);
      if (result['success'] == true) {
        setState(() => _isSuccess = true);
        _successController.forward();

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.all(24),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.check_circle, color: Colors.green, size: 60),
                SizedBox(height: 16),
                Text('✅ Password reset successful!',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('You will be redirected to login...',
                    style: TextStyle(fontSize: 14, color: Colors.black54)),
              ],
            ),
          ),
        );

        await Future.delayed(const Duration(seconds: 1));
        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      } else {
        throw Exception(result['message'] ?? 'Unknown error');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Failed to reset password: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildSuccessAnimation() {
    return ScaleTransition(
      scale: CurvedAnimation(parent: _successController, curve: Curves.easeOutBack),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.check_circle, color: Colors.green, size: 80),
          SizedBox(height: 12),
          Text('Password Updated!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text('Set New Password')),
      body: AnimatedOpacity(
        opacity: 1.0,
        duration: const Duration(milliseconds: 500),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              child: Container(
                padding: const EdgeInsets.all(20),
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 400),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _isSuccess
                        ? _buildSuccessAnimation()
                        : SingleChildScrollView(
                            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Hello $phone 👋🏾',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Set your new password below',
                                    style: TextStyle(fontSize: 14, color: Colors.black54),
                                  ),
                                  const SizedBox(height: 20),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: true,
                                    decoration: const InputDecoration(
                                      labelText: 'كلمة المرور الجديدة',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (val) {
                                      if (val == null || val.length < 6) {
                                        return 'Minimum 6 characters';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _confirmController,
                                    obscureText: true,
                                    decoration: const InputDecoration(
                                      labelText: 'تأكيد كلمة المرور',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (val) {
                                      if (val != _passwordController.text) {
                                        return 'Passwords do not match';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Icons.lock_reset),
                                      label: const Text('إعادة تعيين كلمة المرور'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange[700],
                                      ),
                                      onPressed: _submitNewPassword,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}