// lib/views/menu_apoteker_page.dart
// ignore_for_file: use_build_context_synchronously
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/material.dart';
import '../models/obat_model.dart';
import 'login_page.dart';

class MenuApotekerPage extends StatefulWidget {
  const MenuApotekerPage({super.key});

  @override
  State<MenuApotekerPage> createState() => _MenuApotekerPageState();
}

class _MenuApotekerPageState extends State<MenuApotekerPage> {
  // ✅ Form Controllers
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _kategoriController = TextEditingController();
  final TextEditingController _stokController = TextEditingController();
  final TextEditingController _hargaController = TextEditingController();

  // ✅ Dropdown
  String? _jenisObat;

  // ✅ Search
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // ✅ Pagination
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  // ✅ Sidebar
  bool _isSidebarCollapsed = false;
  String? _hoveredItem;
  int? _hoveredRow;

  final Color menuColor = Colors.white;

  @override
  void dispose() {
    _namaController.dispose();
    _kategoriController.dispose();
    _stokController.dispose();
    _hargaController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ✅ Tampilkan Form Tambah Obat
  void _showAddObatForm() {
    final contextLocal = context;

    // Reset form
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
                // Nama Obat
                TextField(
                  controller: _namaController,
                  decoration: const InputDecoration(
                    labelText: "Nama Obat",
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 12),

                // Kategori Obat
                TextField(
                  controller: _kategoriController,
                  decoration: const InputDecoration(
                    labelText: "Kategori Obat",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                // Stok Obat
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

                // Jenis Obat (Dropdown)
                DropdownButtonFormField<String>(
                  value: _jenisObat,
                  hint: const Text("Pilih Jenis Obat"),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    'Tablet',
                    'Sirup',
                    'Obat Oles',
                    'Obat Tetes',
                    'Kapsul',
                    'Supositoria'
                  ].map((e) {
                    return DropdownMenuItem(value: e, child: Text(e));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _jenisObat = value;
                    });
                  },
                ),
                const SizedBox(height: 12),

                // Harga Obat
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
                final contextLocal = context;
                final nama = _namaController.text.trim();
                final kategori = _kategoriController.text.trim();
                final stokText = _stokController.text.trim();
                final hargaText = _hargaController.text.trim();

                if (nama.isEmpty ||
                    kategori.isEmpty ||
                    stokText.isEmpty ||
                    hargaText.isEmpty ||
                    _jenisObat == null) {
                  if (contextLocal.mounted) {
                    ScaffoldMessenger.of(contextLocal).showSnackBar(
                      const SnackBar(content: Text("Semua field wajib diisi")),
                    );
                  }
                  return;
                }

                final stok = int.tryParse(stokText);
                final harga = int.tryParse(hargaText);

                if (stok == null || harga == null) {
                  if (contextLocal.mounted) {
                    ScaffoldMessenger.of(contextLocal).showSnackBar(
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

                  // ✅ Simpan ke Firestore
                  await FirebaseFirestore.instance.collection('obat').add(newObat.toMap());

                  if (contextLocal.mounted) {
                    ScaffoldMessenger.of(contextLocal).showSnackBar(
                      SnackBar(content: Text("Obat $nama berhasil ditambahkan")),
                    );
                    Navigator.of(contextLocal).pop();
                  }
                } catch (e) {
                  if (contextLocal.mounted) {
                    ScaffoldMessenger.of(contextLocal).showSnackBar(
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

  // ✅ Edit Obat
  void _editObat(Obat obat) {
    final contextLocal = context;

    // Isi form dengan data obat
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
                  items: [
                    'Tablet',
                    'Sirup',
                    'Obat Oles',
                    'Obat Tetes',
                    'Kapsul',
                    'Supositoria'
                  ].map((e) {
                    return DropdownMenuItem(value: e, child: Text(e));
                  }).toList(),
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
                final contextLocal = context;
                final nama = _namaController.text.trim();
                final kategori = _kategoriController.text.trim();
                final stokText = _stokController.text.trim();
                final hargaText = _hargaController.text.trim();

                if (nama.isEmpty ||
                    kategori.isEmpty ||
                    stokText.isEmpty ||
                    hargaText.isEmpty ||
                    _jenisObat == null) {
                  if (contextLocal.mounted) {
                    ScaffoldMessenger.of(contextLocal).showSnackBar(
                      const SnackBar(content: Text("Semua field wajib diisi")),
                    );
                  }
                  return;
                }

                final stok = int.tryParse(stokText);
                final harga = int.tryParse(hargaText);

                if (stok == null || harga == null) {
                  if (contextLocal.mounted) {
                    ScaffoldMessenger.of(contextLocal).showSnackBar(
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

                  // ✅ Update ke Firestore
                  await FirebaseFirestore.instance
                      .collection('obat')
                      .doc(obat.id)
                      .update(updatedObat.toMap());

                  if (contextLocal.mounted) {
                    ScaffoldMessenger.of(contextLocal).showSnackBar(
                      SnackBar(content: Text("Obat $nama berhasil diperbarui")),
                    );
                    Navigator.of(contextLocal).pop();
                  }
                } catch (e) {
                  if (contextLocal.mounted) {
                    ScaffoldMessenger.of(contextLocal).showSnackBar(
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

  // ✅ Hapus Obat
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
                  await FirebaseFirestore.instance.collection('obat').doc(docId).delete();
                  if (contextLocal.mounted) {
                    ScaffoldMessenger.of(contextLocal).showSnackBar(
                      const SnackBar(content: Text("Obat berhasil dihapus")),
                    );
                    Navigator.of(contextLocal).pop();
                  }
                } catch (e) {
                  if (contextLocal.mounted) {
                    ScaffoldMessenger.of(contextLocal).showSnackBar(
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

  // ✅ Logout
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
                final contextLocal = context;
                await firebase.FirebaseAuth.instance.signOut();
                if (contextLocal.mounted) {
                  Navigator.pushReplacement(
                    contextLocal,
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
              onPressed: () {
                setState(() {
                  _isSidebarCollapsed = !_isSidebarCollapsed;
                });
              },
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
                              Text(
                                'Apotek dan Klinik Pratama',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(1, 1),
                                      blurRadius: 2,
                                      color: Color.fromARGB(158, 232, 68, 147),
                                    ),
                                  ],
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              Text(
                                'Sakura Medical Center',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(1, 1),
                                      blurRadius: 2,
                                      color: Color.fromARGB(158, 232, 68, 147),
                                    ),
                                  ],
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
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
                      _buildSidebarItem(Icons.file_copy, 'Data Obat', menuColor, onTap: () {}),
                      _buildSidebarItem(Icons.medical_services, 'Resep Obat', menuColor, onTap: () {}),
                      _buildSidebarItem(Icons.assignment, 'Pemberian Obat', menuColor, onTap: () {}),
                      _buildSidebarItem(Icons.bar_chart, 'Laporan Obat', menuColor, onTap: () {}),
                      _buildSidebarItem(Icons.payment, 'Pembayaran', menuColor, onTap: () {}),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daftar Obat',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Color(0xFFEA2070),
                          side: BorderSide(color: Color(0xFFEA2070)),
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
                          'Tambah Obat',
                          style: TextStyle(fontSize: 14),
                        ),
                        onPressed: _showAddObatForm,
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 250,
                        height: 33,
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Cari Obat...',
                            prefixIcon: const Icon(Icons.search, size: 18),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Colors.grey.shade400,
                              ),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(8),
                              ),
                              borderSide: BorderSide(
                                color: Color(0xFFEA2070),
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            isDense: true,
                          ),
                          style: const TextStyle(fontSize: 14),
                          onChanged: (query) {
                            if (mounted) {
                              setState(() {
                                _searchQuery = query;
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
                        if (snapshot.hasError) {
                          return const Center(child: Text("Gagal memuat data"));
                        }
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final docs = snapshot.data!.docs;
                        final obatList = docs
                            .map((doc) => Obat.fromMap(doc.id, doc.data() as Map<String, dynamic>))
                            .toList();

                        final filtered = _searchQuery.isEmpty
                            ? obatList
                            : obatList.where((o) => o.namaObat.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

                        final totalPages = (filtered.length / _itemsPerPage).ceil();
                        final startIndex = (_currentPage - 1) * _itemsPerPage;
                        final endIndex = (startIndex + _itemsPerPage).clamp(0, filtered.length);
                        final currentObat = filtered.sublist(startIndex, endIndex);

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
                                  Expanded(flex: 3, child: _buildHeaderCell('Nama Obat')),
                                  Expanded(flex: 2, child: _buildHeaderCell('Kategori Obat')),
                                  Expanded(flex: 2, child: _buildHeaderCell('Stok Obat')),
                                  Expanded(flex: 2, child: _buildHeaderCell('Jenis Obat')),
                                  Expanded(flex: 2, child: _buildHeaderCell('Harga')),
                                  Expanded(flex: 2, child: _buildHeaderCell('Aksi')),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: ListView(
                                children: currentObat.asMap().entries.map((entry) {
                                  final index = entry.key + 1;
                                  final obat = entry.value;
                                  return MouseRegion(
                                    cursor: SystemMouseCursors.click,
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
              ),
            ),
          ),
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
        border: Border(right: BorderSide(color: Colors.grey.shade300, width: 1)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
    );
  }

  Widget _buildDataCell(String text) {
    return Container(
      alignment: Alignment.center,
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Colors.grey.shade300, width: 1)),
      ),
      child: Text(text, textAlign: TextAlign.center),
    );
  }

  Widget _buildSidebarItem(IconData icon, String title, Color color, {VoidCallback? onTap}) {
    return StatefulBuilder(
      builder: (context, setState) {
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hoveredItem = title),
          onExit: (_) => setState(() => _hoveredItem = null),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _hoveredItem == title ? Colors.white12 : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
              splashColor: Colors.white30,
              highlightColor: Colors.white10,
              child: ListTile(
                leading: Icon(icon, color: color, size: 20),
                title: _isSidebarCollapsed ? null : Text(title, style: TextStyle(color: color, fontSize: 14)),
                dense: true,
                horizontalTitleGap: 12,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
            ),
          ),
        );
      },
    );
  }
}