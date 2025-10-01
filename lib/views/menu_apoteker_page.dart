// lib/views/menu_apoteker_page.dart
// ignore_for_file: use_build_context_synchronously
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: ['Tablet', 'Sirup', 'Obat Oles', 'Obat Tetes', 'Kapsul', 'Supositoria']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
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
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Batal")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA2070)),
              onPressed: () async {
                final nama = _namaController.text.trim();
                final kategori = _kategoriController.text.trim();
                final stokText = _stokController.text.trim();
                final hargaText = _hargaController.text.trim();

                if (nama.isEmpty || kategori.isEmpty || stokText.isEmpty || hargaText.isEmpty || _jenisObat == null) {
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
                      const SnackBar(content: Text("Stok dan Harga harus angka")),
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

                  await FirebaseFirestore.instance.collection('obat').add(newObat.toMap());

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Obat $nama berhasil ditambahkan")),
                    );
                    Navigator.of(context).pop();
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Gagal menyimpan ke database")),
                    );
                  }
                }
              },
              child: const Text("Simpan", style: TextStyle(color: Colors.white)),
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
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: ['Tablet', 'Sirup', 'Obat Oles', 'Obat Tetes', 'Kapsul', 'Supositoria']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
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
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Batal")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA2070)),
              onPressed: () async {
                final nama = _namaController.text.trim();
                final kategori = _kategoriController.text.trim();
                final stokText = _stokController.text.trim();
                final hargaText = _hargaController.text.trim();

                if (nama.isEmpty || kategori.isEmpty || stokText.isEmpty || hargaText.isEmpty || _jenisObat == null) {
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
                      const SnackBar(content: Text("Stok dan Harga harus angka")),
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
              child: const Text("Simpan", style: TextStyle(color: Colors.white)),
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
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Batal")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA2070)),
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance.collection('obat').doc(docId).delete();
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
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Batal")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA2070)),
              onPressed: () async {
                await firebase.FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                }
              },
              child: const Text("Keluar", style: TextStyle(color: Colors.white)),
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
        const Text('Daftar Obat', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              final docs = snapshot.data!.docs;
              final obatList = docs
                  .map((doc) => Obat.fromMap(doc.id, doc.data() as Map<String, dynamic>))
                  .where((o) => o.namaObat.toLowerCase().contains(_searchQuery))
                  .toList();

              final totalPages = (obatList.length / _itemsPerPage).ceil();
              final startIndex = (_currentPage - 1) * _itemsPerPage;
              final endIndex = (startIndex + _itemsPerPage).clamp(0, obatList.length);
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
                              color: _hoveredRow == index ? Colors.grey.shade100 : Colors.transparent,
                              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                            ),
                            child: Row(
                              children: [
                                Expanded(flex: 1, child: _buildDataCell("$index")),
                                Expanded(flex: 3, child: _buildDataCell(obat.namaObat)),
                                Expanded(flex: 2, child: _buildDataCell(obat.kategoriObat)),
                                Expanded(flex: 2, child: _buildDataCell(obat.stokObat.toString())),
                                Expanded(flex: 2, child: _buildDataCell(obat.jenisObat)),
                                Expanded(flex: 2, child: _buildDataCell("${obat.harga}")),
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    alignment: Alignment.center,
                                    height: 48,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, size: 18, color: Color(0xFFEA2070)),
                                          onPressed: () => _editObat(obat),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, size: 18, color: Color(0xFFEA2070)),
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
                              onPressed: _currentPage == 1 ? null : () => setState(() => _currentPage--),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: _currentPage == totalPages ? null : () => setState(() => _currentPage++),
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
        const Text('Resep Obat dari Dokter', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        const Text("Daftar resep yang dikirim oleh dokter."),
        const SizedBox(height: 24),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('resep_obat')
                .orderBy('tanggal', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return const Text("Gagal memuat resep");
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              final docs = snapshot.data!.docs;
              if (docs.isEmpty) return const Center(child: Text("Belum ada resep dari dokter."));

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final resepId = docs[index].id;
                  final namaPasien = data['namaPasien'] as String;
                  final rm = data['nomorRekamMedis'] as String;
                  final diagnosis = data['diagnosis'] as String;
                  final resep = data['resep'] as String;
                  final dokter = data['dokter'] as String;
                  final tanggal = (data['tanggal'] as Timestamp).toDate();
                  final status = data['status'] as String;

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
                              Text("RM: $rm", style: const TextStyle(fontWeight: FontWeight.bold)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                                    color: status == 'Baru' ? Colors.orange : status == 'Diproses' ? Colors.blue : Colors.green,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text("Pasien: $namaPasien"),
                          Text("Dokter: $dokter"),
                          Text("Tanggal: ${DateFormat('dd/MM/yyyy HH:mm').format(tanggal)}"),
                          const SizedBox(height: 8),
                          const Text("Diagnosis:", style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(diagnosis),
                          const SizedBox(height: 8),
                          const Text("Resep Obat:", style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(resep),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              if (status == 'Baru')
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                                  onPressed: () async {
                                    await FirebaseFirestore.instance
                                        .collection('resep_obat')
                                        .doc(resepId)
                                        .update({'status': 'Diproses'});
                                  },
                                  child: const Text("Proses", style: TextStyle(color: Colors.white)),
                                ),
                              if (status == 'Diproses')
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                  onPressed: () async {
                                    // Ambil data resep
                                    final docSnapshot = await FirebaseFirestore.instance
                                        .collection('resep_obat')
                                        .doc(resepId)
                                        .get();

                                    if (!docSnapshot.exists) return;

                                    final data = docSnapshot.data() as Map<String, dynamic>;

                                    // Simpan ke riwayat_resep
                                    await FirebaseFirestore.instance.collection('riwayat_resep').add({
                                      ...data,
                                      'selesaiAt': FieldValue.serverTimestamp(),
                                    });

                                    // Hapus dari resep_obat
                                    await FirebaseFirestore.instance
                                        .collection('resep_obat')
                                        .doc(resepId)
                                        .delete();

                                    // Feedback
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Resep berhasil diproses dan dipindahkan ke Riwayat")),
                                    );
                                  },
                                  child: const Text("Selesai", style: TextStyle(color: Colors.white)),
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

  // ✅ Riwayat Resep Obat
  Widget _buildRiwayat() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Riwayat Resep Obat',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Text("Daftar resep yang telah selesai diproses."),
        const SizedBox(height: 24),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('riwayat_resep')
                .orderBy('selesaiAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Text("Gagal: ${snapshot.error}");
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              final docs = snapshot.data!.docs;
              if (docs.isEmpty) return const Center(child: Text("Belum ada riwayat."));

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final namaPasien = data['namaPasien'] as String;
                  final rm = data['nomorRekamMedis'] as String;
                  final diagnosis = data['diagnosis'] as String;
                  final resep = data['resep'] as String;
                  final dokter = data['dokter'] as String;
                  final selesaiAt = (data['selesaiAt'] as Timestamp).toDate();

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
                              Text("RM: $rm", style: const TextStyle(fontWeight: FontWeight.bold)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  "SELESAI",
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
                          Text("Selesai: ${DateFormat('dd/MM/yyyy HH:mm').format(selesaiAt)}"),
                          const SizedBox(height: 8),
                          const Text("Diagnosis:", style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(diagnosis),
                          const SizedBox(height: 8),
                          const Text("Resep Obat:", style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(resep),
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

  // Placeholder Views
  Widget _buildLaporanObat() => const Center(child: Text("Fitur Laporan Obat sedang dikembangkan."));

  // ✅ Pembayaran (Integrasi Resep + Stok + Harga)
  Widget _buildPembayaran() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pembayaran Obat', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        const Text("Daftar pasien yang siap membayar berdasarkan resep."),
        const SizedBox(height: 24),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('riwayat_resep')
                .orderBy('selesaiAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Text("Gagal: ${snapshot.error}");
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              final docs = snapshot.data!.docs;
              if (docs.isEmpty) return const Center(child: Text("Belum ada resep selesai."));

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final namaPasien = data['namaPasien'] as String;
                  final rm = data['nomorRekamMedis'] as String;
                  final dokter = data['dokter'] as String;
                  final resepText = data['resep'] as String;
                  final selesaiAt = (data['selesaiAt'] as Timestamp).toDate();

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
                        final obat = Obat.fromMap(doc.id, doc.data() as Map<String, dynamic>);
                        obatMap[obat.namaObat.toLowerCase()] = obat;
                      }

                      // Parse resep: "amoxcilin x2, paracetamol x1"
                      final items = resepText.split(',').map((item) => item.trim()).toList();
                      for (final item in items) {
                        RegExp reg = RegExp(r'(.+?)\s*x(\d+)', caseSensitive: false);
                        Match? match = reg.firstMatch(item);

                        String namaObat = match?.group(1)?.trim() ?? item;
                        int jumlah = int.tryParse(match?.group(2) ?? '1') ?? 1;

                        final obat = obatMap[namaObat.toLowerCase()];
                        if (obat != null) {
                          int subTotal = obat.harga * jumlah;
                          totalHarga += subTotal;
                          daftarObat.add({
                            'nama': obat.namaObat,
                            'jumlah': jumlah,
                            'harga': obat.harga,
                            'subtotal': subTotal,
                          });
                        }
                      }

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
                                  Text("RM: $rm", style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      "SELESAI",
                                      style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              Text("Pasien: $namaPasien"),
                              Text("Dokter: $dokter"),
                              Text("Selesai: ${DateFormat('dd/MM/yyyy HH:mm').format(selesaiAt)}"),
                              const SizedBox(height: 8),
                              const Text("Rincian Obat:", style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              ...daftarObat.map((obat) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                    child: Row(
                                      children: [
                                        Expanded(flex: 3, child: Text("${obat['nama']} x${obat['jumlah']}")),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            "Rp ${(obat['subtotal'] as int).toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.')}",
                                            textAlign: TextAlign.right,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                              const Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("Total:", style: TextStyle(fontWeight: FontWeight.bold)),
                                  Text(
                                    "Rp ${totalHarga.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.')}",
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  // Kurangi stok
                                  for (final item in daftarObat) {
                                    final namaObat = item['nama'] as String;
                                    final jumlah = item['jumlah'] as int;

                                    final obatDoc = await FirebaseFirestore.instance
                                        .collection('obat')
                                        .where('namaObat', isEqualTo: namaObat)
                                        .get();

                                    if (obatDoc.docs.isNotEmpty) {
                                      final doc = obatDoc.docs.first;
                                      final stokSaatIni = doc.get('stokObat') as int;
                                      final stokBaru = stokSaatIni - jumlah;

                                      if (stokBaru >= 0) {
                                        await FirebaseFirestore.instance
                                            .collection('obat')
                                            .doc(doc.id)
                                            .update({'stokObat': stokBaru});
                                      }
                                    }
                                  }

                                  // Simpan ke pembayaran (opsional)
                                  await FirebaseFirestore.instance.collection('pembayaran').add({
                                    'pasienId': data['pasienId'],
                                    'nomorRekamMedis': rm,
                                    'namaPasien': namaPasien,
                                    'totalHarga': totalHarga,
                                    'resep': resepText,
                                    'dibayarAt': FieldValue.serverTimestamp(),
                                  });

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Pembayaran untuk $namaPasien berhasil")),
                                  );
                                },
                                icon: const Icon(Icons.payment, size: 18),
                                label: const Text("Bayar Sekarang"),
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA2070)),
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
      decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.grey.shade300, width: 1))),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
    );
  }

  Widget _buildDataCell(String text) {
    return Container(
      alignment: Alignment.center,
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.grey.shade300, width: 1))),
      child: Text(text, textAlign: TextAlign.center),
    );
  }

  // Sidebar Item
  Widget _buildSidebarItem(IconData icon, String title, Color color, {VoidCallback? onTap}) {
    final isSelected = _currentView == title;

    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.white : color, size: 20),
      title: _isSidebarCollapsed ? null : Text(
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
              icon: Icon(_isSidebarCollapsed ? Icons.menu_open : Icons.menu, color: Colors.white),
              onPressed: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
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
                              Text('Apotek dan Klinik Pratama', style: const TextStyle(color: Colors.white, fontSize: 10)),
                              Text('Sakura Medical Center', style: const TextStyle(color: Colors.white, fontSize: 10)),
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
                      _buildSidebarItem(Icons.file_copy, 'Data Obat', menuColor),
                      _buildSidebarItem(Icons.medical_services, 'Resep Obat', menuColor),
                      _buildSidebarItem(Icons.history, 'Riwayat', menuColor),
                      _buildSidebarItem(Icons.bar_chart, 'Laporan Obat', menuColor),
                      _buildSidebarItem(Icons.payment, 'Pembayaran', menuColor),
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