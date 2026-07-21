import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';

Future<void> exportPaymentsToPDF(
  List<DocumentSnapshot> payments,
  DateTime month,
  BuildContext context,
) async {
  final status = await Permission.storage.request();
  if (!status.isGranted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('⚠️ Ruhusa ya kuhifadhi haikupatikana')),
    );
    return;
  }

  final pdf = pw.Document();
  final monthTitle = DateFormat('MMMM yyyy').format(month);
  final font = pw.Font.helvetica();
  final boldFont = pw.Font.helveticaBold();

  final logoBytes = await rootBundle.load('assets/icon/connect.png');
  final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

  pdf.addPage(
    pw.MultiPage(
      pageTheme: pw.PageTheme(
        margin: const pw.EdgeInsets.all(24),
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
      ),
      build: (context) => [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Container(
              width: 60,
              height: 60,
              margin: const pw.EdgeInsets.only(right: 12),
              decoration: pw.BoxDecoration(
                image: pw.DecorationImage(image: logoImage),
              ),
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('SmartConnect Internet Services Ltd',
                    style: pw.TextStyle(
                        fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.Text('Monthly Payments Report - $monthTitle',
                    style: const pw.TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 16),
        pw.TableHelper.fromTextArray(
          headers: ['Customer', 'Amount', 'Method', 'Date'],
          data: payments.map((doc) {
            final name = doc['buyer_name'] ?? 'Unknown';
            final amount = (doc['amount'] ?? 0.0).toString();
            final method = doc['channel'] ?? 'Unknown';
            final date = (doc['created_at'] as Timestamp?)?.toDate();
            final formattedDate = date != null
                ? DateFormat('dd MMM yyyy, h:mm a').format(date)
                : 'Unknown';

            return ['$name', 'TSh $amount', '$method', formattedDate];
          }).toList(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          cellStyle: const pw.TextStyle(fontSize: 10),
          cellAlignment: pw.Alignment.centerLeft,
          headerDecoration: const pw.BoxDecoration(color: PdfColors.teal300),
          border: pw.TableBorder.all(width: 0.3, color: PdfColors.grey400),
        ),
        pw.SizedBox(height: 24),
        pw.Divider(),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('From UmemeSwahili Lab',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
        ),
      ],
    ),
  );

  final baseDir = await getApplicationDocumentsDirectory();
  final path = '${baseDir.path}/Payments-$monthTitle.pdf';
  final file = File(path);
  await file.writeAsBytes(await pdf.save());

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
          const Text('✅ PDF imesafirishwa!',
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
                label: const Text('مشاركة'),
                onPressed: () {
                  Share.shareXFiles([XFile(path)],
                      text: 'SmartConnect PDF Report - $monthTitle');
                },
              ),
            ],
          ),
        ],
      ),
    ),
  );
}