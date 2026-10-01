import 'package:flutter/material.dart';
import 'package:smartconnect/local_auth_service.dart';
import 'package:smartconnect/local_database.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  void _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter username and password')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await AuthService.instance.signIn(username, password);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/admin');
    } on AuthException {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid username or password')),
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        margin: const EdgeInsets.only(bottom: 30),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/icon/user.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      TextField(
                        controller: _usernameController,
                        keyboardType: TextInputType.text,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.person),
                          labelText: 'Username',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock),
                          labelText: 'Password',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                          ),
                          child: const Text(
                            'Login',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/forgot');
                        },
                        child: const Text('Forgot Password?'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/create');
                        },
                        child: const Text('Create Account'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
