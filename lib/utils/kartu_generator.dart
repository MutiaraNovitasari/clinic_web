// lib/utils/kartu_generator.dart
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/pasien_model.dart';

class KartuGenerator {
  static Future<Uint8List> generateKartu(Pasien pasien) async {
    final pdf = pw.Document();

    // Load font bawaan dari paket pdf
    final fontData = await rootBundle.load('packages/pdf/assets/fonts/Roboto-Regular.ttf');
    final boldFontData = await rootBundle.load('packages/pdf/assets/fonts/Roboto-Bold.ttf');

    final font = pw.Font.ttf(fontData);
    final boldFont = pw.Font.ttf(boldFontData);

    // Load logo
    final logoImage = await rootBundle.load('assets/images/logo.png');
    final imageLogo = pw.MemoryImage(logoImage.buffer.asUint8List());

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(8.5 * PdfPageFormat.cm, 5.5 * PdfPageFormat.cm),
        margin: pw.EdgeInsets.all(10),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Logo dan Nama Klinik
            pw.Row(
              children: [
                pw.Container(
                  width: 30,
                  height: 30,
                  child: pw.Image(imageLogo, fit: pw.BoxFit.contain),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Text(
                    'Sakura Medical Center',
                    style: pw.TextStyle(fontSize: 10, font: boldFont, color: PdfColors.grey),
                  ),
                ),
              ],
            ),
            pw.Divider(color: PdfColors.grey, thickness: 0.5, height: 10),
            pw.Text('KARTU PASIEN', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, font: boldFont)),
            pw.SizedBox(height: 8),
            _buildRow('Nama', pasien.namaLengkap, boldFont, font),
            _buildRow('RM', pasien.nomorRekamMedis, boldFont, font),
            _buildRow('Gol. Darah', pasien.golonganDarah, boldFont, font),
            _buildRow('JK', pasien.jenisKelamin, boldFont, font),
            _buildRow('Umur', pasien.umur, boldFont, font),
            _buildRow('No. Telp', pasien.noTelepon, boldFont, font),
            pw.Spacer(),
            pw.Text('Terima kasih atas kepercayaan Anda', style: pw.TextStyle(fontSize: 8, font: font, color: PdfColors.grey)),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildRow(String label, String value, pw.Font bold, pw.Font normal) {
    return pw.Row(
      children: [
        pw.Expanded(flex: 2, child: pw.Text('$label:', style: pw.TextStyle(font: bold, fontSize: 10))),
        pw.Expanded(flex: 3, child: pw.Text(value, style: pw.TextStyle(font: normal, fontSize: 10))),
      ],
    );
  }

  static Future<void> printKartu(Pasien pasien) async {
    final pdfData = await generateKartu(pasien);
    await Printing.layoutPdf(
      onLayout: (_) => pdfData,
      format: const PdfPageFormat(8.5 * PdfPageFormat.cm, 5.5 * PdfPageFormat.cm), // ✅ Ganti optionsBuilder → format
    );
  }
}