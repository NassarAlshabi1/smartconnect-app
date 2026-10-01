import 'package:flutter/material.dart';
import 'package:smartconnect/splash_screen.dart';
import 'package:smartconnect/admin_dashboard.dart';
import 'package:smartconnect/customer_screen.dart';
import 'package:smartconnect/forgot_password_screen.dart';
import 'package:smartconnect/create_account_screen.dart';
import 'package:smartconnect/metrics_card.dart'; // hakikisha path ni sahihi
import 'package:smartconnect/voucher_management_screen.dart';
import 'package:smartconnect/main_dashboard.dart';
import 'package:smartconnect/speed_test_screen.dart'; // 👈 badilisha path kama uliloweka tofauti
import 'package:smartconnect/admin_payments_screen.dart';
import 'package:smartconnect/login_screen.dart'; // badilisha path kama file liko sehemu nyingine
import 'package:smartconnect/buy_voucher_screen.dart'; // badilisha path kama file liko ndani ya folder
import 'package:smartconnect/payment_screen.dart'; // badilisha path kulingana na project yako

import 'package:smartconnect/reset_password_screen.dart';
import 'feedback_screen.dart';
import 'profile_screen.dart';
import 'help_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartConnect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      routes: {
        '/admin': (_) => const AdminDashboardScreen(),
        '/customer': (_) => const CustomerDashboardScreen(),
        '/forgot': (_) => const ForgotPasswordScreen(),
        '/create': (_) => const CreateAccountScreen(),
        '/dashboard': (context) => const MainDashboard(),
        '/speed-test': (context) => const ManageVoucherPackagesScreen(),
        '/payments': (context) => const AdminPaymentsScreen(),
        '/login': (context) => const LoginScreen(),
        '/buy': (context) => const BuyVoucherScreen(),
        '/payment': (context) => const PaymentScreen(), // Hii hapa
        '/feedback': (context) => const FeedbackScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/help': (context) => const HelpScreen(),
        '/reset-password': (context) => const ResetPasswordScreen(),
      },
    ); // ← semicolon inafunga MaterialApp hapa sasa
  }
}
