// lib/views/menu_resepsionis_page.dart
// ignore_for_file: use_build_context_synchronously
import 'dart:typed_data';
import 'package:clinic_web/utils/kartu_generator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:universal_html/html.dart' as html;
import '../models/pasien_model.dart';
import 'login_page.dart';

class MenuResepsionisPage extends StatefulWidget {
  const MenuResepsionisPage({super.key});

  @override
  State<MenuResepsionisPage> createState() => _MenuResepsionisPageState();
}

class _MenuResepsionisPageState extends State<MenuResepsionisPage> {
  // ✅ Navigasi
  bool _isSidebarCollapsed = false;
  String? _hoveredItem;
  final Color menuColor = Colors.white;
  String _currentView = 'Daftar Pasien';

  // ✅ Profil User
  Uint8List? _profileImage;
  String _userName = 'Resepsionis';
  bool _loading = true;

  // ✅ Form Pasien
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _tanggalLahirController = TextEditingController();
  final TextEditingController _noTeleponController = TextEditingController();
  final TextEditingController _alergiObatController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();

  String? _jenisKelamin;
  String? _status;
  String _searchQuery = '';
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  // ✅ Form Anamnesa Awal
  final TextEditingController _anamnesaNamaController = TextEditingController();
  final TextEditingController _anamnesaRMController = TextEditingController();
  final TextEditingController _tekananDarahController = TextEditingController();
  final TextEditingController _suhuController = TextEditingController();
  final TextEditingController _tinggiController = TextEditingController();
  final TextEditingController _beratController = TextEditingController();
  final TextEditingController _keluhanController = TextEditingController();
  final TextEditingController _tanggalKunjunganController =
      TextEditingController();

  List<Pasien> _daftarPasien = [];

  String? _selectedPasienId;

  // ✅ Laporan
  DateTime _filterDate = DateTime.now();
  String _filterType = 'Harian';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadDaftarPasien();
    _tanggalKunjunganController.text = DateFormat(
      'dd/MM/yyyy HH:mm',
    ).format(DateTime.now());
  }

  @override
  void dispose() {
    _namaController.dispose();
    _tanggalLahirController.dispose();
    _noTeleponController.dispose();
    _alergiObatController.dispose();
    _searchController.dispose();
    _anamnesaNamaController.dispose();
    _anamnesaRMController.dispose();
    _tekananDarahController.dispose();
    _suhuController.dispose();
    _tinggiController.dispose();
    _beratController.dispose();
    _keluhanController.dispose();
    _tanggalKunjunganController.dispose();
    _alamatController.dispose();
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
          _userName = data?['nama'] ?? 'Resepsionis';
          final imageBytes = data?['profileImage'];

          // FIX: Menghilangkan unnecessary cast
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

  Future<void> _loadDaftarPasien() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('pasien')
          .get();
      setState(() {
        _daftarPasien = snapshot.docs
            .map((doc) => Pasien.fromMap(doc.id, doc.data()))
            .toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Gagal muat daftar pasien")));
    }
  }

  Future<void> _uploadImage() async {
    final input = html.FileUploadInputElement()
      ..accept = 'image/*'
      ..click();
    input.onChange.listen((event) {
      final file = input.files!.first;
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      reader.onLoadEnd.listen((e) async {
        final bytes = reader.result as Uint8List;
        final user = firebase.FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({'profileImage': bytes});
          setState(() {
            _profileImage = bytes;
          });
        }
      });
    });
  }

  String _generateNomorRekamMedis() {
    final now = DateTime.now();
    final jam = now.hour.toString().padLeft(2, '0');
    final menit = now.minute.toString().padLeft(2, '0');
    final detik = now.second.toString().padLeft(2, '0');
    return 'RM-$jam$menit$detik';
  }

  void _showAddPasienForm() {
    final contextLocal = context;
    final nomorRekamMedis = _generateNomorRekamMedis();
    _namaController.clear();
    _tanggalLahirController.clear();
    _noTeleponController.clear();
    _alergiObatController.clear();
    _alamatController.clear();
    _jenisKelamin = null;
    _status = null;

    showDialog(
      context: contextLocal,
      builder: (context) {
        return AlertDialog(
          title: const Text("Tambah Pasien Baru"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: TextEditingController(text: nomorRekamMedis),
                  decoration: const InputDecoration(
                    labelText: "Nomor Rekam Medis",
                    border: OutlineInputBorder(),
                  ),
                  readOnly: true,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _namaController,
                  decoration: const InputDecoration(
                    labelText: "Nama Lengkap",
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _alamatController,
                  decoration: const InputDecoration(
                    labelText: "Alamat",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _jenisKelamin,
                  hint: const Text("Pilih Jenis Kelamin"),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: ["Laki-Laki", "Perempuan"].map((e) {
                    return DropdownMenuItem(value: e, child: Text(e));
                  }).toList(),
                  onChanged: (value) => setState(() => _jenisKelamin = value),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _tanggalLahirController,
                  decoration: const InputDecoration(
                    labelText: "Umur (tahun)",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                    hintText: "Contoh: 25",
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _noTeleponController,
                  decoration: const InputDecoration(
                    labelText: "No. Telepon",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _status,
                  hint: const Text("Pilih Status"),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items:
                      [
                        "Belum Bekerja",
                        "Wiraswasta",
                        "Karyawan",
                        "Pelajar/Mahasiswa",
                        "Ibu Rumah Tangga",
                      ].map((e) {
                        return DropdownMenuItem(value: e, child: Text(e));
                      }).toList(),
                  onChanged: (value) => setState(() => _status = value),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _alergiObatController,
                  decoration: const InputDecoration(
                    labelText: "Alergi Obat (Opsional)",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
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
                final nama = _namaController.text.trim();
                final umur = _tanggalLahirController.text.trim();
                if (nama.isEmpty ||
                    _jenisKelamin == null ||
                    umur.isEmpty ||
                    _status == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Nama, Jenis Kelamin, Umur, dan Status wajib diisi",
                      ),
                    ),
                  );
                  return;
                }
                final newPasien = Pasien(
                  id: '',
                  nomorRekamMedis: nomorRekamMedis,
                  namaLengkap: nama,
                  alamat: _alamatController.text.trim(),
                  jenisKelamin: _jenisKelamin!,
                  umur: umur,
                  noTelepon: _noTeleponController.text.trim(),
                  status: _status!,
                  alergiObat: _alergiObatController.text.isEmpty
                      ? null
                      : _alergiObatController.text,
                );
                try {
                  final docRef = await FirebaseFirestore.instance
                      .collection('pasien')
                      .add(newPasien.toMap());
                  final pasienDenganId = newPasien.copyWith(id: docRef.id);
                  await KartuGenerator.printKartu(pasienDenganId);
                  if (contextLocal.mounted) {
                    ScaffoldMessenger.of(contextLocal).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Pasien $nama berhasil ditambahkan dan dicetak",
                        ),
                      ),
                    );
                    Navigator.of(contextLocal).pop();
                    _loadDaftarPasien();
                  }
                } catch (e) {
                  if (contextLocal.mounted) {
                    ScaffoldMessenger.of(contextLocal).showSnackBar(
                      const SnackBar(content: Text("Gagal menyimpan data")),
                    );
                  }
                }
              },
              child: const Text(
                "Simpan",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _editPasien(Pasien pasien) {
    final contextLocal = context;
    _namaController.text = pasien.namaLengkap;
    _alamatController.text = pasien.alamat ?? '';
    _jenisKelamin = pasien.jenisKelamin;
    _tanggalLahirController.text = pasien.umur;
    _noTeleponController.text = pasien.noTelepon;
    _status = pasien.status;
    _alergiObatController.text = pasien.alergiObat ?? '';

    showDialog(
      context: contextLocal,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Pasien"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _namaController,
                  decoration: const InputDecoration(
                    labelText: "Nama Lengkap",
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _alamatController,
                  decoration: const InputDecoration(
                    labelText: "Alamat",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _jenisKelamin,
                  hint: const Text("Pilih Jenis Kelamin"),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: ["Laki-Laki", "Perempuan"]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) => setState(() => _jenisKelamin = value),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _tanggalLahirController,
                  decoration: const InputDecoration(
                    labelText: "Umur (tahun)",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _noTeleponController,
                  decoration: const InputDecoration(
                    labelText: "No. Telepon",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _status,
                  hint: const Text("Pilih Status"),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items:
                      [
                            "Belum Bekerja",
                            "Wiraswasta",
                            "Karyawan",
                            "Pelajar/Mahasiswa",
                            "Ibu Rumah Tangga",
                          ]
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                  onChanged: (value) => setState(() => _status = value),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _alergiObatController,
                  decoration: const InputDecoration(
                    labelText: "Alergi Obat",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
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
                final nama = _namaController.text.trim();
                final umur = _tanggalLahirController.text.trim();
                if (nama.isEmpty ||
                    _jenisKelamin == null ||
                    umur.isEmpty ||
                    _status == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Nama, Jenis Kelamin, Umur, dan Status wajib diisi",
                      ),
                    ),
                  );
                  return;
                }
                final updatedPasien = pasien.copyWith(
                  namaLengkap: nama,
                  alamat: _alamatController.text.trim(),
                  jenisKelamin: _jenisKelamin!,
                  umur: umur,
                  noTelepon: _noTeleponController.text.trim(),
                  status: _status!,
                  alergiObat: _alergiObatController.text.isEmpty
                      ? null
                      : _alergiObatController.text,
                );
                try {
                  await FirebaseFirestore.instance
                      .collection('pasien')
                      .doc(pasien.id)
                      .update(updatedPasien.toMap());
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Pasien $nama diperbarui")),
                  );
                  Navigator.of(context).pop();
                  _loadDaftarPasien();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Gagal memperbarui")),
                  );
                }
              },
              child: const Text(
                "Simpan",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _deletePasien(String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Hapus"),
        content: const Text("Yakin ingin menghapus pasien ini?"),
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
              try {
                await FirebaseFirestore.instance
                    .collection('pasien')
                    .doc(docId)
                    .delete();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text("Pasien dihapus")));
                Navigator.of(context).pop();
                _loadDaftarPasien();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Gagal menghapus")),
                );
              }
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _printPasien(Pasien pasien) async {
    await KartuGenerator.printKartu(pasien);
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

  // lib/views/menu_resepsionis_page.dart (Fokus pada perbaikan _printAnamnesaDetail)

  // =========================================================================
  // ✅ Fungsi Cetak Anamnesa Detail (FIXED: Alignment Data Pasien)
  // =========================================================================
  Future<void> _printAnamnesaDetail(Map<String, dynamic> data) async {
    final pdf = pw.Document();
    final timestamp = data['tanggalKunjungan'] as Timestamp;
    final date = timestamp.toDate();
    final String namaPasien = data['namaPasien'] ?? 'N/A';
    final String nomorRM = data['nomorRekamMedis'] ?? 'N/A';

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          // Gaya teks untuk label
          final labelStyle = pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 10,
          );
          // Gaya teks untuk nilai
          const valueStyle = pw.TextStyle(fontSize: 10);

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Text(
                  'HASIL PEMERIKSAAN AWAL (ANAMNESA)',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Divider(),

              // Data Pasien (PERBAIKAN: Menggunakan pw.Table manual untuk kontrol alignment)
              pw.Text(
                'Data Pasien:',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              pw.SizedBox(height: 5),

              // Mulai Tabel Manual
              pw.Table(
                columnWidths: const {
                  0: pw.FlexColumnWidth(
                    3,
                  ), // Lebar Kolom Label (e.g., Nama Pasien)
                  1: pw.FlexColumnWidth(0.5), // Lebar Kolom Pemisah (:)
                  2: pw.FlexColumnWidth(7), // Lebar Kolom Nilai
                },
                // Hapus border
                border: null,
                children: [
                  // Baris Nama Pasien
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 2),
                        child: pw.Text('Nama Pasien', style: labelStyle),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 2),
                        child: pw.Text(':', style: valueStyle),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 2),
                        child: pw.Text(namaPasien, style: valueStyle),
                      ),
                    ],
                  ),
                  // Baris Nomor Rekam Medis
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 2),
                        child: pw.Text('Nomor Rekam Medis', style: labelStyle),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 2),
                        child: pw.Text(':', style: valueStyle),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 2),
                        child: pw.Text(nomorRM, style: valueStyle),
                      ),
                    ],
                  ),
                  // Baris Tanggal Kunjungan
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 2),
                        child: pw.Text('Tanggal Kunjungan', style: labelStyle),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 2),
                        child: pw.Text(':', style: valueStyle),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 2),
                        child: pw.Text(
                          DateFormat('dd MMMM yyyy HH:mm').format(date),
                          style: valueStyle,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Akhir Tabel Manual
              pw.SizedBox(height: 15),

              // Keluhan Utama (Tanpa Border)
              pw.Text(
                'Keluhan Utama:',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  vertical: 4,
                  horizontal: 0,
                ),
                child: pw.Text(
                  data['keluhan'] ?? 'Tidak ada keluhan tercatat.',
                ),
              ),

              pw.SizedBox(height: 20),

              // Data Pemeriksaan (Header sudah diganti 'Pemeriksaan')
              pw.Text(
                'Data Pemeriksaan Fisik:',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Table.fromTextArray(
                border: pw.TableBorder.all(color: PdfColors.grey500),
                headerAlignment: pw.Alignment.center,
                cellAlignment: pw.Alignment.centerLeft,
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.pink700,
                ),
                columnWidths: const {
                  0: pw.FlexColumnWidth(3),
                  1: pw.FlexColumnWidth(3),
                },
                data: <List<String>>[
                  ['Pemeriksaan', 'Hasil'], // Kolom sudah diperbaiki
                  ['Tekanan Darah', '${data['tekananDarah']} mmHg'],
                  ['Suhu Tubuh', '${data['suhuTubuh']} °C'],
                  ['Tinggi Badan', '${data['tinggiBadan']} cm'],
                  ['Berat Badan', '${data['beratBadan']} kg'],
                ],
              ),

              pw.Spacer(),

              // Footer/Tanda Tangan
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Petugas Resepsionis,',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.SizedBox(height: 40),
                    pw.Text(
                      '( $_userName )',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }

  void _showAnamnesaAwal() {
    _anamnesaNamaController.clear();
    _anamnesaRMController.clear();
    _tekananDarahController.clear();
    _suhuController.clear();
    _tinggiController.clear();
    _beratController.clear();
    _keluhanController.clear();

    _selectedPasienId = null;

    _tanggalKunjunganController.text = DateFormat(
      'dd/MM/yyyy HH:mm',
    ).format(DateTime.now());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Pemeriksaan Awal Pasien"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Supporting text",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                // Nama Pasien
                const Text(
                  "Nama Pasien",
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Autocomplete<Pasien>(
                  optionsBuilder: (TextEditingValue textValue) {
                    if (textValue.text.isEmpty) {
                      return _daftarPasien;
                    }
                    return _daftarPasien.where(
                      (p) => p.namaLengkap.toLowerCase().contains(
                        textValue.text.toLowerCase(),
                      ),
                    );
                  },
                  displayStringForOption: (Pasien p) => p.namaLengkap,
                  onSelected: (Pasien pasien) {
                    setState(() {
                      _anamnesaNamaController.text = pasien.namaLengkap;
                      _anamnesaRMController.text = pasien.nomorRekamMedis;
                      _selectedPasienId = pasien.id;
                      print(
                        'DEBUG: Pasien dipilih - ID: $_selectedPasienId, Nama: ${pasien.namaLengkap}',
                      );
                    });
                  },
                  fieldViewBuilder:
                      (context, controller, focusNode, onFieldSubmitted) {
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            hintText: "Pilih nama pasien",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        );
                      },
                ),
                const SizedBox(height: 16),
                // Nomor RM
                const Text(
                  "Nomor RM",
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _anamnesaRMController,
                  readOnly: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                ),
                const SizedBox(height: 16),
                // Tanggal Kunjungan
                const Text(
                  "Tanggal Kunjungan",
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _tanggalKunjunganController,
                  decoration: InputDecoration(
                    hintText: "Pilih tanggal & waktu",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.calendar_today),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  readOnly: true,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateFormat(
                        'dd/MM/yyyy HH:mm',
                      ).parse(_tanggalKunjunganController.text),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (date == null) return;
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(
                        DateFormat(
                          'dd/MM/yyyy HH:mm',
                        ).parse(_tanggalKunjunganController.text),
                      ),
                    );
                    if (time == null) return;
                    final dateTime = DateTime(
                      date.year,
                      date.month,
                      date.day,
                      time.hour,
                      time.minute,
                    );
                    _tanggalKunjunganController.text = DateFormat(
                      'dd/MM/yyyy HH:mm',
                    ).format(dateTime);
                  },
                ),
                const SizedBox(height: 16),
                // Keluhan
                const Text(
                  "Keluhan",
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _keluhanController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: "Masukkan keluhan pasien",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                // Data Pemeriksaan
                const Text(
                  "Data Pemeriksaan",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  "Tekanan Darah (mmHG)",
                  _tekananDarahController,
                  suffix: "mmHg",
                ),
                const SizedBox(height: 16),
                _buildInputField("Suhu Tubuh", _suhuController, suffix: "°C"),
                const SizedBox(height: 16),
                _buildInputField(
                  "Tinggi Badan (cm)",
                  _tinggiController,
                  suffix: "cm",
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  "Berat Badan (kg)",
                  _beratController,
                  suffix: "kg",
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
                final rm = _anamnesaRMController.text.trim();
                final tekanan = _tekananDarahController.text.trim();
                final suhu = _suhuController.text.trim();
                final tinggi = _tinggiController.text.trim();
                final berat = _beratController.text.trim();
                final keluhan = _keluhanController.text.trim();

                if (_selectedPasienId == null || _selectedPasienId!.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Pilih pasien terlebih dahulu"),
                    ),
                  );
                  return;
                }

                if (rm.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Nomor Rekam Medis tidak boleh kosong"),
                    ),
                  );
                  return;
                }

                if (tekanan.isEmpty ||
                    suhu.isEmpty ||
                    tinggi.isEmpty ||
                    berat.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Semua data pemeriksaan wajib diisi"),
                    ),
                  );
                  return;
                }

                try {
                  final tanggalKunjungan = DateFormat(
                    'dd/MM/yyyy HH:mm',
                  ).parse(_tanggalKunjunganController.text);
                  final dataToSave = {
                    'pasienId': _selectedPasienId,
                    'nomorRekamMedis': rm,
                    'namaPasien': _anamnesaNamaController.text.trim(),
                    'tanggalKunjungan': tanggalKunjungan,
                    'tekananDarah': tekanan,
                    'suhuTubuh': suhu,
                    'tinggiBadan': tinggi,
                    'beratBadan': berat,
                    'keluhan': keluhan,
                    'isDiagnosed': false,
                    'createdAt': FieldValue.serverTimestamp(),
                  };

                  print('DEBUG: Menyimpan data: $dataToSave');

                  await FirebaseFirestore.instance
                      .collection('anamnesa_awal')
                      .add(dataToSave);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Pemeriksaan awal berhasil disimpan"),
                    ),
                  );
                  Navigator.of(context).pop();
                } catch (e) {
                  print('ERROR: Gagal simpan anamnesa: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Gagal menyimpan data: $e")),
                  );
                }
              },
              child: const Text(
                "Simpan Pemeriksaan",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller, {
    String? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: "Masukkan $label",
            suffixText: suffix,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_currentView == 'Daftar Pasien') {
      return _buildDaftarPasien();
    } else if (_currentView == 'Anamnesa Awal') {
      return _buildAnamnesaAwal();
    } else if (_currentView == 'Laporan') {
      return _buildLaporan();
    }
    return _buildDaftarPasien();
  }

  Widget _buildDaftarPasien() {
    return Column(
      children: [
        Row(
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFEA2070),
                side: const BorderSide(color: Color(0xFFEA2070)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text(
                'Tambah Pasien',
                style: TextStyle(fontSize: 14),
              ),
              onPressed: _showAddPasienForm,
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 300,
              height: 33,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari Pasien (Nama atau RM)',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    borderSide: BorderSide(color: Color(0xFFEA2070), width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 14),
                onChanged: (query) {
                  setState(() {
                    _searchQuery = query.trim().toLowerCase();
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('pasien').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text("Gagal memuat data"));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data!.docs;
              final pasienList =
                  docs
                      .map(
                        (doc) => Pasien.fromMap(
                          doc.id,
                          doc.data() as Map<String, dynamic>,
                        ),
                      )
                      .toList()
                    ..sort((a, b) => a.namaLengkap.compareTo(b.namaLengkap));
              final filtered = _searchQuery.isEmpty
                  ? pasienList
                  : pasienList
                        .where(
                          (p) =>
                              p.namaLengkap.toLowerCase().contains(
                                _searchQuery,
                              ) ||
                              p.nomorRekamMedis.toLowerCase().contains(
                                _searchQuery,
                              ),
                        )
                        .toList();
              final totalPages = (filtered.length / _itemsPerPage).ceil();
              final startIndex = (_currentPage - 1) * _itemsPerPage;
              final endIndex = (startIndex + _itemsPerPage).clamp(
                0,
                filtered.length,
              );
              final currentPasien = filtered.sublist(startIndex, endIndex);
              return Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Expanded(flex: 1, child: _buildHeaderCell('No')),
                        Expanded(flex: 3, child: _buildHeaderCell('Nama')),
                        Expanded(flex: 2, child: _buildHeaderCell('RM')),
                        Expanded(flex: 2, child: _buildHeaderCell('Alamat')),
                        Expanded(flex: 2, child: _buildHeaderCell('JK')),
                        Expanded(flex: 2, child: _buildHeaderCell('Umur')),
                        Expanded(flex: 2, child: _buildHeaderCell('No. Telp')),
                        Expanded(flex: 2, child: _buildHeaderCell('Aksi')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView(
                      children: currentPasien.asMap().entries.map((entry) {
                        final index = entry.key + 1;
                        final pasien = entry.value;
                        return MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.grey.shade200),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: _buildDataCell("$index"),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: _buildDataCell(pasien.namaLengkap),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: _buildDataCell(pasien.nomorRekamMedis),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: _buildDataCell(pasien.alamat ?? '-'),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: _buildDataCell(pasien.jenisKelamin),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: _buildDataCell(pasien.umur),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: _buildDataCell(pasien.noTelepon),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    alignment: Alignment.center,
                                    height: 48,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            size: 18,
                                            color: Color(0xFFEA2070),
                                          ),
                                          onPressed: () => _editPasien(pasien),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            size: 18,
                                            color: Color(0xFFEA2070),
                                          ),
                                          onPressed: () =>
                                              _deletePasien(pasien.id),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.print,
                                            size: 18,
                                            color: Colors.blue,
                                          ),
                                          onPressed: () => _printPasien(pasien),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  if (totalPages > 1)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Halaman $_currentPage dari $totalPages'),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              onPressed: _currentPage == 1
                                  ? null
                                  : () => setState(() => _currentPage--),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: _currentPage == totalPages
                                  ? null
                                  : () => setState(() => _currentPage++),
                            ),
                          ],
                        ),
                      ],
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAnamnesaAwal() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Anamnesa Awal Pasien',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _showAnamnesaAwal,
          icon: const Icon(Icons.add),
          label: const Text("Tambah Pemeriksaan"),
        ),
        const SizedBox(height: 16),
        Flexible(
          fit: FlexFit.tight,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('anamnesa_awal')
                .orderBy('tanggalKunjungan', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text("Error: ${snapshot.error}");
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text("Belum ada data anamnesa awal."),
                );
              }
              final docs = snapshot.data!.docs;
              return Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Expanded(flex: 1, child: _buildHeaderCell('No')),
                        Expanded(flex: 3, child: _buildHeaderCell('Nama')),
                        Expanded(flex: 2, child: _buildHeaderCell('RM')),
                        Expanded(flex: 2, child: _buildHeaderCell('Keluhan')),
                        Expanded(flex: 2, child: _buildHeaderCell('Tanggal')),
                        Expanded(flex: 2, child: _buildHeaderCell('Aksi')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView(
                      children: docs.asMap().entries.map((entry) {
                        final index = entry.key + 1;
                        // ✅ PERBAIKAN: Cast ke Map<String, dynamic> yang lebih aman
                        final data = entry.value.data() is Map<String, dynamic>
                            ? entry.value.data() as Map<String, dynamic>
                            : <String, dynamic>{};

                        // Cek apakah 'tanggalKunjungan' ada dan bertipe Timestamp sebelum diakses
                        final Timestamp? timestamp =
                            data['tanggalKunjungan'] is Timestamp
                            ? data['tanggalKunjungan']
                            : null;

                        final date =
                            timestamp?.toDate() ??
                            DateTime.now(); // Default ke waktu sekarang jika null

                        return MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.grey.shade200),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: _buildDataCell("$index"),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: _buildDataCell(
                                    data['namaPasien'] ?? '-',
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: _buildDataCell(
                                    data['nomorRekamMedis'] ?? '-',
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: _buildDataCell(data['keluhan'] ?? '-'),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: _buildDataCell(
                                    DateFormat('dd/MM HH:mm').format(date),
                                  ),
                                ),
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
                                      onPressed: () async {
                                        // Pastikan timestamp tidak null sebelum memanggil _printAnamnesaDetail
                                        if (timestamp != null) {
                                          await _printAnamnesaDetail(data);
                                        } else {
                                          // Tampilkan error jika data tidak valid
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                "Data kunjungan tidak lengkap/valid.",
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
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

  Widget _buildLaporan() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Laporan Kunjungan Pasien',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            // Dropdown Filter
            DropdownButton<String>(
              value: _filterType,
              items: [
                'Harian',
                'Bulanan',
                'Tahunan',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (value) => setState(() => _filterType = value!),
            ),
            const SizedBox(width: 12),
            // Tombol Pilih Tanggal
            ElevatedButton.icon(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _filterDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (date != null) {
                  setState(() => _filterDate = date);
                }
              },
              icon: const Icon(Icons.calendar_today),
              label: Text(DateFormat('dd/MM/yyyy').format(_filterDate)),
            ),
            const SizedBox(width: 12),
            // Tombol CETAK LAPORAN (Bagian yang Diperbaiki)
            ElevatedButton.icon(
              onPressed: () async {
                // 1. Ambil dan Filter Data
                final snapshot = await FirebaseFirestore.instance
                    .collection('anamnesa_awal')
                    .get();
                final data = snapshot.docs.map((doc) => doc.data()).toList();
                final filtered = data.where((item) {
                  // Tambahkan pengecekan tipe data untuk 'tanggalKunjungan'
                  if (item['tanggalKunjungan'] is! Timestamp) return false;

                  final date = (item['tanggalKunjungan'] as Timestamp).toDate();
                  if (_filterType == 'Harian') {
                    return date.day == _filterDate.day &&
                        date.month == _filterDate.month &&
                        date.year == _filterDate.year;
                  } else if (_filterType == 'Bulanan') {
                    return date.month == _filterDate.month &&
                        date.year == _filterDate.year;
                  } else {
                    return date.year == _filterDate.year;
                  }
                }).toList();

                if (filtered.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Tidak ada data untuk periode ini."),
                    ),
                  );
                  return;
                }

                // 2. Siapkan Data untuk Tabel PDF
                // Kolom Header Tabel
                final headers = [
                  'No',
                  'Waktu Kunjungan',
                  'RM',
                  'Nama Pasien',
                  'Keluhan Utama',
                ];

                // Isi Data Tabel
                final tableData = filtered.asMap().entries.map((entry) {
                  int index = entry.key;
                  Map<String, dynamic> item = entry.value;
                  // Asumsi sudah difilter, jadi 'tanggalKunjungan' pasti Timestamp
                  final date = (item['tanggalKunjungan'] as Timestamp).toDate();

                  return [
                    (index + 1).toString(),
                    DateFormat('dd/MM/yyyy HH:mm').format(date),
                    item['nomorRekamMedis'] ?? '-',
                    item['namaPasien'] ?? '-',
                    item['keluhan'] ?? '-',
                  ];
                }).toList();

                // 3. Buat Dokumen PDF dengan Tabel
                final pdf = pw.Document();
                pdf.addPage(
                  pw.Page(
                    build: (context) => pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Judul Laporan
                        pw.Text(
                          'Laporan Kunjungan Pasien $_filterType',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          'Periode: ${DateFormat('dd/MM/yyyy').format(_filterDate)}',
                        ),
                        pw.SizedBox(height: 20),

                        // 🚀 Tabel PDF (Implementasi Perbaikan)
                        pw.Table.fromTextArray(
                          headers: headers,
                          data: tableData,
                          border: pw.TableBorder.all(), // Tambahkan border
                          headerStyle: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                          headerDecoration: const pw.BoxDecoration(
                            color: PdfColors.pink600,
                          ),
                          cellAlignment: pw.Alignment.centerLeft,
                          cellStyle: const pw.TextStyle(fontSize: 10),
                          columnWidths: {
                            0: const pw.FixedColumnWidth(0.7), // No.
                            1: const pw.FixedColumnWidth(2.5), // Tgl/Waktu
                            2: const pw.FixedColumnWidth(2), // RM
                            3: const pw.FixedColumnWidth(3), // Nama Pasien
                            4: const pw.FixedColumnWidth(4), // Keluhan
                          },
                        ),
                      ],
                    ),
                  ),
                );
                // 4. Tampilkan atau Cetak PDF
                await Printing.layoutPdf(onLayout: (_) => pdf.save());
              },
              icon: const Icon(Icons.print),
              label: const Text("Cetak Laporan"),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Data di UI (Tidak Berubah)
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('anamnesa_awal')
                .orderBy('tanggalKunjungan', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              // ... (Kode ListView tetap sama)
              if (snapshot.hasError) return const Text("Gagal muat data");
              if (!snapshot.hasData) return const CircularProgressIndicator();
              final docs = snapshot.data!.docs;
              final data = docs
                  .map((doc) => doc.data() as Map<String, dynamic>)
                  .toList();
              final filtered = data.where((item) {
                // Tambahkan pengecekan tipe data untuk 'tanggalKunjungan'
                if (item['tanggalKunjungan'] is! Timestamp) return false;

                final date = (item['tanggalKunjungan'] as Timestamp).toDate();
                if (_filterType == 'Harian') {
                  return date.day == _filterDate.day &&
                      date.month == _filterDate.month &&
                      date.year == _filterDate.year;
                } else if (_filterType == 'Bulanan') {
                  return date.month == _filterDate.month &&
                      date.year == _filterDate.year;
                } else {
                  return date.year == _filterDate.year;
                }
              }).toList();
              return ListView(
                children: filtered.map((item) {
                  // Asumsi sudah difilter, jadi 'tanggalKunjungan' pasti Timestamp
                  final date = (item['tanggalKunjungan'] as Timestamp).toDate();
                  return ListTile(
                    title: Text(item['namaPasien'] ?? '-'),
                    subtitle: Text(
                      "${item['keluhan'] ?? '-'} | ${DateFormat('dd/MM HH:mm').format(date)}",
                    ),
                    trailing: Text(item['nomorRekamMedis'] ?? '-'),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCell(String label) {
    return Container(
      alignment: Alignment.center,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDataCell(String text) {
    return Container(
      alignment: Alignment.center,
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Text(text, textAlign: TextAlign.center),
    );
  }

  Widget _buildSidebarItem(
    IconData icon,
    String title,
    Color color, {
    VoidCallback? onTap,
  }) {
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
            color: _hoveredItem == title ? Colors.white12 : Colors.transparent,
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
            child: Stack(
              alignment: Alignment.center,
              children: [
                GestureDetector(
                  onTap: _uploadImage,
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
                        : Image.asset(
                            'assets/images/pp.jpg',
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEA2070),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        backgroundColor: const Color(0xFFFF8DAA),
      ),
      body: Row(
        children: [
          // SIDEBAR
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
                      Image.asset(
                        'assets/images/logo.png',
                        width: 30,
                        height: 30,
                      ),
                      if (!_isSidebarCollapsed) const SizedBox(width: 12),
                      if (!_isSidebarCollapsed)
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Klinik Pratama',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                              Text(
                                'Sakura Medical Center',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
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
                      _buildSidebarItem(
                        Icons.person_add,
                        'Daftar Pasien',
                        menuColor,
                      ),
                      _buildSidebarItem(
                        Icons.edit_note,
                        'Anamnesa Awal',
                        menuColor,
                      ),
                      _buildSidebarItem(Icons.bar_chart, 'Laporan', menuColor),
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
          // KONTEN UTAMA
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
