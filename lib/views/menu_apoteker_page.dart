// lib/views/menu_apoteker_page.dart
// ignore_for_file: use_build_context_synchronously
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/obat_model.dart';
import 'login_page.dart';

class MenuApotekerPage extends StatefulWidget {
  const MenuApotekerPage({super.key});

  @override
  State<MenuApotekerPage> createState() => _MenuApotekerPageState();
}

class _MenuApotekerPageState extends State<MenuApotekerPage> {
  // Navigasi
  bool _isSidebarCollapsed = false;
  String? _hoveredItem;
  final Color menuColor = Colors.white;
  String _currentView = 'Data Obat'; // Default view

  // Form Obat
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _kategoriController = TextEditingController();
  final TextEditingController _stokController = TextEditingController();
  final TextEditingController _hargaController = TextEditingController();

  // Dropdown Obat
  String? _jenisObat;

  // Search & Pagination Obat
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  // Hover row
  int? _hoveredRow;

  // 🔹 Filter Tanggal untuk Riwayat & Laporan
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  String _periodeFilter = 'Mingguan';

  @override
  void dispose() {
    _namaController.dispose();
    _kategoriController.dispose();
    _stokController.dispose();
    _hargaController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Tambah Obat
  void _showAddObatForm() {
    final contextLocal = context;

    _namaController.clear();
    _kategoriController.clear();
    _stokController.clear();
    _hargaController.clear();
    _jenisObat = null;

    showDialog(
      context: contextLocal,
      builder: (context) {
        return AlertDialog(
          title: const Text("Tambah Obat Baru"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _namaController,
                  decoration: const InputDecoration(
                    labelText: "Nama Obat",
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _kategoriController,
                  decoration: const InputDecoration(
                    labelText: "Kategori Obat",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _stokController,
                  decoration: const InputDecoration(
                    labelText: "Stok Obat",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.inventory),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _jenisObat,
                  hint: const Text("Pilih Jenis Obat"),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items:
                      [
                            'Tablet',
                            'Sirup',
                            'Obat Oles',
                            'Obat Tetes',
                            'Kapsul',
                            'Supositoria',
                          ]
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                  onChanged: (value) {
                    setState(() {
                      _jenisObat = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _hargaController,
                  decoration: const InputDecoration(
                    labelText: "Harga Obat",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
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
                final nama = _namaController.text.trim();
                final kategori = _kategoriController.text.trim();
                final stokText = _stokController.text.trim();
                final hargaText = _hargaController.text.trim();

                if (nama.isEmpty ||
                    kategori.isEmpty ||
                    stokText.isEmpty ||
                    hargaText.isEmpty ||
                    _jenisObat == null) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Semua field wajib diisi")),
                    );
                  }
                  return;
                }

                final stok = int.tryParse(stokText);
                final harga = int.tryParse(hargaText);

                if (stok == null || harga == null) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Stok dan Harga harus angka"),
                      ),
                    );
                  }
                  return;
                }

                try {
                  final newObat = Obat(
                    id: '',
                    namaObat: nama,
                    kategoriObat: kategori,
                    stokObat: stok,
                    jenisObat: _jenisObat!,
                    harga: harga,
                  );

                  await FirebaseFirestore.instance
                      .collection('obat')
                      .add(newObat.toMap());

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Obat $nama berhasil ditambahkan"),
                      ),
                    );
                    Navigator.of(context).pop();
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Gagal menyimpan ke database"),
                      ),
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

  // Edit Obat
  void _editObat(Obat obat) {
    final contextLocal = context;

    _namaController.text = obat.namaObat;
    _kategoriController.text = obat.kategoriObat;
    _stokController.text = obat.stokObat.toString();
    _hargaController.text = obat.harga.toString();
    _jenisObat = obat.jenisObat;

    showDialog(
      context: contextLocal,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Obat"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _namaController,
                  decoration: const InputDecoration(
                    labelText: "Nama Obat",
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _kategoriController,
                  decoration: const InputDecoration(
                    labelText: "Kategori Obat",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _stokController,
                  decoration: const InputDecoration(
                    labelText: "Stok Obat",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.inventory),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _jenisObat,
                  hint: const Text("Pilih Jenis Obat"),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items:
                      [
                            'Tablet',
                            'Sirup',
                            'Obat Oles',
                            'Obat Tetes',
                            'Kapsul',
                            'Supositoria',
                          ]
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                  onChanged: (value) {
                    setState(() {
                      _jenisObat = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _hargaController,
                  decoration: const InputDecoration(
                    labelText: "Harga Obat",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
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
                final nama = _namaController.text.trim();
                final kategori = _kategoriController.text.trim();
                final stokText = _stokController.text.trim();
                final hargaText = _hargaController.text.trim();

                if (nama.isEmpty ||
                    kategori.isEmpty ||
                    stokText.isEmpty ||
                    hargaText.isEmpty ||
                    _jenisObat == null) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Semua field wajib diisi")),
                    );
                  }
                  return;
                }

                final stok = int.tryParse(stokText);
                final harga = int.tryParse(hargaText);

                if (stok == null || harga == null) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Stok dan Harga harus angka"),
                      ),
                    );
                  }
                  return;
                }

                try {
                  final updatedObat = Obat(
                    id: obat.id,
                    namaObat: nama,
                    kategoriObat: kategori,
                    stokObat: stok,
                    jenisObat: _jenisObat!,
                    harga: harga,
                  );

                  await FirebaseFirestore.instance
                      .collection('obat')
                      .doc(obat.id)
                      .update(updatedObat.toMap());

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Obat $nama berhasil diperbarui")),
                    );
                    Navigator.of(context).pop();
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Gagal memperbarui data")),
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

  // Hapus Obat
  void _deleteObat(String docId) {
    final contextLocal = context;
    showDialog(
      context: contextLocal,
      builder: (context) {
        return AlertDialog(
          title: const Text("Konfirmasi Hapus"),
          content: const Text("Yakin ingin menghapus obat ini?"),
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
                      .collection('obat')
                      .doc(docId)
                      .delete();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Obat berhasil dihapus")),
                    );
                    Navigator.of(context).pop();
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Gagal menghapus obat")),
                    );
                  }
                }
              },
              child: const Text("Hapus", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // Logout
  void _showLogoutDialog() {
    final contextLocal = context;
    showDialog(
      context: contextLocal,
      builder: (context) {
        return AlertDialog(
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
                if (context.mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                }
              },
              child: const Text(
                "Keluar",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // Build Content
  Widget _buildContent() {
    switch (_currentView) {
      case 'Data Obat':
        return _buildDataObat();
      case 'Resep Obat':
        return _buildResepObat();
      case 'Riwayat':
        return _buildRiwayat();
      case 'Laporan Obat':
        return _buildLaporanObat();
      case 'Pembayaran':
        return _buildPembayaran();
      default:
        return _buildDataObat();
    }
  }

  // Data Obat
  Widget _buildDataObat() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Daftar Obat',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _showAddObatForm,
              icon: const Icon(Icons.add),
              label: const Text("Tambah Obat"),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari Obat...',
                  prefixIcon: const Icon(Icons.search),
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
                  if (mounted) {
                    setState(() {
                      _searchQuery = query.toLowerCase();
                    });
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('obat').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs;
              final obatList = docs
                  .map(
                    (doc) => Obat.fromMap(
                      doc.id,
                      doc.data() as Map<String, dynamic>,
                    ),
                  )
                  .where((o) => o.namaObat.toLowerCase().contains(_searchQuery))
                  .toList();

              final totalPages = (obatList.length / _itemsPerPage).ceil();
              final startIndex = (_currentPage - 1) * _itemsPerPage;
              final endIndex = (startIndex + _itemsPerPage).clamp(
                0,
                obatList.length,
              );
              final currentObat = obatList.sublist(startIndex, endIndex);

              return Column(
                children: [
                  _buildHeaderRow(),
                  Expanded(
                    child: ListView(
                      children: currentObat.asMap().entries.map((entry) {
                        final index = entry.key + 1;
                        final obat = entry.value;
                        return MouseRegion(
                          onEnter: (_) => setState(() => _hoveredRow = index),
                          onExit: (_) => setState(() => _hoveredRow = null),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            decoration: BoxDecoration(
                              color: _hoveredRow == index
                                  ? Colors.grey.shade100
                                  : Colors.transparent,
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
                                  child: _buildDataCell(obat.namaObat),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: _buildDataCell(obat.kategoriObat),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: _buildDataCell(
                                    obat.stokObat.toString(),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: _buildDataCell(obat.jenisObat),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: _buildDataCell("${obat.harga}"),
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
                                          onPressed: () => _editObat(obat),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            size: 18,
                                            color: Color(0xFFEA2070),
                                          ),
                                          onPressed: () => _deleteObat(obat.id),
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

  // Resep Obat (Dari Dokter)
  Widget _buildResepObat() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resep Obat dari Dokter',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Text("Daftar resep yang dikirim oleh dokter."),
        const SizedBox(height: 24),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('resep_obat')
                .where('status', whereIn: ['Baru', 'Diproses'])
                .orderBy('tanggal', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return const Text("Gagal memuat resep");
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return const Center(
                  child: Text("Belum ada resep dari dokter."),
                );
              }

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final resepId = docs[index].id;
                  final namaPasien = data['namaPasien'] ?? 'Tidak Diketahui';
                  final rm = data['nomorRekamMedis'] ?? 'RM-000';
                  final diagnosis = data['diagnosis'] ?? '-';
                  final obatList = data['obat'] as List<dynamic>? ?? [];

                  final dokter = data['dokter'] ?? 'Dokter Tidak Diketahui';
                  final biayaPelayanan = data['biayaPemeriksaan'] as int? ?? 0;

                  final aturanPakaiObat = data['aturan'] ?? '-';

                  final tanggal =
                      (data['tanggal'] as Timestamp?)?.toDate() ??
                      DateTime.now();
                  final status = data['status'] ?? 'Tidak Diketahui';

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
                                  color: status == 'Baru'
                                      ? Colors.orange.shade100
                                      : status == 'Diproses'
                                      ? Colors.blue.shade100
                                      : Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: TextStyle(
                                    color: status == 'Baru'
                                        ? Colors.orange
                                        : status == 'Diproses'
                                        ? Colors.blue
                                        : Colors.green,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text("Pasien: $namaPasien"),
                          Text("Dokter: $dokter"),
                          Text(
                            "Tanggal: ${DateFormat('dd/MM/yyyy HH:mm').format(tanggal)}",
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Diagnosis:",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(diagnosis),
                          const SizedBox(height: 8),
                          const Text(
                            "Biaya Pelayanan:",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "Rp ${biayaPelayanan.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.')}",
                          ),

                          const SizedBox(height: 8),
                          const Text(
                            "Resep Obat:",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          if (obatList.isEmpty)
                            const Padding(
                              padding: EdgeInsets.only(left: 8.0),
                              child: Text("-"),
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: obatList.map((obatData) {
                                final nama =
                                    obatData['nama'] as String? ?? 'N/A';
                                final jumlah =
                                    obatData['jumlah'] as String? ?? 'N/A';
                                final aturan =
                                    obatData['aturan'] as String? ?? 'N/A';

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 3.0,
                                    horizontal: 8.0,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "•  ",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          "$nama x$jumlah",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        flex: 4,
                                        child: Text("→ $aturan"),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),

                          // PERBAIKAN: Bagian Aturan Pemakaian Obat dihapus dari tampilan menu resep obat
                          // const SizedBox(height: 8),
                          // const Text(
                          //   "Aturan Pemakaian Obat:",
                          //   style: TextStyle(fontWeight: FontWeight.bold),
                          // ),
                          // Text(aturanPakaiObat),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              if (status == 'Baru')
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                  ),
                                  onPressed: () async {
                                    await FirebaseFirestore.instance
                                        .collection('resep_obat')
                                        .doc(resepId)
                                        .update({'status': 'Diproses'});
                                  },
                                  child: const Text(
                                    "Proses",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              if (status == 'Diproses')
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                  onPressed: () async {
                                    final docSnapshot = await FirebaseFirestore
                                        .instance
                                        .collection('resep_obat')
                                        .doc(resepId)
                                        .get();

                                    if (!docSnapshot.exists) return;

                                    final data =
                                        docSnapshot.data()
                                            as Map<String, dynamic>;

                                    // PERBAIKAN: Tambahkan field 'sudahDibayar' sebagai penanda di riwayat_resep
                                    await FirebaseFirestore.instance
                                        .collection('riwayat_resep')
                                        .add({
                                          ...data,
                                          'status': 'Selesai',
                                          'selesaiAt':
                                              FieldValue.serverTimestamp(),
                                          'sudahDibayar':
                                              false, // Baru ditambahkan
                                        });

                                    await FirebaseFirestore.instance
                                        .collection('resep_obat')
                                        .doc(resepId)
                                        .update({'status': 'Sudah Bayar'});

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Resep berhasil diproses dan dipindahkan ke Riwayat",
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    "Selesai",
                                    style: TextStyle(color: Colors.white),
                                  ),
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

  // Riwayat Resep Obat (dengan Filter & Cetak)
  Widget _buildRiwayat() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Riwayat Resep Obat',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            DropdownButton<String>(
              value: _periodeFilter,
              items: [
                'Harian',
                'Mingguan',
                'Bulanan',
                'Custom',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (value) {
                setState(() {
                  _periodeFilter = value!;
                  final now = DateTime.now();
                  _endDate = now;
                  _startDate = value == 'Harian'
                      ? now.subtract(const Duration(days: 1))
                      : value == 'Mingguan'
                      ? now.subtract(const Duration(days: 7))
                      : value == 'Bulanan'
                      ? now.subtract(const Duration(days: 30))
                      : now.subtract(const Duration(days: 1));
                });
              },
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () async {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  initialDateRange: DateTimeRange(
                    start: _startDate,
                    end: _endDate,
                  ),
                );
                if (picked != null) {
                  setState(() {
                    _startDate = picked.start;
                    _endDate = picked.end;
                    _periodeFilter = 'Custom';
                  });
                }
              },
              icon: const Icon(Icons.calendar_today, size: 16),
              label: const Text(
                "Pilih Tanggal",
                style: TextStyle(fontSize: 12),
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () async {
                final filteredDocs = await FirebaseFirestore.instance
                    .collection('riwayat_resep')
                    .where(
                      'selesaiAt',
                      isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate),
                    )
                    .where(
                      'selesaiAt',
                      isLessThanOrEqualTo: Timestamp.fromDate(
                        _endDate.add(const Duration(days: 1)),
                      ),
                    )
                    .orderBy('selesaiAt', descending: true)
                    .get();

                final data = filteredDocs.docs
                    .map((doc) => doc.data())
                    .toList();

                await _cetakLaporanRiwayat(data, _startDate, _endDate);
              },
              icon: const Icon(Icons.print, size: 18),
              label: const Text("Cetak Laporan"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEA2070),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text("Daftar resep yang telah selesai diproses."),
        const SizedBox(height: 24),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('riwayat_resep')
                .where(
                  'selesaiAt',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate),
                )
                .where(
                  'selesaiAt',
                  isLessThanOrEqualTo: Timestamp.fromDate(
                    _endDate.add(const Duration(days: 1)),
                  ),
                )
                .orderBy('selesaiAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Text("Gagal: ${snapshot.error}");
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return const Center(child: Text("Belum ada riwayat."));
              }

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final namaPasien = data['namaPasien'] ?? 'Tidak Diketahui';
                  final rm = data['nomorRekamMedis'] ?? 'RM-000';
                  final diagnosis = data['diagnosis'] ?? '-';
                  final obatList = data['obat'] as List<dynamic>? ?? [];

                  final dokter = data['dokter'] ?? 'Dokter Tidak Diketahui';
                  final biayaPelayanan = data['biayaPemeriksaan'] as int? ?? 0;
                  final sudahDibayar = data['sudahDibayar'] as bool? ?? false;

                  final selesaiAt =
                      (data['selesaiAt'] as Timestamp?)?.toDate() ??
                      DateTime.now();

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
                                  color: sudahDibayar
                                      ? Colors.blueGrey.shade100
                                      : Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  sudahDibayar ? "SUDAH BAYAR" : "SELESAI",
                                  style: TextStyle(
                                    color: sudahDibayar
                                        ? Colors.blueGrey
                                        : Colors.green,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text("Pasien: $namaPasien"),
                          Text("Dokter: $dokter"),
                          Text(
                            "Selesai: ${DateFormat('dd/MM/yyyy HH:mm').format(selesaiAt)}",
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Diagnosis:",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(diagnosis),
                          const SizedBox(height: 8),
                          const Text(
                            "Biaya Pelayanan:",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "Rp ${biayaPelayanan.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.')}",
                          ),

                          const SizedBox(height: 8),

                          const Text(
                            "Resep Obat:",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          if (obatList.isEmpty)
                            const Padding(
                              padding: EdgeInsets.only(left: 8.0),
                              child: Text("-"),
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: obatList.map((obatData) {
                                final nama =
                                    obatData['nama'] as String? ?? 'N/A';
                                final jumlah =
                                    obatData['jumlah'] as String? ?? 'N/A';
                                final aturan =
                                    obatData['aturan'] as String? ?? 'N/A';

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 3.0,
                                    horizontal: 8.0,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "•  ", // Poin peluru
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          "$nama x$jumlah",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        flex: 4,
                                        child: Text("→ $aturan"),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
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

  // Laporan Obat (dengan Filter & Cetak)
  Widget _buildLaporanObat() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Laporan Pembayaran Obat',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            DropdownButton<String>(
              value: _periodeFilter,
              items: [
                'Harian',
                'Mingguan',
                'Bulanan',
                'Custom',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (value) {
                setState(() {
                  _periodeFilter = value!;
                  final now = DateTime.now();
                  _endDate = now;
                  _startDate = value == 'Harian'
                      ? now.subtract(const Duration(days: 1))
                      : value == 'Mingguan'
                      ? now.subtract(const Duration(days: 7))
                      : value == 'Bulanan'
                      ? now.subtract(const Duration(days: 30))
                      : now.subtract(const Duration(days: 1));
                });
              },
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () async {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  initialDateRange: DateTimeRange(
                    start: _startDate,
                    end: _endDate,
                  ),
                );
                if (picked != null) {
                  setState(() {
                    _startDate = picked.start;
                    _endDate = picked.end;
                    _periodeFilter = 'Custom';
                  });
                }
              },
              icon: const Icon(Icons.calendar_today, size: 16),
              label: const Text(
                "Pilih Tanggal",
                style: TextStyle(fontSize: 12),
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () async {
                final filteredDocs = await FirebaseFirestore.instance
                    .collection('pembayaran')
                    .where(
                      'dibayarAt',
                      isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate),
                    )
                    .where(
                      'dibayarAt',
                      isLessThanOrEqualTo: Timestamp.fromDate(
                        _endDate.add(const Duration(days: 1)),
                      ),
                    )
                    .orderBy('dibayarAt', descending: true)
                    .get();

                final data = filteredDocs.docs
                    .map((doc) => doc.data())
                    .toList();

                await _cetakLaporanPembayaran(data, _startDate, _endDate);
              },
              icon: const Icon(Icons.print, size: 18),
              label: const Text("Cetak Laporan"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEA2070),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text("Daftar pembayaran yang telah berhasil dilakukan."),
        const SizedBox(height: 24),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('pembayaran')
                .where(
                  'dibayarAt',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate),
                )
                .where(
                  'dibayarAt',
                  isLessThanOrEqualTo: Timestamp.fromDate(
                    _endDate.add(const Duration(days: 1)),
                  ),
                )
                .orderBy('dibayarAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Text("Gagal: ${snapshot.error}");
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return const Center(child: Text("Belum ada pembayaran."));
              }

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final namaPasien = data['namaPasien'] ?? 'Tidak Diketahui';
                  final rm = data['nomorRekamMedis'] ?? 'RM-000';
                  final totalHarga = data['totalHarga'] as int? ?? 0;
                  final dibayarAt =
                      (data['dibayarAt'] as Timestamp?)?.toDate() ??
                      DateTime.now();

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
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  "LUNAS",
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text("Pasien: $namaPasien"),
                          Text(
                            "Total: Rp ${totalHarga.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.')}",
                          ),
                          Text(
                            "Dibayar: ${DateFormat('dd/MM HH:mm').format(dibayarAt)}",
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

  // Pembayaran (Integrasi + Cetak Langsung + Struk Rapih)
  Widget _buildPembayaran() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pembayaran Obat',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Text("Daftar resep yang siap dibayar (Status Selesai)."),
        const SizedBox(height: 24),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('riwayat_resep')
                .where('status', isEqualTo: 'Selesai')
                .orderBy('selesaiAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                final message = snapshot.error.toString();
                if (message.contains('The query requires an index')) {
                  final startIndex = message.indexOf('https://');
                  final endIndex = message.indexOf(')', startIndex);
                  final link = message.substring(startIndex, endIndex);
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text("Perlu buat index di Firestore"),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => launchUrl(Uri.parse(link)),
                          child: const Text("Buat Index Sekarang"),
                        ),
                      ],
                    ),
                  );
                }
                return Text("Gagal: ${snapshot.error}");
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs;

              // Filter hanya dokumen yang BELUM dibayar
              final filteredDocs = docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final sudahDibayar = data['sudahDibayar'] as bool? ?? false;
                return !sudahDibayar;
              }).toList();

              if (filteredDocs.isEmpty) {
                return const Center(
                  child: Text("Belum ada resep yang siap dibayar."),
                );
              }

              return ListView.builder(
                itemCount: filteredDocs.length,
                itemBuilder: (context, index) {
                  final data =
                      filteredDocs[index].data() as Map<String, dynamic>;
                  final resepRiwayatId =
                      filteredDocs[index].id; // ID dokumen di riwayat_resep
                  final namaPasien = data['namaPasien'] ?? 'Tidak Diketahui';
                  final rm = data['nomorRekamMedis'] ?? 'RM-000';
                  final dokter = data['dokter'] ?? 'Dokter Tidak Diketahui';
                  final obatList = data['obat'] as List<dynamic>? ?? [];

                  final selesaiAt =
                      (data['selesaiAt'] as Timestamp?)?.toDate() ??
                      DateTime.now();

                  final rawBiayaPelayanan =
                      data['biayaPemeriksaan'] as int? ?? 0;
                  final aturanPakaiObat = data['aturan'] ?? '-';

                  int totalHarga = 0;
                  List<Map<String, dynamic>> daftarObat = [];

                  return FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance.collection('obat').get(),
                    builder: (context, obatSnapshot) {
                      if (!obatSnapshot.hasData) {
                        return const LinearProgressIndicator();
                      }

                      final obatMap = <String, Obat>{};
                      for (var doc in obatSnapshot.data!.docs) {
                        final obat = Obat.fromMap(
                          doc.id,
                          doc.data() as Map<String, dynamic>,
                        );
                        obatMap[obat.namaObat.toLowerCase()] = obat;
                      }

                      // Kosongkan dulu sebelum menghitung ulang
                      totalHarga = 0;
                      daftarObat = [];

                      for (final obatData in obatList) {
                        final namaObat = obatData['nama'] as String? ?? 'N/A';
                        final jumlahString =
                            obatData['jumlah'] as String? ?? '1';
                        final jumlah = int.tryParse(jumlahString) ?? 1;

                        final obat = obatMap[namaObat.toLowerCase()];
                        if (obat != null) {
                          int subTotal = obat.harga * jumlah;
                          totalHarga += subTotal;
                          daftarObat.add({
                            'nama': obat.namaObat,
                            'jumlah': jumlah,
                            'harga': obat.harga,
                            'subtotal': subTotal,
                            'isService': false, // flag obat
                          });
                        }
                      }

                      totalHarga += rawBiayaPelayanan;
                      daftarObat.add({
                        'nama': 'Biaya Pelayanan',
                        'jumlah': 1,
                        'harga': rawBiayaPelayanan,
                        'subtotal': rawBiayaPelayanan,
                        'isService': true, // flag service
                      });

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                      color: Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      "SIAP BAYAR",
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Text("Pasien: $namaPasien"),
                              Text("Dokter: $dokter"),
                              Text(
                                "Selesai: ${DateFormat('dd/MM/yyyy HH:mm').format(selesaiAt)}",
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Rincian Biaya:",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              ...daftarObat.map(
                                (obat) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 2,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          obat['isService'] == true
                                              ? "${obat['nama']}"
                                              : "${obat['nama']} x${obat['jumlah']}",
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          "Rp ${(obat['subtotal'] as int).toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.')}",
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const Divider(),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Total:",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "Rp ${totalHarga.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.')}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text(
                                        "Konfirmasi Pembayaran",
                                      ),
                                      content: Text(
                                        "Yakin pasien $namaPasien akan membayar total Rp ${totalHarga.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.')}?",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(false),
                                          child: const Text("Batal"),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFFEA2070,
                                            ),
                                          ),
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(true),
                                          child: const Text(
                                            "Ya, Bayar",
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirmed == true) {
                                    // 1. Kurangi stok obat
                                    for (final item in daftarObat) {
                                      if (item['isService'] == true) continue;

                                      final namaObat = item['nama'] as String;
                                      final jumlah = item['jumlah'] as int;

                                      final obatDoc = await FirebaseFirestore
                                          .instance
                                          .collection('obat')
                                          .where(
                                            'namaObat',
                                            isEqualTo: namaObat,
                                          )
                                          .get();

                                      if (obatDoc.docs.isNotEmpty) {
                                        final doc = obatDoc.docs.first;
                                        final stokSaatIni =
                                            doc.get('stokObat') as int?;
                                        final stokBaru =
                                            (stokSaatIni ?? 0) - jumlah;

                                        if (stokBaru >= 0) {
                                          await FirebaseFirestore.instance
                                              .collection('obat')
                                              .doc(doc.id)
                                              .update({'stokObat': stokBaru});
                                        }
                                      }
                                    }

                                    // 2. Tambahkan ke koleksi pembayaran
                                    await FirebaseFirestore.instance
                                        .collection('pembayaran')
                                        .add({
                                          'pasienId': data['pasienId'],
                                          'nomorRekamMedis': rm,
                                          'namaPasien': namaPasien,
                                          'totalHarga': totalHarga,
                                          'obat': obatList,
                                          'biayaPelayanan': rawBiayaPelayanan,
                                          'aturanPakaiObat': aturanPakaiObat,
                                          'dibayarAt':
                                              FieldValue.serverTimestamp(),
                                        });

                                    // 3. Update status di riwayat_resep (TETAP ADA, HANYA DITANDAI SUDAH DIBAYAR)
                                    await FirebaseFirestore.instance
                                        .collection('riwayat_resep')
                                        .doc(resepRiwayatId)
                                        .update({'sudahDibayar': true});

                                    // 4. Cetak Struk
                                    await _cetakStruk(
                                      namaPasien,
                                      rm,
                                      daftarObat,
                                      totalHarga,
                                      dokter,
                                      aturanPakaiObat,
                                    );

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "Pembayaran untuk $namaPasien berhasil dan struk dicetak.",
                                        ),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.payment, size: 18),
                                label: const Text("Bayar & Cetak"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFEA2070),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // Fungsi Cetak Struk
  Future<void> _cetakStruk(
    String namaPasien,
    String rm,
    List<Map<String, dynamic>> daftarObat,
    int totalHarga,
    String dokter,
    String aturanPakaiObat,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5.copyWith(
          marginBottom: 1.5 * PdfPageFormat.cm,
        ),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Header
              pw.Text(
                'Klinik Sakura Medical Center',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text('Apotek & Pelayanan Medis'),
              pw.SizedBox(height: 10),

              pw.Divider(),
              pw.SizedBox(height: 10),

              // Judul
              pw.Text(
                'STRUK PEMBAYARAN OBAT',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),

              // Info Pasien
              _buildPdfRow('Nama Pasien', namaPasien),
              _buildPdfRow('Nomor RM', rm),
              _buildPdfRow('Dokter', dokter),
              _buildPdfRow(
                'Tanggal',
                DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
              ),

              pw.SizedBox(height: 15),

              // Rincian Biaya
              pw.Text(
                'Rincian Biaya:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 5),
              ...daftarObat.map(
                (obat) => _buildPdfRow(
                  obat['isService'] == true
                      ? '${obat['nama']}'
                      : '${obat['nama']} x${obat['jumlah']}',
                  'Rp ${(obat['subtotal'] as int).toString().replaceFirstMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.')}',
                ),
              ),

              pw.Divider(),

              // Total
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    'Rp ${totalHarga.toString().replaceFirstMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.')}',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.red,
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 15),

              // PERBAIKAN: Hapus aturan pemakaian obat di struk pembayaran
              // pw.Text(
              //   'Aturan Pemakaian Obat:',
              //   style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              // ),
              // pw.Text(aturanPakaiObat),
              pw.SizedBox(height: 20),

              // Footer
              pw.Align(
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'Terima kasih atas kunjungan Anda!',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    // Cetak otomatis
    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  // Cetak Laporan Riwayat Resep
  Future<void> _cetakLaporanRiwayat(
    List<dynamic> data,
    DateTime start,
    DateTime end,
  ) async {
    final pdf = pw.Document();
    final pinkColor = PdfColor.fromHex("#D81B60");

    pdf.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(50),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Laporan Riwayat Resep Obat',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Periode: ${DateFormat('dd/MM/yyyy').format(start)} - ${DateFormat('dd/MM/yyyy').format(end)}',
              ),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(width: 1),
                columnWidths: const {
                  0: pw.FixedColumnWidth(50),
                  1: pw.FixedColumnWidth(80),
                  2: pw.FixedColumnWidth(120),
                  3: pw.FixedColumnWidth(100),
                  4: pw.FixedColumnWidth(150),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: pinkColor, // Background Pink600
                    ),
                    children: [
                      // ✅ No
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'No',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 11,
                          ),
                          textAlign: pw.TextAlign.center, // ✅ Teks center
                        ),
                      ),
                      // ✅ RM
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'RM',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 11,
                          ),
                          textAlign: pw.TextAlign.center, // ✅ Teks center
                        ),
                      ),
                      // ✅ Pasien
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Pasien',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 11,
                          ),
                          textAlign: pw.TextAlign.center, // ✅ Teks center
                        ),
                      ),
                      // ✅ Dokter
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Dokter',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 11,
                          ),
                          textAlign: pw.TextAlign.center, // ✅ Teks center
                        ),
                      ),
                      // ✅ Tanggal
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Tanggal',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 11,
                          ),
                          textAlign: pw.TextAlign.center, // ✅ Teks center
                        ),
                      ),
                    ],
                  ),
                  ...data.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final date = (item['selesaiAt'] as Timestamp).toDate();
                    return pw.TableRow(
                      children: [
                        // No
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            '${index + 1}',
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        // RM
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            item['nomorRekamMedis'],
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        // Pasien
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            item['namaPasien'],
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        // Dokter
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            item['dokter'],
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        // Tanggal
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            DateFormat('dd/MM/yyyy HH:mm').format(date),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  // Cetak Laporan Pembayaran
  Future<void> _cetakLaporanPembayaran(
    List<dynamic> data,
    DateTime start,
    DateTime end,
  ) async {
    final pdf = pw.Document();

    // Warna Pink600
    final pinkColor = PdfColor.fromHex("#D81B60");
    int totalLaporan = 0;
    for (final item in data) {
      totalLaporan += (item['totalHarga'] as int? ?? 0);
    }

    pdf.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(30),
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Laporan Pembayaran Obat',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Periode: ${DateFormat('dd/MM/yyyy').format(start)} - ${DateFormat('dd/MM/yyyy').format(end)}',
              ),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(width: 1, color: PdfColors.grey400),
                columnWidths: const {
                  0: pw.FixedColumnWidth(30), // No
                  1: pw.FixedColumnWidth(60), // RM
                  2: pw.FixedColumnWidth(100), // Pasien
                  3: pw.FixedColumnWidth(150), // Obat
                  4: pw.FixedColumnWidth(80), // Total
                  5: pw.FixedColumnWidth(80), // Tanggal
                },
                children: [
                  pw.TableRow(
                    // PERBAIKAN: Ganti warna header dan teks center
                    decoration: pw.BoxDecoration(color: pinkColor),
                    children: [
                      _buildPdfHeaderCell('No', align: pw.Alignment.center),
                      _buildPdfHeaderCell('RM', align: pw.Alignment.center),
                      _buildPdfHeaderCell(
                        'Pasien',
                        align: pw.Alignment.centerLeft,
                      ),
                      _buildPdfHeaderCell(
                        'Obat',
                        align: pw.Alignment.centerLeft,
                      ),
                      _buildPdfHeaderCell(
                        'Total',
                        align: pw.Alignment.centerRight,
                      ),
                      _buildPdfHeaderCell(
                        'Tanggal',
                        align: pw.Alignment.center,
                      ),
                    ],
                  ),
                  ...data.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final date = (item['dibayarAt'] as Timestamp).toDate();
                    final total = (item['totalHarga'] as int)
                        .toString()
                        .replaceAllMapped(
                          RegExp(r'(\d)(?=(\d{3})+$)'),
                          (m) => '${m[1]}.',
                        );

                    // PERBAIKAN: Ambil daftar obat dan format
                    final obatList = item['obat'] as List<dynamic>? ?? [];
                    final namaObatString = obatList
                        .where((o) => o['nama'] != null)
                        .map((o) => '${o['nama']} (x${o['jumlah']})')
                        .join('\n');

                    return pw.TableRow(
                      children: [
                        _buildPdfTableCell(
                          '${index + 1}',
                          align: pw.Alignment.center,
                        ),
                        _buildPdfTableCell(
                          item['nomorRekamMedis'],
                          align: pw.Alignment.center,
                        ),
                        _buildPdfTableCell(
                          item['namaPasien'],
                          align: pw.Alignment.centerLeft,
                        ),
                        _buildPdfTableCell(
                          namaObatString,
                          align: pw.Alignment.centerLeft,
                        ), // Kolom Obat Baru
                        _buildPdfTableCell(
                          'Rp $total',
                          align: pw.Alignment.centerRight,
                        ),
                        _buildPdfTableCell(
                          DateFormat('dd/MM HH:mm').format(date),
                          align: pw.Alignment.center,
                        ),
                      ],
                    );
                  }),
                ],
              ),

              // Total Laporan
              pw.SizedBox(height: 20),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Total Pendapatan (Periode Terpilih):',
                      style: pw.TextStyle(fontSize: 14),
                    ),
                    pw.Text(
                      'Rp ${totalLaporan.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.')}',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: pinkColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  // Helper untuk PDF Table Header
  pw.Widget _buildPdfHeaderCell(String text, {pw.Alignment? align}) {
    return pw.Padding(
      child: pw.Container(
        alignment: align ?? pw.Alignment.center,
        child: pw.Text(
          text,
          style: pw.TextStyle(
            color: PdfColors.white,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ),
      padding: const pw.EdgeInsets.all(8),
    );
  }

  // Helper untuk PDF Table Cell
  pw.Widget _buildPdfTableCell(String text, {pw.Alignment? align}) {
    return pw.Padding(
      child: pw.Container(
        alignment: align ?? pw.Alignment.centerLeft,
        child: pw.Text(text, style: const pw.TextStyle(fontSize: 10)),
      ),
      padding: const pw.EdgeInsets.all(6),
    );
  }

  // Helper untuk baris PDF Struk
  pw.Widget _buildPdfRow(String kiri, String kanan) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(kiri, style: pw.TextStyle(fontSize: 11)),
        pw.Text(kanan, style: pw.TextStyle(fontSize: 11)),
      ],
    );
  }

  // Helper: Header Row
  Widget _buildHeaderRow() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(flex: 1, child: _buildHeaderCell('No')),
          Expanded(flex: 3, child: _buildHeaderCell('Nama Obat')),
          Expanded(flex: 2, child: _buildHeaderCell('Kategori Obat')),
          Expanded(flex: 2, child: _buildHeaderCell('Stok Obat')),
          Expanded(flex: 2, child: _buildHeaderCell('Jenis Obat')),
          Expanded(flex: 2, child: _buildHeaderCell('Harga')),
          Expanded(flex: 2, child: _buildHeaderCell('Aksi')),
        ],
      ),
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

  // Sidebar Item
  Widget _buildSidebarItem(
    IconData icon,
    String title,
    Color color, {
    VoidCallback? onTap,
  }) {
    final isSelected = _currentView == title;

    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.white : color, size: 20),
      title: _isSidebarCollapsed
          ? null
          : Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: () {
        setState(() {
          _currentView = title;
        });
        onTap?.call();
      },
      tileColor: isSelected ? const Color(0xFFEA2070) : null,
      selected: isSelected,
      selectedColor: Colors.white,
      selectedTileColor: const Color(0xFFEA2070),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          ],
        ),
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Apotek dan Klinik Pratama',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                              Text(
                                'Sakura Medical Center',
                                style: const TextStyle(
                                  color: Colors.white,
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
                        Icons.file_copy,
                        'Data Obat',
                        menuColor,
                      ),
                      _buildSidebarItem(
                        Icons.medical_services,
                        'Resep Obat',
                        menuColor,
                      ),
                      _buildSidebarItem(Icons.history, 'Riwayat', menuColor),
                      _buildSidebarItem(
                        Icons.bar_chart,
                        'Laporan Obat',
                        menuColor,
                      ),
                      _buildSidebarItem(Icons.payment, 'Pembayaran', menuColor),
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
