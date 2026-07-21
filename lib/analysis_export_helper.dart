import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter/services.dart' show rootBundle;

Future<void> exportAnalysisToPDF({
  required List<DocumentSnapshot> transactions,
  required DateTime month,
  required BuildContext context,
}) async {
  final permissionStatus = await Permission.storage.request();
  if (!permissionStatus.isGranted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('⚠️ Permission to access storage denied')),
    );
    return;
  }

  final pdf = pw.Document();
  final monthLabel = DateFormat('MMMM yyyy').format(month);

  final filtered = transactions.where((doc) {
    final status = doc['status']?.toString().toUpperCase();
    final date = (doc['created_at'] as Timestamp).toDate();
    return status == 'COMPLETED' &&
        date.month == month.month &&
        date.year == month.year;
  }).toList();

  final totalPaid = filtered.fold<double>(
    0.0,
    (sum, doc) => sum + ((doc['amount'] is num) ? doc['amount'].toDouble() : 0.0),
  );

  final uniqueCustomers = filtered.map((doc) => doc['customer_id']).toSet().length;
  final allCustomerIds = transactions.map((doc) => doc['customer_id']).toSet();
  final activeCustomerIds = filtered.map((doc) => doc['customer_id']).toSet();
  final inactiveIds = allCustomerIds.difference(activeCustomerIds);

  final Map<String, double> topMap = {};
  for (final doc in filtered) {
    final name = (doc['buyer_name']?.toString().trim().isEmpty ?? true)
        ? 'Unknown'
        : doc['buyer_name'].toString().trim();
    final amount = (doc['amount'] is num) ? doc['amount'].toDouble() : 0.0;
    topMap[name] = (topMap[name] ?? 0) + amount;
  }
  final topSorted = topMap.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value))
    ..take(5);

  final Map<String, int> freqMap = {};
  for (final doc in filtered) {
    final name = (doc['buyer_name']?.toString().trim().isEmpty ?? true)
        ? 'Unknown'
        : doc['buyer_name'].toString().trim();
    freqMap[name] = (freqMap[name] ?? 0) + 1;
  }
  final freq5 = freqMap.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value))
    ..take(5);

  final Map<String, int> methodMap = {};
  for (final doc in filtered) {
    final method = (doc['channel']?.toString().trim().isEmpty ?? true)
        ? 'Unknown'
        : doc['channel'].toString().trim();
    methodMap[method] = (methodMap[method] ?? 0) + 1;
  }

  final logoBytes = await rootBundle.load('assets/icon/connect.png');
  final footerLogoBytes = await rootBundle.load('assets/icon/affiliate.png');
  final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
  final footerImage = pw.MemoryImage(footerLogoBytes.buffer.asUint8List());

  pdf.addPage(
    pw.MultiPage(
      pageTheme: pw.PageTheme(
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(base: pw.Font.helvetica()),
      ),
      build: (context) => [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Image(logoImage, width: 60),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('SmartConnect Internet Services Ltd',
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.Text('Customer Analysis Report - $monthLabel',
                    style: const pw.TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
        pw.Divider(),
        pw.SizedBox(height: 8),
        pw.Text('📊 Summary', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
        pw.Bullet(text: 'Total Paid: TSh ${totalPaid.toStringAsFixed(0)}'),
        pw.Bullet(text: 'Unique Customers: $uniqueCustomers'),
        pw.Bullet(text: 'Inactive Customers: ${inactiveIds.length}'),
        pw.SizedBox(height: 12),
        pw.Text('🏆 Top Paying Customers', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.TableHelper.fromTextArray(
          headers: ['Customer', 'Amount'],
          data: topSorted.map((e) => [e.key, 'TSh ${e.value.toStringAsFixed(0)}']).toList(),
        ),
        pw.SizedBox(height: 12),
        pw.Text('🔁 Most Frequent Payers', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.TableHelper.fromTextArray(
          headers: ['Customer', 'Payments'],
          data: freq5.map((e) => [e.key, '${e.value}']).toList(),
        ),
        pw.SizedBox(height: 12),
        pw.Text('🕒 Inactive Customers', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        if (inactiveIds.isEmpty)
          pw.Text('✅ All customers have paid this month.')
        else
          pw.Bullet(text: inactiveIds.length > 10
              ? '${inactiveIds.length} inactive customers'
              : inactiveIds.join(', ')),
        pw.SizedBox(height: 12),
        pw.Text('💳 Payment Method Breakdown', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.TableHelper.fromTextArray(
          headers: ['Channel', 'Count'],
          data: methodMap.entries.map((e) => [e.key, '${e.value}']).toList(),
        ),
        pw.SizedBox(height: 24),
        pw.Divider(),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text('From UmemeSwahili Lab', style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(width: 8),
            pw.Image(footerImage, width: 40),
          ],
        ),
      ],
    ),
  );

  final dir = await getApplicationDocumentsDirectory();
  final filePath = '${dir.path}/SmartConnect-Analysis-$monthLabel.pdf';
  final file = File(filePath);
  await file.writeAsBytes(await pdf.save());

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    builder: (_) => Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('✅ PDF has transferred!',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open'),
                onPressed: () => OpenFile.open(filePath),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.share),
                label: const Text('مشاركة'),
                onPressed: () {
                  Share.shareXFiles([XFile(filePath)],
                      text: 'SmartConnect PDF Report - $monthLabel');
                },
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Future<void> exportAnalysisToCSV({
  required List<DocumentSnapshot> transactions,
  required DateTime month,
  required BuildContext context,
}) async {
  final permissionStatus = await Permission.storage.request();
  if (!permissionStatus.isGranted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('⚠️ Permission to access storage denied')),
    );
    return;
  }

  final monthLabel = DateFormat('MMMM yyyy').format(month);
  final buffer = StringBuffer();

    final filtered = transactions.where((doc) {
    final status = doc['status']?.toString().toUpperCase();
    final date = (doc['created_at'] as Timestamp).toDate();
    return status == 'COMPLETED' &&
        date.month == month.month &&
        date.year == month.year;
  }).toList();

  final totalPaid = filtered.fold<double>(
    0.0,
    (sum, doc) => sum + ((doc['amount'] is num) ? doc['amount'].toDouble() : 0.0),
  );

  final uniqueCustomers = filtered.map((doc) => doc['customer_id']).toSet().length;
  final allCustomerIds = transactions.map((doc) => doc['customer_id']).toSet();
  final activeCustomerIds = filtered.map((doc) => doc['customer_id']).toSet();
  final inactiveIds = allCustomerIds.difference(activeCustomerIds);

  final Map<String, double> topMap = {};
  for (final doc in filtered) {
    final name = (doc['buyer_name']?.toString().trim().isEmpty ?? true)
        ? 'Unknown'
        : doc['buyer_name'].toString().trim();
    final amount = (doc['amount'] is num) ? doc['amount'].toDouble() : 0.0;
    topMap[name] = (topMap[name] ?? 0) + amount;
  }
  final top5 = topMap.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value))
    ..take(5);

  final Map<String, int> freqMap = {};
  for (final doc in filtered) {
    final name = (doc['buyer_name']?.toString().trim().isEmpty ?? true)
        ? 'Unknown'
        : doc['buyer_name'].toString().trim();
    freqMap[name] = (freqMap[name] ?? 0) + 1;
  }
  final freq5 = freqMap.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value))
    ..take(5);

  final Map<String, int> methodMap = {};
  for (final doc in filtered) {
    final method = (doc['channel']?.toString().trim().isEmpty ?? true)
        ? 'Unknown'
        : doc['channel'].toString().trim();
    methodMap[method] = (methodMap[method] ?? 0) + 1;
  }

  buffer.writeln('SmartConnect Internet Services Ltd');
  buffer.writeln('Customer Analysis Report - $monthLabel\n');

  buffer.writeln('Summary');
  buffer.writeln('Total Paid,TSh ${totalPaid.toStringAsFixed(0)}');
  buffer.writeln('Unique Customers,$uniqueCustomers');
  buffer.writeln('Inactive Customers,${inactiveIds.length}\n');

  buffer.writeln('Top Paying Customers');
  buffer.writeln('Customer,Amount');
  for (final entry in top5) {
    buffer.writeln('${entry.key},TSh ${entry.value.toStringAsFixed(0)}');
  }

  buffer.writeln('\nMost Frequent Payers');
  buffer.writeln('Customer,Payments');
  for (final entry in freq5) {
    buffer.writeln('${entry.key},${entry.value}');
  }

  buffer.writeln('\nInactive Customers');
  if (inactiveIds.isEmpty) {
    buffer.writeln('All customers have paid this month.');
  } else {
    buffer.writeln('Customer ID');
    for (final id in inactiveIds) {
      buffer.writeln(id);
    }
  }

  buffer.writeln('\nPayment Method Breakdown');
  buffer.writeln('Channel,Count');
  for (final entry in methodMap.entries) {
    buffer.writeln('${entry.key},${entry.value}');
  }

  final dir = await getApplicationDocumentsDirectory();
  final filePath = '${dir.path}/SmartConnect-Analysis-$monthLabel.csv';
  final file = File(filePath);
  await file.writeAsString(buffer.toString());

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    builder: (_) => Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('✅ CSV has transferred!',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open'),
                onPressed: () => OpenFile.open(filePath),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.share),
                label: const Text('مشاركة'),
                onPressed: () {
                  Share.shareXFiles([XFile(filePath)],
                      text: 'SmartConnect CSV Report - $monthLabel');
                },
              ),
            ],
          ),
        ],
      ),
    ),
  );
}