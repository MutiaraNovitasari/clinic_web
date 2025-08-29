// lib/views/menu_admin_page.dart
// ignore_for_file: use_build_context_synchronously
import 'dart:typed_uint';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;
import '../models/user_model.dart';
import '../models/admin_model.dart';
import 'login_page.dart';

class MenuAdminPage extends StatefulWidget {
  const MenuAdminPage({super.key});

  @override
  State<MenuAdminPage> createState() => _MenuAdminPageState();
}

class _MenuAdminPageState extends State<MenuAdminPage> {
  late Admin admin;
  bool _isSidebarCollapsed = false;
  String? _hoveredItem;
  int? _hoveredRow;

  List<User> users = [];
  late Stream<QuerySnapshot> usersStream;

  final TextEditingController searchController = TextEditingController();

  // Form Controllers
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _teleponController = TextEditingController();

  String? _selectedJabatan;
  final List<String> _jabatanOptions = ['Dokter', 'Resepsionis', 'Apoteker'];

  // Upload Image
  Uint8List? selectedImageBytes;
  String selectedImageUrl = 'assets/images/user_placeholder.png';

  // Pagination
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  // Sort
  bool _sortAscending = true;
  String? _sortBy;

  @override
  void initState() {
    super.initState();
    admin = Admin(
      id: '',
      nama: 'Loading...',
      username: '',
      password: '',
      telepon: '',
      fotoUrl: 'assets/images/user_placeholder.png',
      fotoBytes: null,
    );
    _loadAdminData();
    _setupUserStream();
  }

  @override
  void dispose() {
    searchController.dispose();
    _namaController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _teleponController.dispose();
    super.dispose();
  }

  // ✅ Load Data Admin
  Future<void> _loadAdminData() async {
    final user = firebase.FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
      }
      return;
    }

    final doc = await FirebaseFirestore.instance.collection('admins').doc(user.uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      if (mounted) {
        setState(() {
          admin = Admin(
            id: doc.id,
            nama: data['nama'],
            username: data['username'],
            password: data['password'],
            telepon: data['telepon'],
            fotoUrl: data['fotoUrl'] ?? 'assets/images/user_placeholder.png',
            fotoBytes: null,
          );
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Data admin tidak ditemukan")),
        );
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
      }
    }
  }

  // ✅ Setup Stream User
  void _setupUserStream() {
    usersStream = FirebaseFirestore.instance.collection('users').snapshots();
    usersStream.listen((snapshot) {
      if (mounted) {
        setState(() {
          users = snapshot.docs.map((doc) => User.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList();
        });
      }
    });
  }

  // ✅ Validasi Password
  bool isValidPassword(String password) {
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasDigits = password.contains(RegExp(r'[0-9]'));
    final hasMinLength = password.length >= 8;
    return hasUppercase && hasLowercase && hasDigits && hasMinLength;
  }

  // ✅ Cek Duplikat User
  bool isDuplicateUser(String username, String email, [User? excludeUser]) {
    return users.any((user) {
      if (excludeUser != null && user.docId == excludeUser.docId) return false;
      return user.username == username || user.email == email;
    });
  }

  // ✅ Tambah/Edit User
  void _showUserForm({User? user}) {
    final contextLocal = context;
    final isEdit = user != null;

    if (isEdit) {
      _namaController.text = user.namaLengkap;
      _usernameController.text = user.username;
      _emailController.text = user.email;
      _teleponController.text = user.telepon;
      _selectedJabatan = user.status;
      _passwordController.text = user.password;
      selectedImageUrl = user.fotoUrl ?? 'assets/images/user_placeholder.png';
      selectedImageBytes = user.fotoBytes;
    } else {
      _namaController.clear();
      _usernameController.clear();
      _emailController.clear();
      _teleponController.clear();
      _passwordController.clear();
      _selectedJabatan = null;
      selectedImageUrl = 'assets/images/user_placeholder.png';
      selectedImageBytes = null;
    }

    showDialog(
      context: contextLocal,
      builder: (context) {
        return AlertDialog(
          title: Text(isEdit ? "Edit User" : "Tambah User Baru"),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Foto Profil
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey, width: 2),
                            ),
                            child: ClipOval(
                              child: selectedImageBytes != null
                                  ? Image.memory(selectedImageBytes!, fit: BoxFit.cover)
                                  : Image.asset(selectedImageUrl, fit: BoxFit.cover),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () async {
                                final result = await FilePicker.platform.pickFiles(type: FileType.image);
                                if (result != null) {
                                  final bytes = result.files.first.bytes;
                                  if (bytes != null && bytes.lengthInBytes > 2 * 1024 * 1024) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("File terlalu besar (max 2MB)")),
                                    );
                                    return;
                                  }
                                  setState(() {
                                    selectedImageBytes = bytes;
                                    selectedImageUrl = '';
                                  });
                                }
                              },
                              child: Container(
                                width: 35,
                                height: 35,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEA2070),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.edit, size: 18, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _namaController,
                      decoration: const InputDecoration(labelText: 'Nama Lengkap', border: OutlineInputBorder()),
                      autofocus: true,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _usernameController,
                      decoration: const InputDecoration(labelText: 'Username', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _teleponController,
                      decoration: const InputDecoration(labelText: 'Telepon', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedJabatan,
                      hint: const Text("Pilih Jabatan"),
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: _jabatanOptions.map((e) {
                        return DropdownMenuItem(value: e, child: Text(e));
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedJabatan = value),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA2070)),
              onPressed: () async {
                final nama = _namaController.text.trim();
                final username = _usernameController.text.trim();
                final password = _passwordController.text.trim();
                final email = _emailController.text.trim();
                final telepon = _teleponController.text.trim();

                if (nama.isEmpty || username.isEmpty || password.isEmpty || email.isEmpty || telepon.isEmpty || _selectedJabatan == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Semua field wajib diisi")),
                  );
                  return;
                }

                if (!isValidPassword(password)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Password harus 8+ karakter, huruf besar, kecil, dan angka")),
                  );
                  return;
                }

                if (isDuplicateUser(username, email, isEdit ? user : null)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Username atau email sudah digunakan")),
                  );
                  return;
                }

                try {
                  final userData = {
                    'namaLengkap': nama,
                    'status': _selectedJabatan,
                    'username': username,
                    'password': password,
                    'email': email,
                    'telepon': telepon,
                    'fotoUrl': selectedImageUrl,
                    'createdAt': FieldValue.serverTimestamp(),
                  };

                  if (selectedImageBytes != null) {
                    userData['fotoBytes'] = selectedImageBytes;
                  }

                  if (isEdit && user != null) {
                    await FirebaseFirestore.instance.collection('users').doc(user.docId).update(userData);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("User $nama berhasil diupdate")),
                    );
                  } else {
                    await FirebaseFirestore.instance.collection('users').add(userData);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("User $nama berhasil ditambahkan")),
                    );
                  }
                  Navigator.of(context).pop();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Gagal menyimpan data")),
                  );
                }
              },
              child: const Text("Simpan", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // ✅ Edit User
  void _editUser(User user) {
    _showUserForm(user: user);
  }

  // ✅ Hapus User
  void _deleteUser(String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Hapus"),
        content: const Text("Yakin ingin menghapus user ini?"),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA2070)),
            onPressed: () async {
              try {
                await FirebaseFirestore.instance.collection('users').doc(docId).delete();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User dihapus")));
                Navigator.of(context).pop();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal menghapus")));
              }
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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

  // ✅ Render Sidebar
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

  @override
  Widget build(BuildContext context) {
    if (admin.nama == 'Loading...') {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    const menuColor = Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            IconButton(
              icon: Icon(_isSidebarCollapsed ? Icons.menu_open : Icons.menu, color: Colors.white),
              onPressed: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
            ),
            const SizedBox(width: 8),
            Text('Halo, ${admin.nama}', style: const TextStyle(color: Colors.white)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: const Color(0xFFEA2070),
              child: admin.fotoBytes != null
                  ? ClipOval(child: Image.memory(admin.fotoBytes!, width: 40, height: 40, fit: BoxFit.cover))
                  : Image.asset(admin.fotoUrl, width: 40, height: 40, fit: BoxFit.cover),
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
                      _buildSidebarItem(Icons.person_add, 'Tambah User', menuColor, onTap: () => _showUserForm()),
                      _buildSidebarItem(Icons.people, 'Daftar User', menuColor, onTap: () {}),
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
                  const Text('Manajemen User', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _showUserForm(),
                        icon: const Icon(Icons.person_add),
                        label: const Text("Tambah User"),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 300,
                        child: TextField(
                          controller: searchController,
                          decoration: InputDecoration(
                            hintText: 'Cari user...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onChanged: (value) {
                            setState(() {});
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: usersStream,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) return const Text("Gagal muat data");
                        if (!snapshot.hasData) return const CircularProgressIndicator();

                        final docs = snapshot.data!.docs;
                        final allUsers = docs
                            .map((doc) => User.fromMap(doc.id, doc.data() as Map<String, dynamic>))
                            .toList();

                        final filtered = searchController.text.isEmpty
                            ? allUsers
                            : allUsers
                                .where((u) =>
                                    u.namaLengkap.toLowerCase().contains(searchController.text.toLowerCase()) ||
                                    u.username.toLowerCase().contains(searchController.text.toLowerCase()))
                                .toList();

                        final totalPages = (filtered.length / _itemsPerPage).ceil();
                        final startIndex = (_currentPage - 1) * _itemsPerPage;
                        final endIndex = startIndex + _itemsPerPage;
                        final currentUsers = filtered.sublist(startIndex, endIndex.clamp(0, filtered.length));

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
                                  Expanded(flex: 2, child: _buildHeaderCell('Username')),
                                  Expanded(flex: 2, child: _buildHeaderCell('Jabatan')),
                                  Expanded(flex: 2, child: _buildHeaderCell('Email')),
                                  Expanded(flex: 2, child: _buildHeaderCell('Telepon')),
                                  Expanded(flex: 2, child: _buildHeaderCell('Aksi')),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: ListView(
                                children: currentUsers.asMap().entries.map((entry) {
                                  final index = entry.key + 1;
                                  final user = entry.value;
                                  return MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    onEnter: (_) => setState(() => _hoveredRow = index),
                                    onExit: (_) => setState(() => _hoveredRow = null),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(flex: 1, child: _buildDataCell("$index")),
                                          Expanded(flex: 3, child: _buildDataCell(user.namaLengkap)),
                                          Expanded(flex: 2, child: _buildDataCell(user.username)),
                                          Expanded(flex: 2, child: _buildDataCell(user.status)),
                                          Expanded(flex: 2, child: _buildDataCell(user.email)),
                                          Expanded(flex: 2, child: _buildDataCell(user.telepon)),
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
                                                    onPressed: () => _editUser(user),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.delete, size: 18, color: Color(0xFFEA2070)),
                                                    onPressed: () => _deleteUser(user.docId),
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
}