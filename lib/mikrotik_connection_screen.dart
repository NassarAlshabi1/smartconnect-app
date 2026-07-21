// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartconnect/main_dashboard.dart';

/// شاشة الاتصال بالماكروتك — إدخال IP/Port/Username/Password للارتباط بالراوتر.
///
/// تُحفظ البيانات في SharedPreferences للاستخدام المستقبلي.
/// بعد الحفظ، يتم الانتقال مباشرة إلى MainDashboard.
class MikrotikConnectionScreen extends StatefulWidget {
  const MikrotikConnectionScreen({super.key});

  @override
  State<MikrotikConnectionScreen> createState() =>
      _MikrotikConnectionScreenState();
}

class _MikrotikConnectionScreenState extends State<MikrotikConnectionScreen> {
  final _ipController = TextEditingController();
  final _portController = TextEditingController(text: '8728');
  final _userController = TextEditingController(text: 'admin');
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    _loadSavedSettings();
  }

  Future<void> _loadSavedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _ipController.text = prefs.getString('mikrotik_ip') ?? '';
      _portController.text = prefs.getString('mikrotik_port') ?? '8728';
      _userController.text = prefs.getString('mikrotik_user') ?? 'admin';
      _passwordController.text = prefs.getString('mikrotik_password') ?? '';
    });
  }

  Future<void> _connect() async {
    final ip = _ipController.text.trim();
    final port = _portController.text.trim();
    final user = _userController.text.trim();
    final pass = _passwordController.text.trim();

    if (ip.isEmpty || port.isEmpty || user.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال جميع البيانات')),
      );
      return;
    }

    setState(() => _isConnecting = true);

    // حفظ البيانات في SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mikrotik_ip', ip);
    await prefs.setString('mikrotik_port', port);
    await prefs.setString('mikrotik_user', user);
    await prefs.setString('mikrotik_password', pass);

    // محاكاة الاتصال (يمكن استبدالها باتصال حقيقي لاحقاً)
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _isConnecting = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ تم الاتصال بالماكروتك: $ip:$port')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainDashboard()),
      );
    }
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF001F3F),
        body: SafeArea(
          child: _isConnecting
              ? _buildConnectingView()
              : _buildConnectionForm(),
        ),
      ),
    );
  }

  Widget _buildConnectingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.tealAccent),
          const SizedBox(height: 20),
          Text(
            'جاري الاتصال بالماكروتك...',
            style: TextStyle(color: Colors.tealAccent.shade100, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            '${_ipController.text}:${_portController.text}',
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // الشعار
          Center(
            child: Container(
              width: 100,
              height: 100,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3)),
                ],
              ),
              child: ClipOval(
                child: Image.asset('assets/icon/connect.png', fit: BoxFit.cover),
              ),
            ),
          ),
          const Text(
            'الاتصال بالماكروتك',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.tealAccent,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'أدخل بيانات الراوتر للارتباط',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 30),

          // حقل IP
          _buildField(
            controller: _ipController,
            label: 'عنوان IP',
            hint: '192.168.88.1',
            icon: Icons.router,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),

          // حقل Port
          _buildField(
            controller: _portController,
            label: 'المنفذ (Port)',
            hint: '8728',
            icon: Icons.settings_ethernet,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),

          // حقل اسم المستخدم
          _buildField(
            controller: _userController,
            label: 'اسم المستخدم',
            hint: 'admin',
            icon: Icons.person,
          ),
          const SizedBox(height: 16),

          // حقل كلمة المرور
          _buildPasswordField(),

          const SizedBox(height: 30),

          // زر الاتصال
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _connect,
              icon: const Icon(Icons.power_settings_new, color: Colors.black),
              label: const Text(
                'اتصال',
                style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.tealAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.tealAccent),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: Colors.blueGrey.shade800,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.tealAccent, width: 2),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.lock, color: Colors.tealAccent),
        labelText: 'كلمة المرور',
        labelStyle: const TextStyle(color: Colors.white70),
        hintText: '••••••••',
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: Colors.blueGrey.shade800,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.tealAccent, width: 2),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: Colors.white54,
          ),
          onPressed: () {
            setState(() => _obscurePassword = !_obscurePassword);
          },
        ),
      ),
    );
  }
}
