import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';

Future<void> exportPaymentsToCSV(
  List<DocumentSnapshot> payments,
  DateTime month,
  BuildContext context,
) async {
  final permissionStatus = await Permission.storage.request();
  if (!permissionStatus.isGranted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('⚠️ Ruhusa ya kuhifadhi haikupatikana')),
    );
    return;
  }

  final csvBuffer = StringBuffer();
  csvBuffer.writeln('Customer,Amount,Method,Date');

  for (final doc in payments) {
    final name = doc['buyer_name'] ?? 'Unknown';
    final amount = (doc['amount'] ?? 0.0).toString();
    final method = doc['channel'] ?? 'Unknown';
    final date = (doc['created_at'] as Timestamp?)?.toDate();
    final formattedDate = date != null
        ? DateFormat('dd MMM yyyy, h:mm a').format(date)
        : 'Unknown';

    csvBuffer.writeln('$name,$amount,$method,$formattedDate');
  }

  final monthTitle = DateFormat('MMMM yyyy').format(month);
  final baseDir = await getApplicationDocumentsDirectory();
  final path = '${baseDir.path}/Payments-$monthTitle.csv';
  final file = File(path);
  await file.writeAsString(csvBuffer.toString());

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    builder: (_) => Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('✅ CSV imesafirishwa!',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open'),
                onPressed: () => OpenFile.open(path),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.share),
                label: const Text('Share'),
                onPressed: () {
                  Share.shareXFiles([XFile(path)],
                      text: 'SmartConnect CSV Report - $monthTitle');
                },
              ),
            ],
          ),
        ],
      ),
    ),
  );
}