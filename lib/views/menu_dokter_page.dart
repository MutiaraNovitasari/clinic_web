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
  // ✅ Navigasi (Disesuaikan dengan Resepsionis)
  bool _isSidebarCollapsed = false;
  String? _hoveredItem;
  final Color menuColor = Colors.white;
  String _currentView = 'Dashboard'; // Default view

  // ✅ Profil User
  Uint8List? _profileImage; // Tambahkan untuk konsistensi
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

  // ✅ Laporan (Disesuaikan)
  DateTime _filterDate = DateTime.now();
  String _filterType = 'Harian';

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

  // ✅ Load Nama Dokter & Foto Profil
  Future<void> _loadUserData() async {
    final user = firebase.FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data();
        setState(() {
          _userName = data?['nama'] ?? 'Dokter';
          final imageBytes = data?['profileImage'];
          if (imageBytes is List) {
            _profileImage = Uint8List.fromList(imageBytes.map((e) => e as int).toList());
          }
        });
      }
    }
    setState(() {
      _loading = false;
    });
  }

  // ✅ Logout (Sama seperti Resepsionis)
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

  // ✅ Cetak Resume Pemeriksaan (PDF) - Tetap sama
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

  // ✅ Tampilkan Form Diagnosis & Resep - Tetap sama
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

  // ✅ Hitung jumlah pasien hari ini
  int _countPasienHariIni(List<QueryDocumentSnapshot> docs) {
    final today = DateTime.now();
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final tanggal = (data['tanggalKunjungan'] as Timestamp).toDate();
      return tanggal.day == today.day &&
             tanggal.month == today.month &&
             tanggal.year == today.year;
    }).length;
  }

  // ✅ Build Content (Disesuaikan dengan Resepsionis)
  Widget _buildContent() {
    if (_currentView == 'Dashboard') {
      return _buildDashboard();
    } else if (_currentView == 'Riwayat Pemeriksaan') {
      return _buildRiwayatPemeriksaan();
    } else if (_currentView == 'Laporan') {
      return _buildLaporan();
    }
    return _buildDashboard(); // fallback
  }

  // ✅ Dashboard View (Daftar Anamnesa Awal)
  Widget _buildDashboard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pemeriksaan Utama',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
        ),
        const SizedBox(height: 8),
        const Text(
          'Data pemeriksaan awal dari resepsionis',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 16),

        // 🔍 Search
        TextField(
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
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final data = filtered[index].data() as Map<String, dynamic>;
                  final nama = data['namaPasien'] as String;
                  final rm = data['nomorRekamMedis'] as String;
                  final tanggalKunjungan = (data['tanggalKunjungan'] as Timestamp).toDate();
                  final usia = data['usia'] ?? '-';
                  final jenisKelamin = data['jenisKelamin'] ?? '-';

                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Pasien
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(nama, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    Text('RM: $rm', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                                    Text('Usia: $usia | JK: $jenisKelamin', style: const TextStyle(color: Colors.grey, fontSize: 12)),
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

                          // Tanda Vital
                          const Text('Tanda Vital', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          _buildDataRow('Tekanan Darah', '${data['tekananDarah']} mmHg'),
                          _buildDataRow('Suhu Tubuh', '${data['suhuTubuh']} °C'),
                          _buildDataRow('Tinggi Badan', '${data['tinggiBadan']} cm'),
                          _buildDataRow('Berat Badan', '${data['beratBadan']} kg'),
                          const SizedBox(height: 16),

                          // Action Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () => _printResume(data),
                                icon: const Icon(Icons.print, size: 16),
                                label: const Text('Cetak Resume', style: TextStyle(color: Colors.blue)),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA2070)),
                                onPressed: () => _showDiagnosisForm(data),
                                icon: const Icon(Icons.edit_note, size: 16, color: Colors.white),
                                label: const Text('Diagnosis', style: TextStyle(color: Colors.white)),
                              ),
                            ],
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

  // ✅ Riwayat Pemeriksaan View (Dummy - Bisa dikembangkan)
  Widget _buildRiwayatPemeriksaan() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Riwayat Pemeriksaan',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('resep_obat') // Ambil dari koleksi resep
              .orderBy('tanggal', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("Belum ada riwayat pemeriksaan."));
            }

            final docs = snapshot.data!.docs;

            return Expanded(
              child: ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final tanggal = (data['tanggal'] as Timestamp).toDate();

                  return Card(
                    child: ListTile(
                      title: Text(data['namaPasien']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Diagnosis: ${data['diagnosis']}'),
                          Text('Resep: ${data['resep']}'),
                          Text(DateFormat('dd MMM yyyy, HH:mm').format(tanggal)),
                        ],
                      ),
                      trailing: Text(data['dokter']),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  // ✅ Laporan View (Disesuaikan dengan Resepsionis)
  Widget _buildLaporan() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Laporan Kunjungan Pasien', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          children: [
            DropdownButton<String>(
              value: _filterType,
              items: ['Harian', 'Bulanan', 'Tahunan'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (value) => setState(() => _filterType = value!),
            ),
            const SizedBox(width: 12),
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
            ElevatedButton.icon(
              onPressed: () async {
                // Ambil data dari anamnesa_awal
                final snapshot = await FirebaseFirestore.instance.collection('anamnesa_awal').get();
                final data = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
                final filtered = data.where((item) {
                  final date = (item['tanggalKunjungan'] as Timestamp).toDate();
                  if (_filterType == 'Harian') {
                    return date.day == _filterDate.day && date.month == _filterDate.month && date.year == _filterDate.year;
                  } else if (_filterType == 'Bulanan') {
                    return date.month == _filterDate.month && date.year == _filterDate.year;
                  } else {
                    return date.year == _filterDate.year;
                  }
                }).toList();

                // Buat PDF
                final pdf = pw.Document();
                pdf.addPage(pw.Page(build: (context) => pw.Column(
                  children: [
                    pw.Text('Laporan Kunjungan ${_filterType}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Periode: ${DateFormat('dd/MM/yyyy').format(_filterDate)}'),
                    pw.SizedBox(height: 20),
                    ...filtered.map((item) {
                      final date = (item['tanggalKunjungan'] as Timestamp).toDate();
                      return pw.Column(
                        children: [
                          pw.Text('Nama: ${item['namaPasien']}'),
                          pw.Text('RM: ${item['nomorRekamMedis']}'),
                          pw.Text('Keluhan: ${item['keluhan'] ?? '-'}'),
                          pw.Text('Tanggal: ${DateFormat('dd/MM/yyyy HH:mm').format(date)}'),
                          pw.Divider(),
                        ],
                      );
                    }).toList(),
                  ],
                )));

                await Printing.layoutPdf(onLayout: (_) => pdf.save());
              },
              icon: const Icon(Icons.print),
              label: const Text("Cetak Laporan"),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('anamnesa_awal').orderBy('tanggalKunjungan', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return const Text("Gagal muat data");
              if (!snapshot.hasData) return const CircularProgressIndicator();
              final docs = snapshot.data!.docs;
              final data = docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
              final filtered = data.where((item) {
                final date = (item['tanggalKunjungan'] as Timestamp).toDate();
                if (_filterType == 'Harian') {
                  return date.day == _filterDate.day && date.month == _filterDate.month && date.year == _filterDate.year;
                } else if (_filterType == 'Bulanan') {
                  return date.month == _filterDate.month && date.year == _filterDate.year;
                } else {
                  return date.year == _filterDate.year;
                }
              }).toList();
              return ListView(
                children: filtered.map((item) {
                  final date = (item['tanggalKunjungan'] as Timestamp).toDate();
                  return ListTile(
                    title: Text(item['namaPasien']),
                    subtitle: Text("${item['keluhan'] ?? '-'} | ${DateFormat('dd/MM HH:mm').format(date)}"),
                    trailing: Text(item['nomorRekamMedis']),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  // ✅ Build Sidebar Item (Sama seperti Resepsionis)
  Widget _buildSidebarItem(IconData icon, String title, Color color, {VoidCallback? onTap}) {
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
              if (!_isSidebarCollapsed) Text(title, style: TextStyle(color: color, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Build Data Row (Helper)
  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Text(': $value', style: const TextStyle(fontSize: 14)),
        ],
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
              icon: Icon(_isSidebarCollapsed ? Icons.menu_open : Icons.menu, color: Colors.white),
              onPressed: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
            ),
            const SizedBox(width: 8),
            Text('Halo, $_userName', style: const TextStyle(color: Colors.white)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFFEA2070),
                  child: _profileImage != null
                      ? ClipOval(child: Image.memory(_profileImage!, width: 40, height: 40, fit: BoxFit.cover))
                      : const Icon(Icons.person, color: Colors.white, size: 40),
                ),
                // Tidak ada tombol edit di sini untuk dokter, bisa ditambahkan jika perlu
              ],
            ),
          ),
        ],
        backgroundColor: const Color(0xFFFF8DAA), // Warna AppBar disesuaikan
      ),
      body: Row(
        children: [
          // SIDEBAR (Identik dengan Resepsionis)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _isSidebarCollapsed ? 60 : 200,
            color: const Color(0xFFFFB2D0), // Warna sidebar disesuaikan
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  child: Row(
                    children: [
                      Image.asset('assets/images/logo.png', width: 30, height: 30),
                      if (!_isSidebarCollapsed) const SizedBox(width: 12),
                      if (!_isSidebarCollapsed)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Klinik Pratama', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                              Text('Sakura Medical Center', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
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
                      _buildSidebarItem(Icons.history, 'Riwayat Pemeriksaan', menuColor),
                      _buildSidebarItem(Icons.description, 'Laporan', menuColor),
                      _buildSidebarItem(Icons.logout, 'Sign Out', menuColor, onTap: _showLogoutDialog),
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