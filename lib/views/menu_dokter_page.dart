// lib/views/menu_dokter_page.dart
// ignore_for_file: use_build_context_synchronously
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/obat_model.dart'; // Untuk referensi jika nanti diperlukan
import 'login_page.dart';

class MenuDokterPage extends StatefulWidget {
  const MenuDokterPage({super.key});

  @override
  State<MenuDokterPage> createState() => _MenuDokterPageState();
}

class _MenuDokterPageState extends State<MenuDokterPage> {
  bool _isSidebarCollapsed = false;
  String? _hoveredItem;
  final Color menuColor = Colors.white;
  String _currentView = 'Dashboard';

  Uint8List? _profileImage;
  String _userName = 'Dokter';
  bool _loading = true;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // LOGIKA PAGINATION
  int _currentPage = 1;
  final int _pageSize = 10;
  int _totalDocs = 0;
  int _totalPages = 1;

  // Laporan State
  DateTime? _startDate;
  DateTime? _endDate;
  String _periodFilter = 'Semua Data'; // Default filter

  // Form Diagnosis & Resep
  final TextEditingController _diagnosisController = TextEditingController();
  final TextEditingController _biayaPemeriksaanController =
      TextEditingController();

  Map<String, dynamic>? _selectedAnamnesa;
  String? _selectedPasienId;
  String? _selectedRM;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    // Inisialisasi filter untuk 'Semua Data' (Tidak ada batasan tanggal)
    _applyDateFilter(_periodFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _diagnosisController.dispose();
    _biayaPemeriksaanController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = firebase.FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data();
        setState(() {
          _userName = data?['nama'] ?? 'Dokter';
          final imageBytes = data?['profileImage'];
          if (imageBytes is List) {
            _profileImage = Uint8List.fromList(
              imageBytes.map((e) => e as int).toList(),
            );
          }
        });
      }
    }
    setState(() {
      _loading = false;
    });
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Keluar"),
        content: const Text("Yakin ingin keluar dari akun ini?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEA2070),
            ),
            onPressed: () async {
              await firebase.FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              }
            },
            child: const Text("Keluar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // HELPER PDF
  // =========================================================

  pw.Widget _buildPdfTableHeader(
    String text,
    pw.Font boldFont,
    PdfColor color, {
    pw.TextAlign align = pw.TextAlign.center,
  }) {
    return pw.Container(
      alignment: pw.Alignment.center,
      child: pw.Padding(
        padding: const pw.EdgeInsets.all(5),
        child: pw.Text(
          text,
          style: pw.TextStyle(font: boldFont, color: color, fontSize: 10),
          textAlign: align,
        ),
      ),
    );
  }

  pw.Widget _buildPdfTableCell(String text, pw.Font font, pw.TextAlign align) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: font, fontSize: 10),
        textAlign: align,
      ),
    );
  }

  pw.TableRow _buildPdfDataRow(
    String label,
    String value,
    pw.Font bold,
    pw.Font normal,
  ) {
    return pw.TableRow(
      verticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(label, style: pw.TextStyle(font: bold, fontSize: 10)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(
            value,
            style: pw.TextStyle(font: normal, fontSize: 10),
          ),
        ),
      ],
    );
  }

  // ✅ Cetak Resume untuk Satu Pasien
  Future<void> _printResume(Map<String, dynamic> data) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.openSansRegular();
    final boldFont = await PdfGoogleFonts.openSansBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (context) {
          final List<pw.TableRow> obatRows = [];

          // 1. Header Tabel Obat (Warna Pink600)
          obatRows.add(
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.pink600),
              children: [
                _buildPdfTableHeader(
                  'Nama Obat',
                  boldFont,
                  PdfColors.white,
                  align: pw.TextAlign.left,
                ),
                _buildPdfTableHeader('Jumlah', boldFont, PdfColors.white),
                _buildPdfTableHeader(
                  'Aturan Pakai',
                  boldFont,
                  PdfColors.white,
                  align: pw.TextAlign.left,
                ),
              ],
            ),
          );

          // 2. Isi Tabel Obat
          final List<dynamic> obatList = data['obat'] as List<dynamic>? ?? [];
          if (obatList.isEmpty) {
            obatRows.add(
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                      'Tidak ada resep obat',
                      style: pw.TextStyle(font: font, fontSize: 10),
                    ),
                  ),
                  pw.SizedBox.shrink(),
                  pw.SizedBox.shrink(),
                ],
              ),
            );
          } else {
            for (int i = 0; i < obatList.length; i++) {
              final obat = obatList[i];
              final rowColor = i.isEven ? PdfColors.grey100 : PdfColors.white;
              obatRows.add(
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: rowColor),
                  children: [
                    _buildPdfTableCell(
                      obat['nama'] ?? '-',
                      font,
                      pw.TextAlign.left,
                    ),
                    _buildPdfTableCell(
                      obat['jumlah'] ?? '-',
                      font,
                      pw.TextAlign.center,
                    ),
                    _buildPdfTableCell(
                      obat['aturan'] ?? '-',
                      font,
                      pw.TextAlign.left,
                    ),
                  ],
                ),
              );
            }
          }

          // Penanganan Timestamp di PDF juga dibuat aman
          final tanggalTimestamp = data['tanggal'] as Timestamp?;
          final formattedTanggal = tanggalTimestamp != null
              ? DateFormat('dd/MM/yyyy HH:mm').format(tanggalTimestamp.toDate())
              : '-';

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header Dokumen
              pw.Text(
                'Sakura Medical Center',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  font: boldFont,
                  color: PdfColors.pink600,
                ),
              ),
              pw.Text(
                'Resume Pemeriksaan Pasien',
                style: pw.TextStyle(
                  fontSize: 14,
                  font: boldFont,
                  color: PdfColors.grey600,
                ),
              ),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 20),

              // Data Pasien dan Tanda Vital (Menggunakan Tabel 2 Kolom)
              pw.Table(
                columnWidths: const {
                  0: pw.FlexColumnWidth(2),
                  1: pw.FlexColumnWidth(3),
                },
                border: pw.TableBorder.all(
                  color: PdfColors.grey300,
                  width: 0.5,
                ),
                children: [
                  _buildPdfDataRow(
                    'Nama Pasien',
                    data['namaPasien'] ?? '-',
                    boldFont,
                    font,
                  ),
                  _buildPdfDataRow(
                    'Nomor RM',
                    data['nomorRekamMedis'] ?? '-',
                    boldFont,
                    font,
                  ),
                  _buildPdfDataRow(
                    'Tanggal Kunjungan',
                    formattedTanggal,
                    boldFont,
                    font,
                  ),
                  _buildPdfDataRow('Dokter', _userName, boldFont, font),
                ],
              ),
              pw.SizedBox(height: 15),

              // Tanda Vital
              pw.Text(
                'Tanda Vital:',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  font: boldFont,
                ),
              ),
              pw.Table(
                columnWidths: const {
                  0: pw.FlexColumnWidth(2),
                  1: pw.FlexColumnWidth(3),
                },
                border: pw.TableBorder.all(
                  color: PdfColors.grey300,
                  width: 0.5,
                ),
                children: [
                  _buildPdfDataRow(
                    'Tekanan Darah',
                    '${data['tekananDarah']} mmHg',
                    boldFont,
                    font,
                  ),
                  _buildPdfDataRow(
                    'Suhu Tubuh',
                    '${data['suhuTubuh']} °C',
                    boldFont,
                    font,
                  ),
                  _buildPdfDataRow(
                    'Tinggi Badan',
                    '${data['tinggiBadan']} cm',
                    boldFont,
                    font,
                  ),
                  _buildPdfDataRow(
                    'Berat Badan',
                    '${data['beratBadan']} kg',
                    boldFont,
                    font,
                  ),
                ],
              ),
              pw.SizedBox(height: 15),

              // Diagnosis
              pw.Text(
                'Diagnosis:',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  font: boldFont,
                ),
              ),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(5),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                ),
                child: pw.Text(
                  data['diagnosis'] ?? '-',
                  style: pw.TextStyle(font: font),
                ),
              ),
              pw.SizedBox(height: 20),

              // Resep Obat
              pw.Text(
                'Resep Obat:',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  font: boldFont,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Table(
                columnWidths: const {
                  0: pw.FlexColumnWidth(4), // Nama Obat
                  1: pw.FlexColumnWidth(1.5), // Jumlah
                  2: pw.FlexColumnWidth(4), // Aturan
                },
                border: pw.TableBorder.all(
                  color: PdfColors.grey300,
                  width: 0.5,
                ),
                children: obatRows,
              ),

              pw.SizedBox(height: 30),
              pw.Align(
                alignment: pw.Alignment.topRight,
                child: pw.Text(
                  'Bandung, ${DateFormat('dd MMMM yyyy').format(DateTime.now())}',
                  style: pw.TextStyle(font: font, fontSize: 10),
                ),
              ),
              pw.SizedBox(height: 50),
              pw.Align(
                alignment: pw.Alignment.topRight,
                child: pw.Text(
                  '( $_userName )',
                  style: pw.TextStyle(font: boldFont, fontSize: 10),
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }

  void _showDiagnosisForm(Map<String, dynamic> anamnesaData) {
    _selectedPasienId = anamnesaData['pasienId'];
    _selectedRM = anamnesaData['nomorRekamMedis'];
    _diagnosisController.clear();
    _biayaPemeriksaanController.clear();

    final List<Map<String, String>> obatList = [
      {'nama': '', 'jumlah': '', 'aturan': ''},
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Diagnosis & Resep"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Pasien: ${anamnesaData['namaPasien']} (${anamnesaData['nomorRekamMedis']})",
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _diagnosisController,
                      decoration: const InputDecoration(
                        labelText: "Diagnosis",
                        border: OutlineInputBorder(),
                        hintText: "Contoh: Hipertensi, Demam",
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    // Form Obat Dinamis
                    Column(
                      children: obatList.asMap().entries.map((entry) {
                        final index = entry.key;
                        final obat = entry.value;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Nama Obat",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      TextField(
                                        controller: TextEditingController(
                                          text: obat['nama'],
                                        ),
                                        onChanged: (value) =>
                                            obat['nama'] = value,
                                        decoration: const InputDecoration(
                                          hintText: "",
                                          border: InputBorder.none,
                                          isDense: true,
                                        ),
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 1,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Jml",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      TextField(
                                        controller: TextEditingController(
                                          text: obat['jumlah'],
                                        ),
                                        onChanged: (value) =>
                                            obat['jumlah'] = value,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          hintText: "",
                                          border: InputBorder.none,
                                          isDense: true,
                                        ),
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Aturan Pakai",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      TextField(
                                        controller: TextEditingController(
                                          text: obat['aturan'],
                                        ),
                                        onChanged: (value) =>
                                            obat['aturan'] = value,
                                        decoration: const InputDecoration(
                                          hintText: "",
                                          border: InputBorder.none,
                                          isDense: true,
                                        ),
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (obatList.length > 1)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      size: 18,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        obatList.removeAt(index);
                                      });
                                    },
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text(
                          "Tambah Obat",
                          style: TextStyle(fontSize: 12),
                        ),
                        onPressed: () {
                          setState(() {
                            obatList.add({
                              'nama': '',
                              'jumlah': '',
                              'aturan': '',
                            });
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _biayaPemeriksaanController,
                      decoration: const InputDecoration(
                        labelText: "Biaya Pemeriksaan (Rp)",
                        border: OutlineInputBorder(),
                        prefixText: 'Rp ',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Batal"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEA2070),
                  ),
                  onPressed: () async {
                    final diagnosis = _diagnosisController.text.trim();
                    final biayaText = _biayaPemeriksaanController.text.trim();

                    if (diagnosis.isEmpty || biayaText.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Diagnosis dan biaya wajib diisi"),
                        ),
                      );
                      return;
                    }

                    final filteredObat = obatList
                        .where((o) => o['nama']!.isNotEmpty)
                        .toList();
                    if (filteredObat.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Minimal satu obat harus diisi"),
                        ),
                      );
                      return;
                    }

                    final biayaPemeriksaan = int.tryParse(biayaText) ?? 0;
                    if (biayaPemeriksaan == 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Biaya pemeriksaan tidak valid/nol."),
                        ),
                      );
                      return;
                    }

                    try {
                      // 1. SIMPAN DIAGNOSIS KE resep_obat DENGAN STATUS 'Baru'
                      await FirebaseFirestore.instance
                          .collection('resep_obat')
                          .add({
                            'pasienId': _selectedPasienId,
                            'nomorRekamMedis': _selectedRM,
                            'namaPasien': anamnesaData['namaPasien'],
                            'diagnosis': diagnosis,
                            'obat': filteredObat,
                            'dokter': _userName,
                            'tanggal': DateTime.now(),
                            'status': 'Baru',
                            'createdAt': FieldValue.serverTimestamp(),
                            'biayaPemeriksaan': biayaPemeriksaan,
                            // Pastikan data Tanda Vital di sini juga String/dikonversi
                            'tekananDarah': anamnesaData['tekananDarah'],
                            'suhuTubuh': anamnesaData['suhuTubuh'],
                            'tinggiBadan': anamnesaData['tinggiBadan'],
                            'beratBadan': anamnesaData['beratBadan'],
                          });

                      // 2. TANDAI DOKUMEN anamnesa_awal SEBAGAI SUDAH DIDIAGNOSA
                      await FirebaseFirestore.instance
                          .collection('anamnesa_awal')
                          .doc(anamnesaData['id'])
                          .update({'isDiagnosed': true});

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Diagnosis selesai. Data dikirim ke Apoteker dan ditambahkan ke Riwayat.",
                          ),
                        ),
                      );
                      // Pop dialog DULU
                      Navigator.of(context).pop();

                      // ✅ PERBAIKAN: Pindah ke halaman Riwayat setelah diagnosa berhasil
                      await Future.delayed(Duration.zero, () {
                        setState(() {
                          _currentView = 'Riwayat';
                        });
                      });
                    } catch (e) {
                      print("Error saving diagnosis: $e");
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Gagal menyimpan data diagnosis."),
                        ),
                      );
                    }
                  },
                  child: const Text(
                    "Selesai",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildContent() {
    switch (_currentView) {
      case 'Dashboard':
        return _buildDashboard();
      case 'Riwayat':
        return _buildRiwayat();
      case 'Laporan':
        return _buildLaporan();
      default:
        return _buildDashboard();
    }
  }

  // ✅ PERBAIKAN _buildDashboard: Memastikan semua field adalah String
  Widget _buildDashboard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pemeriksaan Utama',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Text("Daftar pasien yang menunggu diagnosis"),
        const SizedBox(height: 24),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('anamnesa_awal')
                .where('isDiagnosed', isEqualTo: false)
                .orderBy('tanggalKunjungan', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                print("ERROR Firestore: ${snapshot.error}");
                return const Center(
                  child: Text(
                    "Gagal memuat data. (Periksa koneksi atau aturan Firestore)",
                    textAlign: TextAlign.center,
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return const Center(
                  child: Text("Belum ada pasien menunggu diagnosis."),
                );
              }

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final docId = doc.id;

                  // Pengambilan data string biasa
                  final nama =
                      data['namaPasien'] as String? ?? 'Nama Tidak Ada';
                  final rm =
                      data['nomorRekamMedis'] as String? ?? 'RM Tidak Ada';

                  // Penanganan Timestamp yang aman
                  final tanggalTimestamp =
                      data['tanggalKunjungan'] as Timestamp?;
                  final tanggal = tanggalTimestamp?.toDate() ?? DateTime.now();

                  // Field Keluhan
                  final keluhan = data['keluhan'] as String? ?? '-';

                  // 🔥 PERBAIKAN KRUSIAL: Konversi data Tanda Vital ke String secara aman.
                  // Menggunakan `.toString()` agar tipe `int` atau `double` juga bisa diambil.
                  final tekanan = data['tekananDarah']?.toString() ?? '-';
                  final suhu = data['suhuTubuh']?.toString() ?? '-';
                  final tinggi = data['tinggiBadan']?.toString() ?? '-';
                  final berat = data['beratBadan']?.toString() ?? '-';

                  // Data lengkap yang akan dikirim ke form diagnosis
                  final anamnesaDataToSend = {
                    ...data,
                    'id': docId,
                    // Pastikan Tanda Vital dikirim sebagai String untuk konsistensi
                    'tekananDarah': tekanan,
                    'suhuTubuh': suhu,
                    'tinggiBadan': tinggi,
                    'beratBadan': berat,
                  };

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "RM: $rm",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  "BARU",
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text("Pasien: $nama"),
                          Text(DateFormat('dd/MM/yyyy HH:mm').format(tanggal)),
                          const SizedBox(height: 8),

                          // ✅ Keluhan
                          const Text(
                            "Keluhan:",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(keluhan),
                          const SizedBox(height: 8),

                          // ✅ Tanda Vital (Menggunakan data yang sudah dikonversi)
                          const Text(
                            "Tanda Vital:",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          _buildDataRow('Tekanan Darah', '$tekanan mmHg'),
                          _buildDataRow('Suhu Tubuh', '$suhu °C'),
                          _buildDataRow('Tinggi Badan', '$tinggi cm'),
                          _buildDataRow('Berat Badan', '$berat kg'),
                          const SizedBox(height: 8),

                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEA2070),
                            ),
                            onPressed: () {
                              // Kirim data yang sudah diolah dan dijamin String
                              _showDiagnosisForm(anamnesaDataToSend);
                            },
                            icon: const Icon(
                              Icons.edit_note,
                              size: 16,
                              color: Colors.white,
                            ),
                            label: const Text(
                              "Diagnosis",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // =========================================================
  // FUNGSI _buildRiwayat()
  // =========================================================

  // Header Cell (Alignment: Center)
  Widget _buildHeaderCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Container(
        alignment: Alignment.center, // <-- CENTERED
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          // Garis pemisah vertikal
          border: Border(right: BorderSide(color: Colors.grey.shade300)),
        ),
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  // Data Cell (Alignment: Center dan garis vertikal)
  Widget _buildDataCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Container(
        alignment: Alignment.center, // <-- CENTERED
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          // Garis pemisah vertikal
          border: Border(right: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Text(
          text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildRiwayat() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Riwayat Pemeriksaan',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        // ✅ Perbaikan Kolom Pencarian (Lebar Dibatasi)
        SizedBox(
          width: 300, // Batasi lebar kolom pencarian
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari pasien...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
                _currentPage = 1; // Reset ke halaman 1 saat mencari
              });
            },
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          // ✅ FIX: Memastikan query ke resep_obat benar dan diurutkan
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('resep_obat')
                .orderBy('tanggal', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Text("Error: ${snapshot.error}");
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs;

              // Filter data berdasarkan _searchQuery
              final filteredDocs = docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final nama = (data['namaPasien'] as String? ?? '')
                    .toLowerCase();
                final rm = (data['nomorRekamMedis'] as String? ?? '')
                    .toLowerCase();
                // Riwayat Dokter menampilkan SEMUA data resep_obat
                return nama.contains(_searchQuery) || rm.contains(_searchQuery);
              }).toList();

              // Perhitungan Pagination
              _totalDocs = filteredDocs.length;
              _totalPages = (_totalDocs / _pageSize).ceil();

              final startIndex = (_currentPage - 1) * _pageSize;
              final endIndex = startIndex + _pageSize;
              final paginatedDocs = filteredDocs.sublist(
                startIndex,
                endIndex.clamp(0, _totalDocs),
              );

              if (filteredDocs.isEmpty) {
                return const Center(
                  child: Text("Belum ada riwayat pemeriksaan yang tersimpan."),
                );
              }

              return Column(
                children: [
                  // 1. Header Tabel
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        _buildHeaderCell('Pasien', flex: 3),
                        _buildHeaderCell('RM', flex: 2),
                        _buildHeaderCell('Diagnosis', flex: 4),
                        _buildHeaderCell('Tanggal', flex: 2),
                        // 🔥 MODIFIKASI: Kolom Status Dihapus
                        // Kolom Aksi (Diberi flex lebih untuk mengisi ruang Status)
                        Expanded(
                          flex: 2, // Dibuat lebih lebar (misal 2)
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            child: const Text(
                              'Aksi',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2. Data Tabel
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(color: Colors.grey.shade300),
                          right: BorderSide(color: Colors.grey.shade300),
                          bottom: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: ListView.builder(
                        itemCount: paginatedDocs.length,
                        itemBuilder: (context, index) {
                          final doc = paginatedDocs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final nama = data['namaPasien'] as String? ?? '-';
                          final rm = data['nomorRekamMedis'] as String? ?? '-';
                          final diagnosis = data['diagnosis'] as String? ?? '-';
                          // final status = data['status'] as String? ?? '-'; // Dihapus

                          // Penanganan Timestamp yang aman
                          final tanggalTimestamp =
                              data['tanggal'] as Timestamp?;
                          final tanggal =
                              tanggalTimestamp?.toDate() ?? DateTime.now();
                          final formattedDate = DateFormat(
                            'dd MMM yyyy',
                          ).format(tanggal);

                          // Warna baris bergantian
                          final rowColor = (index + startIndex).isEven
                              ? Colors.grey[50]
                              : Colors.white;

                          return MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Container(
                              // 🔥 FIX: Hapus properti `color` jika menggunakan `decoration`
                              decoration: BoxDecoration(
                                color: rowColor,
                                border: Border(
                                  // Garis pemisah horizontal antar baris
                                  bottom: BorderSide(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Data Cell sudah memiliki garis vertikal di dalamnya
                                  _buildDataCell(nama, flex: 3),
                                  _buildDataCell(rm, flex: 2),
                                  _buildDataCell(diagnosis, flex: 4),
                                  _buildDataCell(formattedDate, flex: 2),
                                  // 🔥 MODIFIKASI: Kolom Status Dihapus
                                  // Kolom Aksi (Tanpa garis vertikal di Data Cell)
                                  Expanded(
                                    flex: 2,
                                    child: Container(
                                      alignment: Alignment.center,
                                      height: 48,
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.print,
                                          size: 18,
                                          color: Colors.blue,
                                        ),
                                        onPressed: () => _printResume(data),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 3. Pagination Controls
                  _buildPaginationControls(),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // WIDGET PAGINATION CONTROLS
  Widget _buildPaginationControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          'Halaman $_currentPage dari $_totalPages',
          style: TextStyle(color: Colors.grey[700]),
        ),
        const SizedBox(width: 20),
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: _currentPage > 1
              ? () {
                  setState(() {
                    _currentPage--;
                  });
                }
              : null,
          color: Colors.black,
          disabledColor: Colors.grey,
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: _currentPage < _totalPages
              ? () {
                  setState(() {
                    _currentPage++;
                  });
                }
              : null,
          color: Colors.black,
          disabledColor: Colors.grey,
        ),
      ],
    );
  }

  // =========================================================
  // LOGIKA FILTER TANGGAL DAN LAPORAN
  // =========================================================

  void _applyDateFilter(String filter) {
    setState(() {
      _periodFilter = filter;
      _startDate = null;
      _endDate = null;
    });
  }

  Future<void> _pickDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );
    if (picked != null) {
      setState(() {
        _periodFilter = 'Kustom';
        // Set awal hari (00:00:00) dan akhir hari (23:59:59)
        _startDate = DateTime(
          picked.start.year,
          picked.start.month,
          picked.start.day,
        );
        _endDate = DateTime(
          picked.end.year,
          picked.end.month,
          picked.end.day,
          23,
          59,
          59,
        );
      });
    }
  }

  // =========================================================
  // FUNGSI CETAK PDF LAPORAN
  // =========================================================
  Future<void> _printLaporan(List<QueryDocumentSnapshot> docs) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.openSansRegular();
    final boldFont = await PdfGoogleFonts.openSansBold();

    final List<pw.TableRow> reportRows = [];
    final totalPasien = docs.length;

    // Header Tabel
    reportRows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.pink600),
        children: [
          _buildPdfTableHeader(
            'Pasien',
            boldFont,
            PdfColors.white,
            align: pw.TextAlign.left,
          ),
          _buildPdfTableHeader(
            'RM',
            boldFont,
            PdfColors.white,
            align: pw.TextAlign.center,
          ),
          _buildPdfTableHeader(
            'Diagnosis',
            boldFont,
            PdfColors.white,
            align: pw.TextAlign.left,
          ),
          _buildPdfTableHeader(
            'Tanggal',
            boldFont,
            PdfColors.white,
            align: pw.TextAlign.center,
          ),
        ],
      ),
    );

    // Isi Tabel
    for (int i = 0; i < docs.length; i++) {
      final data = docs[i].data() as Map<String, dynamic>;
      final nama = data['namaPasien'] as String? ?? '-';
      final rm = data['nomorRekamMedis'] as String? ?? '-';
      final diagnosis = data['diagnosis'] as String? ?? '-';

      // Penanganan Timestamp yang aman
      final tanggalTimestamp = data['tanggal'] as Timestamp?;
      final tanggal = tanggalTimestamp?.toDate() ?? DateTime.now();
      final formattedDate = DateFormat('dd MMM yyyy').format(tanggal);

      final rowColor = i.isEven ? PdfColors.grey100 : PdfColors.white;
      reportRows.add(
        pw.TableRow(
          decoration: pw.BoxDecoration(color: rowColor),
          children: [
            _buildPdfTableCell(nama, font, pw.TextAlign.left),
            _buildPdfTableCell(rm, font, pw.TextAlign.center),
            _buildPdfTableCell(diagnosis, font, pw.TextAlign.left),
            _buildPdfTableCell(formattedDate, font, pw.TextAlign.center),
          ],
        ),
      );
    }

    // Teks Periode
    String periodText = 'Semua Data';
    if (_startDate != null && _endDate != null) {
      final start = DateFormat('dd MMM yyyy').format(_startDate!);
      final end = DateFormat('dd MMM yyyy').format(_endDate!);
      periodText = 'Periode: $start - $end';
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Laporan Pemeriksaan Klinik Pratama Sakura Medical Center',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                font: boldFont,
                color: PdfColors.pink600,
              ),
            ),
            pw.Text(
              periodText,
              style: pw.TextStyle(
                fontSize: 12,
                font: font,
                color: PdfColors.grey600,
              ),
            ),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 15),

            // Tabel Data Pemeriksaan
            pw.Table(
              columnWidths: const {
                0: pw.FlexColumnWidth(3),
                1: pw.FlexColumnWidth(2),
                2: pw.FlexColumnWidth(4),
                3: pw.FlexColumnWidth(2),
              },
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: reportRows,
            ),
            pw.SizedBox(height: 20),

            // Total Pasien
            pw.Text(
              'TOTAL PASIEN DIPERIKSA: $totalPasien',
              style: pw.TextStyle(fontSize: 12, font: boldFont),
            ),
            pw.SizedBox(height: 30),

            pw.Spacer(),

            // Tanda Tangan
            pw.Align(
              alignment: pw.Alignment.topRight,
              child: pw.Text(
                'Bandung, ${DateFormat('dd MMMM yyyy').format(DateTime.now())}',
                style: pw.TextStyle(font: font, fontSize: 10),
              ),
            ),
            pw.SizedBox(height: 50),
            pw.Align(
              alignment: pw.Alignment.topRight,
              child: pw.Text(
                '( $_userName )',
                style: pw.TextStyle(font: boldFont, fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }

  // =========================================================
  // FUNGSI _buildLaporan()
  // =========================================================
  Widget _buildLaporan() {
    // Tentukan query Stream berdasarkan filter
    Query query = FirebaseFirestore.instance
        .collection('resep_obat')
        .orderBy('tanggal', descending: true);

    if (_startDate != null && _endDate != null) {
      query = query
          .where('tanggal', isGreaterThanOrEqualTo: _startDate)
          .where('tanggal', isLessThanOrEqualTo: _endDate);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Laporan Pemeriksaan',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        // Kontrol Periode Waktu
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // ✅ Tombol Pilih Rentang Tanggal
            ElevatedButton.icon(
              onPressed: _pickDateRange,
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Text(
                _startDate == null
                    ? 'Pilih Rentang Tanggal'
                    : 'Periode: ${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}',
              ),
            ),

            // Tombol Cetak dan Total Pasien
            StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];

                return Row(
                  children: [
                    // ✅ Tampilkan Jumlah Pasien di Container terpisah
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Total Pasien: ${docs.length}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // ✅ Tombol Cetak
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEA2070),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: docs.isEmpty
                          ? null
                          : () => _printLaporan(docs),
                      icon: const Icon(Icons.print, size: 16),
                      label: const Text("Cetak Laporan"),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: query.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Text("Error: ${snapshot.error}");
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs;

              if (docs.isEmpty) {
                return Center(
                  child: Text("Tidak ada data pemeriksaan dalam periode ini."),
                );
              }

              return Column(
                children: [
                  // 1. Header Tabel (Sama seperti Riwayat)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        _buildHeaderCell('Pasien', flex: 3),
                        _buildHeaderCell('RM', flex: 2),
                        _buildHeaderCell('Diagnosis', flex: 4),
                        // Kolom Tanggal (Tanpa kolom Aksi)
                        Expanded(
                          flex: 2,
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            child: const Text(
                              'Tanggal',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2. Data Tabel
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(color: Colors.grey.shade300),
                          right: BorderSide(color: Colors.grey.shade300),
                          bottom: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final nama = data['namaPasien'] as String? ?? '-';
                          final rm = data['nomorRekamMedis'] as String? ?? '-';
                          final diagnosis = data['diagnosis'] as String? ?? '-';

                          // Penanganan Timestamp yang aman
                          final tanggalTimestamp =
                              data['tanggal'] as Timestamp?;
                          final tanggal =
                              tanggalTimestamp?.toDate() ?? DateTime.now();
                          final formattedDate = DateFormat(
                            'dd MMM yyyy',
                          ).format(tanggal);

                          // Warna baris bergantian
                          final rowColor = index.isEven
                              ? Colors.grey[50]
                              : Colors.white;

                          return Container(
                            decoration: BoxDecoration(
                              color: rowColor,
                              border: Border(
                                // Garis pemisah horizontal antar baris
                                bottom: BorderSide(color: Colors.grey.shade200),
                              ),
                            ),
                            child: Row(
                              children: [
                                // Data Cell (dengan garis vertikal)
                                _buildDataCell(nama, flex: 3),
                                _buildDataCell(rm, flex: 2),
                                _buildDataCell(diagnosis, flex: 4),
                                // Kolom Tanggal (tanpa garis vertikal di Data Cell)
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    alignment: Alignment.center,
                                    height: 48,
                                    child: Text(
                                      formattedDate,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(': $value', style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(
    IconData icon,
    String title,
    Color color, {
    VoidCallback? onTap,
  }) {
    // ✅ FIX: Tambahkan kondisi agar sidebar item terpilih sesuai dengan _currentView
    final isSelected = _currentView == title;
    final backgroundColor = isSelected
        ? Colors
              .white24 // Warna latar belakang saat terpilih
        : _hoveredItem == title
        ? Colors.white12
        : Colors.transparent;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hoveredItem = title),
      onExit: (_) => setState(() => _hoveredItem = null),
      child: InkWell(
        onTap: () {
          setState(() {
            _currentView = title;
          });
          onTap?.call();
        },
        borderRadius: BorderRadius.circular(8),
        splashColor: Colors.white30,
        highlightColor: Colors.white10,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color:
                backgroundColor, // Menggunakan warna latar belakang yang baru
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              if (!_isSidebarCollapsed) const SizedBox(width: 12),
              if (!_isSidebarCollapsed)
                Text(title, style: TextStyle(color: color, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            IconButton(
              icon: Icon(
                _isSidebarCollapsed ? Icons.menu_open : Icons.menu,
                color: Colors.white,
              ),
              onPressed: () =>
                  setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
            ),
            const SizedBox(width: 8),
            Text(
              'Halo, $_userName',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFFEA2070),
              child: _profileImage != null
                  ? ClipOval(
                      child: Image.memory(
                        _profileImage!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Icon(Icons.person, color: Colors.white, size: 40),
            ),
          ),
        ],
        backgroundColor: const Color(0xFFFF8DAA),
      ),
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _isSidebarCollapsed ? 60 : 200,
            color: const Color(0xFFFFB2D0),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 12,
                  ),
                  child: Row(
                    children: [
                      // Ganti dengan logo Anda yang sesuai
                      // Pastikan aset ini ada
                      // Image.asset(
                      //   'assets/images/logo.png',
                      //   width: 30,
                      //   height: 30,
                      // ),
                      const SizedBox(
                        width: 30,
                        height: 30,
                      ), // Placeholder for logo
                      if (!_isSidebarCollapsed) const SizedBox(width: 12),
                      if (!_isSidebarCollapsed)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Klinik Pratama',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'Sakura Medical Center',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white30, height: 1),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _buildSidebarItem(Icons.home, 'Dashboard', menuColor),
                      _buildSidebarItem(Icons.history, 'Riwayat', menuColor),
                      _buildSidebarItem(
                        Icons.description,
                        'Laporan',
                        menuColor,
                      ),
                      _buildSidebarItem(
                        Icons.logout,
                        'Sign Out',
                        menuColor,
                        onTap: _showLogoutDialog,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }
}
