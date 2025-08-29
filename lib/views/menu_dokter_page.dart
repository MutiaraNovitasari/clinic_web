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
import '../models/pasien_model.dart';
import 'login_page.dart';

class MenuDokterPage extends StatefulWidget {
  const MenuDokterPage({super.key});

  @override
  State<MenuDokterPage> createState() => _MenuDokterPageState();
}

class _MenuDokterPageState extends State<MenuDokterPage> {
  // ✅ Profil User
  String _userName = 'Dokter';
  bool _loading = true;

  // ✅ Search
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // ✅ Form Diagnosis & Resep
  final TextEditingController _diagnosisController = TextEditingController();
  final TextEditingController _resepController = TextEditingController();

  // ✅ Data yang dipilih
  Map<String, dynamic>? _selectedAnamnesa;
  String? _selectedPasienId;
  String? _selectedRM;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _diagnosisController.dispose();
    _resepController.dispose();
    super.dispose();
  }

  // ✅ Load Nama Dokter
  Future<void> _loadUserData() async {
    final user = firebase.FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          _userName = doc.data()?['nama'] ?? 'Dokter';
        });
      }
    }
    setState(() {
      _loading = false;
    });
  }

  // ✅ Logout
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Keluar"),
        content: const Text("Yakin ingin keluar dari akun ini?"),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA2070)),
            onPressed: () async {
              await firebase.FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
              }
            },
            child: const Text("Keluar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ✅ Cetak Resume Pemeriksaan (PDF)
  Future<void> _printResume(Map<String, dynamic> data) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.openSansRegular();
    final boldFont = await PdfGoogleFonts.openSansBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(30),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Sakura Medical Center', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, font: boldFont)),
            pw.Text('Resume Pemeriksaan Pasien', style: pw.TextStyle(fontSize: 14, font: boldFont, color: PdfColors.grey)),
            pw.SizedBox(height: 20),
            _buildPdfRow('Nama Pasien', data['namaPasien'], boldFont, font),
            _buildPdfRow('Nomor RM', data['nomorRekamMedis'], boldFont, font),
            _buildPdfRow('Tanggal Kunjungan', DateFormat('dd/MM/yyyy HH:mm').format((data['tanggalKunjungan'] as Timestamp).toDate()), boldFont, font),
            pw.SizedBox(height: 10),
            pw.Text('Data Pemeriksaan Awal', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, font: boldFont)),
            _buildPdfRow('Tekanan Darah', '${data['tekananDarah']} mmHg', boldFont, font),
            _buildPdfRow('Suhu Tubuh', '${data['suhuTubuh']} °C', boldFont, font),
            _buildPdfRow('Tinggi Badan', '${data['tinggiBadan']} cm', boldFont, font),
            _buildPdfRow('Berat Badan', '${data['beratBadan']} kg', boldFont, font),
            pw.SizedBox(height: 20),
            pw.Text('Diagnosis & Resep', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, font: boldFont)),
            _buildPdfRow('Diagnosis', 'Belum diisi', boldFont, font),
            _buildPdfRow('Resep Obat', 'Belum diisi', boldFont, font),
            pw.SizedBox(height: 20),
            pw.Text('Dokter: $_userName', style: pw.TextStyle(font: boldFont, fontSize: 12)),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }

  pw.Widget _buildPdfRow(String label, String value, pw.Font bold, pw.Font normal) {
    return pw.Row(
      children: [
        pw.Expanded(flex: 2, child: pw.Text('$label:', style: pw.TextStyle(font: bold, fontSize: 10))),
        pw.Expanded(flex: 3, child: pw.Text(value, style: pw.TextStyle(font: normal, fontSize: 10))),
      ],
    );
  }

  // ✅ Tampilkan Form Diagnosis & Resep
  void _showDiagnosisForm(Map<String, dynamic> anamnesaData) {
    _selectedPasienId = anamnesaData['pasienId'];
    _selectedRM = anamnesaData['nomorRekamMedis'];
    _diagnosisController.clear();
    _resepController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Diagnosis & Resep"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Pasien: ${anamnesaData['namaPasien']} (${anamnesaData['nomorRekamMedis']})"),
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
                const SizedBox(height: 12),
                TextField(
                  controller: _resepController,
                  decoration: const InputDecoration(
                    labelText: "Resep Obat",
                    border: OutlineInputBorder(),
                    hintText: "Contoh: Paracetamol 500mg, 3x1",
                  ),
                  maxLines: 4,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Batal")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA2070)),
              onPressed: () async {
                final diagnosis = _diagnosisController.text.trim();
                final resep = _resepController.text.trim();

                if (diagnosis.isEmpty || resep.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Diagnosis dan resep wajib diisi")),
                  );
                  return;
                }

                try {
                  await FirebaseFirestore.instance.collection('resep_obat').add({
                    'pasienId': _selectedPasienId,
                    'nomorRekamMedis': _selectedRM,
                    'namaPasien': anamnesaData['namaPasien'],
                    'diagnosis': diagnosis,
                    'resep': resep,
                    'dokter': _userName,
                    'tanggal': DateTime.now(),
                    'status': 'Baru',
                    'createdAt': FieldValue.serverTimestamp(),
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Resep berhasil dikirim ke apoteker")),
                  );
                  Navigator.of(context).pop();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Gagal mengirim resep")),
                  );
                }
              },
              child: const Text("Kirim ke Apoteker", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Halo, $_userName', style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFEA2070),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _showLogoutDialog,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pemeriksaan Awal Pasien',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Data pemeriksaan awal dari resepsionis',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // 🔍 Search
            Row(
              children: [
                SizedBox(
                  width: 300,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari Pasien (Nama/RM)...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Daftar Anamnesa Awal
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('anamnesa_awal')
                    .orderBy('tanggalKunjungan', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text("Gagal memuat data pemeriksaan awal"));
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  // 🔍 Filter berdasarkan search
                  final filtered = _searchQuery.isEmpty
                      ? docs
                      : docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return (data['namaPasien'] as String).toLowerCase().contains(_searchQuery) ||
                              (data['nomorRekamMedis'] as String).toLowerCase().contains(_searchQuery);
                        }).toList();

                  if (filtered.isEmpty) {
                    return const Center(child: Text("Tidak ada data yang cocok"));
                  }

                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const Divider(height: 32),
                    itemBuilder: (context, index) {
                      final data = filtered[index].data() as Map<String, dynamic>;
                      final nama = data['namaPasien'] as String;
                      final rm = data['nomorRekamMedis'] as String;
                      final tanggalKunjungan = (data['tanggalKunjungan'] as Timestamp).toDate();

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(nama, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                      Text('RM: $rm', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                                    ],
                                  ),
                                ),
                                Text(
                                  DateFormat('dd MMM yyyy, HH:mm').format(tanggalKunjungan),
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildDataRow('Tekanan Darah', '${data['tekananDarah']} mmHg'),
                            _buildDataRow('Suhu Tubuh', '${data['suhuTubuh']} °C'),
                            _buildDataRow('Tinggi Badan', '${data['tinggiBadan']} cm'),
                            _buildDataRow('Berat Badan', '${data['beratBadan']} kg'),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => _printResume(data),
                                  child: const Text('🖨️ Cetak Resume', style: TextStyle(color: Colors.blue)),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA2070)),
                                  onPressed: () => _showDiagnosisForm(data),
                                  child: const Text('📝 Diagnosis', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Text(': $value', style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}