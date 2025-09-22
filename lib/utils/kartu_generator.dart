// lib/utils/kartu_generator.dart
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/pasien_model.dart';

class KartuGenerator {
  // Ukuran kartu: 8.5 x 5.5 cm
  static const PdfPageFormat cardSize = PdfPageFormat(8.5 * PdfPageFormat.cm, 5.5 * PdfPageFormat.cm);

  /// Menghasilkan PDF kartu pasien
  static Future<Uint8List> _generateKartu(Pasien pasien) async {
    final pdf = pw.Document();

    // Load font
    final font = await PdfGoogleFonts.openSansRegular();
    final boldFont = await PdfGoogleFonts.openSansBold();

    // Load logo
    final logoData = await rootBundle.load('assets/images/logo.png');
    final image = pw.MemoryImage(logoData.buffer.asUint8List());

    pdf.addPage(
      pw.Page(
        pageFormat: cardSize,
        margin: pw.EdgeInsets.all(12),
        build: (context) => pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(width: 1, color: PdfColors.grey),
            borderRadius: pw.BorderRadius.circular(10),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#FF8DAA'),
                ),
                child: pw.Row(
                  children: [
                    pw.Image(image, width: 30, height: 30),
                    pw.SizedBox(width: 8),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Klinik Pratama', style: pw.TextStyle(font: boldFont, fontSize: 9, color: PdfColors.white)),
                          pw.Text('Sakura Medical Center', style: pw.TextStyle(font: boldFont, fontSize: 9, color: PdfColors.white)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 10),

              // Data Pasien
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildField('Nama', pasien.namaLengkap, boldFont, font),
                    _buildField('RM', pasien.nomorRekamMedis, boldFont, font),
                    _buildField('Alamat', pasien.alamat ?? '-', boldFont, font), // ✅ Ganti Gol. Darah -> Alamat
                    _buildField('JK', pasien.jenisKelamin, boldFont, font),
                    _buildField('Umur', '${pasien.umur} tahun', boldFont, font),
                    _buildField('No. Telp', pasien.noTelepon, boldFont, font),
                  ],
                ),
              ),

              pw.Spacer(),

              // Footer
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 6),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#FFB2D0'),
                ),
                child: pw.Text(
                  'Terdaftar: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                  style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.white),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return pdf.save();
  }

  /// Cetak kartu
  static Future<void> printKartu(Pasien pasien) async {
    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => await _generateKartu(pasien),
      );
    } catch (e) {
      print("Gagal cetak: $e");
    }
  }

  static pw.Widget _buildField(String label, String value, pw.Font bold, pw.Font normal) {
    return pw.Row(
      children: [
        pw.Text('$label: ', style: pw.TextStyle(font: bold, fontSize: 9)),
        pw.Expanded(
          child: pw.Text(value, style: pw.TextStyle(font: normal, fontSize: 9)),
        ),
      ],
    );
  }
}