import 'package:flutter/material.dart';
import 'package:smartconnect/local_backend.dart';
import 'booking_status_service.dart';

class SuccessScreen extends StatefulWidget {
  final String orderTrackingId;
  final String network;
  final String package;

  const SuccessScreen({
    super.key,
    required this.orderTrackingId,
    required this.network,
    required this.package,
  });

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen> {
  String? _voucherCode;
  DateTime? _expiry;

  String? _transid;
  String? _channel;
  String? _msisdn;
  String? _reference;
  String _status = "PENDING";
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    print("🚀 SuccessScreen opened for ${widget.orderTrackingId}");
    _checkPaymentProgress();
  }

  Future<void> _checkPaymentProgress() async {
    int attempts = 0;
    const maxAttempts = 12;

    while (attempts < maxAttempts && mounted) {
      final status = await BookingStatusService.checkStatus(widget.orderTrackingId);
      print("🔍 Status check: $status");
      setState(() {
        _status = status;
      });

      if (status == "COMPLETED") {
        final snapshot = await LocalFirestore.instance
            .collection('transactions')
            .doc(widget.orderTrackingId)
            .get();

        final hasVoucher = snapshot.data()?['assigned_voucher'] != null;

        if (hasVoucher) {
          print("🎁 Voucher assigned: ${snapshot.data()?['assigned_voucher']}");
          await _fetchDetails();
          setState(() {
            _loading = false;
          });
          return;
        } else {
          print("🕓 Payment completed but voucher not yet assigned. Retrying...");
        }
      } else if (status == "FAIL" || status == "ERROR") {
        setState(() {
          _loading = false;
        });
        return;
      }

      await Future.delayed(const Duration(seconds: 5));
      attempts++;
    }

    print("⚠️ Max attempts reached. Ending loading.");
    setState(() {
      _loading = false;
    });
  }

  Future<void> _fetchDetails() async {
    final details = await BookingStatusService.fetchDetails(widget.orderTrackingId);
    if (details.isNotEmpty) {
      setState(() {
        _transid = details['transid'];
        _channel = details['channel'];
        _msisdn = details['msisdn'];
        _reference = details['reference'];
        _voucherCode = details['assigned_voucher'] ?? details['transid'];
        _expiry = details['assigned_at'] ?? DateTime.now().add(const Duration(days: 1));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = LocalAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text("⚠️ User not logged in.")),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF512DA8),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Payment Status', style: TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Center(
            child: _loading
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      CircularProgressIndicator(color: Colors.deepPurple),
                      SizedBox(height: 20),
                      Text('⏳ Tunakagua malipo yako...', style: TextStyle(fontSize: 16)),
                    ],
                  )
                : _status == "COMPLETED"
                    ? _buildSuccessContent()
                    : _buildFailureOrPending(),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 90),
        const SizedBox(height: 20),
        const Text(
          '✅ Malipo Yamekamilika!',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const Text('Umepewa voucher ifuatayo:', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.deepPurple.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.deepPurple),
          ),
          child: Center(
            child: Text(
              _voucherCode ?? "Voucher not available",
              style: const TextStyle(
                fontSize: 22,
                color: Colors.deepPurple,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildDetailsSection(),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Done', style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('📦 Taarifa za Malipo:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Text('Network: ${widget.network}', style: const TextStyle(fontSize: 15)),
        Text('Package: ${widget.package}', style: const TextStyle(fontSize: 15)),
        if (_expiry != null)
          Text('Expires: ${_expiry!.toLocal().toString().split('.').first}', style: const TextStyle(fontSize: 15)),
        if (_channel != null)
          Text('Paid via: $_channel', style: const TextStyle(fontSize: 15)),
        if (_msisdn != null)
          Text('Phone: $_msisdn', style: const TextStyle(fontSize: 15)),
        if (_reference != null)
          Text('Reference: $_reference', style: const TextStyle(fontSize: 15)),
        if (_transid != null)
          Text('Transaction ID: $_transid', style: const TextStyle(fontSize: 15)),
      ],
    );
  }

  Widget _buildFailureOrPending() {
    final isFail = _status == "FAIL" || _status == "ERROR";
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isFail ? Icons.error_outline : Icons.hourglass_top,
          color: isFail ? Colors.red : Colors.orange,
          size: 80,
        ),
        const SizedBox(height: 20),
        Text(
          isFail ? '⚠️ Malipo hayakufanikiwa.' : '⌛ Malipo yako yanashughulikiwa...',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        if (!isFail)
          const Text('Please wait or try again later.', textAlign: TextAlign.center),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          ),
          child: const Text('Back', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}