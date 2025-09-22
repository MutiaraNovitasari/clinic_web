// lib/views/menu_admin_page.dart
// ignore_for_file: use_build_context_synchronously
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
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

class _WebFilePicker extends StatelessWidget {
  final void Function(Uint8List bytes, String filename) onFileSelected;

  const _WebFilePicker({required this.onFileSelected});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final input = html.FileUploadInputElement()
          ..accept = 'image/*'
          ..click();

        input.onChange.listen((event) {
          final file = input.files!.first;
          final reader = html.FileReader();
          reader.readAsArrayBuffer(file);

          reader.onLoadEnd.listen((e) {
            final bytes = reader.result as Uint8List;
            onFileSelected(bytes, file.name);
          });
        });
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
    );
  }
}

class _MenuAdminPageState extends State<MenuAdminPage> {
  late Admin admin;

  bool _isSidebarCollapsed = false;
  String? _hoveredItem;
  int? _hoveredRow;

  List<User> users = [];
  late Stream<QuerySnapshot> usersStream;

  final TextEditingController searchController = TextEditingController();

  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _teleponController = TextEditingController();

  String? _selectedJabatan;
  final List<String> _jabatanOptions = ['Dokter', 'Resepsionis', 'Apoteker'];

  // ✅ Pagination
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  // ✅ Sort
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
    );
    _loadAdminData();
    _setupUserStream();
  }

  // ✅ Load data admin dari Firestore
  Future<void> _loadAdminData() async {
    firebase.User? user = firebase.FirebaseAuth.instance.currentUser;
    if (user == null) {
      final contextLocal = context;
      if (contextLocal.mounted) {
        Navigator.pushReplacement(
          contextLocal,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection('admins')
        .doc(user.uid)
        .get();

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
      final contextLocal = context;
      if (contextLocal.mounted) {
        ScaffoldMessenger.of(contextLocal).showSnackBar(
          const SnackBar(content: Text("Data admin tidak ditemukan")),
        );
        Navigator.pushReplacement(
          contextLocal,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    }
  }

  // ✅ Setup stream untuk user (realtime)
  void _setupUserStream() {
    usersStream = FirebaseFirestore.instance.collection('users').snapshots();
    usersStream.listen((snapshot) {
      final List<User> newUsers = [];
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        newUsers.add(
          User(
            docId: doc.id, // ✅ Simpan docId
            namaLengkap: data['namaLengkap'],
            status: data['status'],
            username: data['username'],
            password: data['password'],
            email: data['email'],
            telepon: data['telepon'],
          ),
        );
      }
      if (mounted) {
        setState(() {
          users = newUsers;
          _currentPage = 1;
        });
      }
    });
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

  // ✅ Sort by field
  void _sortUsers(String field) {
    if (!mounted) return;
    setState(() {
      if (_sortBy == field) {
        _sortAscending = !_sortAscending;
      } else {
        _sortBy = field;
        _sortAscending = true;
      }

      users.sort((a, b) {
        int comparison = 0;
        switch (field) {
          case 'nama':
            comparison = a.namaLengkap.compareTo(b.namaLengkap);
            break;
          case 'status':
            comparison = a.status.compareTo(b.status);
            break;
          case 'username':
            comparison = a.username.compareTo(b.username);
            break;
          case 'email':
            comparison = a.email.compareTo(b.email);
            break;
          default:
            comparison = 0;
        }
        return _sortAscending ? comparison : -comparison;
      });

      _currentPage = 1;
    });
  }

  // ✅ Hitung total halaman
  int get _totalPages {
    return (users.length / _itemsPerPage).ceil();
  }

  // ✅ Ambil data untuk halaman saat ini
  List<User> get _currentUsers {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(startIndex, users.length);
    return users.sublist(startIndex, endIndex);
  }

  void _addUser() {
    _resetFormControllers();
    _showUserForm(isEdit: false, user: null);
  }

  void _editUser(User user) {
    _namaController.text = user.namaLengkap;
    _usernameController.text = user.username;
    _passwordController.text = user.password;
    _emailController.text = user.email;
    _teleponController.text = user.telepon;
    _selectedJabatan = user.status;
    _showUserForm(isEdit: true, user: user);
  }

  void _resetFormControllers() {
    _namaController.clear();
    _usernameController.clear();
    _passwordController.clear();
    _emailController.clear();
    _teleponController.clear();
    _selectedJabatan = null;
  }

  // ✅ Validasi password kuat
  bool isValidPassword(String password) {
    final passwordRegex = RegExp(
      r'^(?=.[a-z])(?=.[A-Z])(?=.\d)[a-zA-Z\d@$!%?&]{8,}$',
    );
    return passwordRegex.hasMatch(password);
  }

  // ✅ Cek duplikat username atau email
  bool isDuplicateUser(String username, String email, [User? excludeUser]) {
    return users.any((user) {
      if (excludeUser != null && user.docId == excludeUser.docId) return false;
      return user.username == username || user.email == email;
    });
  }

  void _showUserForm({required bool isEdit, User? user}) {
    final contextLocal = context;
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
                    TextField(
                      controller: _namaController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Lengkap',
                        border: OutlineInputBorder(),
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      obscureText: false,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _teleponController,
                      decoration: const InputDecoration(
                        labelText: 'Telepon',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedJabatan,
                      hint: const Text("Pilih Jabatan"),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: _jabatanOptions.map((jabatan) {
                        return DropdownMenuItem(
                          value: jabatan,
                          child: Text(jabatan),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedJabatan = value;
                        });
                      },
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
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEA2070),
              ),
              onPressed: () async {
                final contextLocal = context;
                final nama = _namaController.text.trim();
                final username = _usernameController.text.trim();
                final password = _passwordController.text;
                final email = _emailController.text.trim();
                final telepon = _teleponController.text.trim();

                if (nama.isEmpty ||
                    username.isEmpty ||
                    password.isEmpty ||
                    email.isEmpty ||
                    telepon.isEmpty ||
                    _selectedJabatan == null) {
                  if (contextLocal.mounted) {
                    ScaffoldMessenger.of(contextLocal).showSnackBar(
                      const SnackBar(content: Text("Semua field harus diisi")),
                    );
                  }
                  return;
                }

                if (!isValidPassword(password)) {
                  if (contextLocal.mounted) {
                    ScaffoldMessenger.of(contextLocal).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Password harus: 8+ karakter, huruf besar, huruf kecil, dan angka",
                        ),
                      ),
                    );
                  }
                  return;
                }

                if (isDuplicateUser(username, email, isEdit ? user : null)) {
                  if (contextLocal.mounted) {
                    ScaffoldMessenger.of(contextLocal).showSnackBar(
                      const SnackBar(
                        content: Text("Username atau email sudah digunakan"),
                      ),
                    );
                  }
                  return;
                }

                try {
                  if (isEdit && user != null) {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.docId) // ✅ Gunakan docId
                        .update({
                      'namaLengkap': nama,
                      'status': _selectedJabatan!,
                      'username': username,
                      'password': password,
                      'email': email,
                      'telepon': telepon,
                    });

                    if (contextLocal.mounted) {
                      ScaffoldMessenger.of(contextLocal).showSnackBar(
                        SnackBar(content: Text("User $nama berhasil diupdate")),
                      );
                      Navigator.of(contextLocal).pop();
                    }
                  } else {
                    await FirebaseFirestore.instance.collection('users').add({
                      'namaLengkap': nama,
                      'status': _selectedJabatan!,
                      'username': username,
                      'password': password,
                      'email': email,
                      'telepon': telepon,
                    });

                    if (contextLocal.mounted) {
                      ScaffoldMessenger.of(contextLocal).showSnackBar(
                        SnackBar(
                          content: Text("User $nama berhasil ditambahkan"),
                        ),
                      );
                      Navigator.of(contextLocal).pop();
                    }
                  }
                } catch (e) {
                  if (contextLocal.mounted) {
                    ScaffoldMessenger.of(contextLocal).showSnackBar(
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

  void _deleteUser(String docId) { // ✅ Ubah dari int ke String
    final contextLocal = context;
    showDialog(
      context: contextLocal,
      builder: (context) {
        return AlertDialog(
          title: const Text("Konfirmasi Hapus"),
          content: const Text("Yakin ingin menghapus user ini?"),
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
                try {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(docId) // ✅ Gunakan docId
                      .delete();

                  if (contextLocal.mounted) {
                    ScaffoldMessenger.of(contextLocal).showSnackBar(
                      const SnackBar(content: Text("User berhasil dihapus")),
                    );
                    Navigator.of(contextLocal).pop();
                  }
                } catch (e) {
                  if (contextLocal.mounted) {
                    ScaffoldMessenger.of(contextLocal).showSnackBar(
                      const SnackBar(content: Text("Gagal menghapus user")),
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

  void _showEditProfilDialog(BuildContext context) async {
    final contextLocal = context;
    final TextEditingController usernameController = TextEditingController(
      text: admin.username,
    );
    final TextEditingController passwordController = TextEditingController(
      text: admin.password,
    );
    final TextEditingController teleponController = TextEditingController(
      text: admin.telepon,
    );
    bool isPasswordVisible = false;

    Uint8List? selectedImageBytes = admin.fotoBytes;
    String? selectedImageUrl = admin.fotoUrl;

    Future<void> pickImageFromMobile() async {
      if (kIsWeb || !context.mounted) return;

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        if (result.files.single.size <= 2 * 1024 * 1024) {
          final Uint8List fileBytes = result.files.single.bytes!;
          if (context.mounted) {
            setState(() {
              selectedImageBytes = fileBytes;
              selectedImageUrl = null;
            });
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("File terlalu besar (max 2MB)")),
            );
          }
        }
      }
    }

    void resetToDefault() {
      if (context.mounted) {
        setState(() {
          selectedImageUrl = 'assets/images/user_placeholder.png';
          selectedImageBytes = null;
        });
      }
    }

    Widget buildImageWidget() {
      if (selectedImageBytes != null && selectedImageBytes!.isNotEmpty) {
        return Image.memory(
          selectedImageBytes!,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
        );
      } else {
        return Image.asset(
          selectedImageUrl ?? 'assets/images/user_placeholder.png',
          width: 120,
          height: 120,
          fit: BoxFit.cover,
        );
      }
    }

    showDialog(
      context: contextLocal,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Profil Admin"),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          ClipOval(child: buildImageWidget()),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: kIsWeb
                                ? _WebFilePicker(
                                    onFileSelected: (bytes, filename) {
                                      if (context.mounted) {
                                        setState(() {
                                          selectedImageBytes = bytes;
                                          selectedImageUrl = null;
                                        });
                                      }
                                    },
                                  )
                                : Container(
                                    width: 35,
                                    height: 35,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFEA2070),
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(
                                        Icons.edit,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                      onPressed: pickImageFromMobile,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passwordController,
                      obscureText: !isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              isPasswordVisible = !isPasswordVisible;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: teleponController,
                      decoration: const InputDecoration(
                        labelText: 'Nomor Telepon',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: resetToDefault,
                      child: const Text("Gunakan Foto Default"),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEA2070),
              ),
              onPressed: () async {
                final contextLocal = context;
                if (!contextLocal.mounted) return;

                try {
                  await FirebaseFirestore.instance
                      .collection('admins')
                      .doc(admin.id)
                      .update({
                    'username': usernameController.text,
                    'password': passwordController.text,
                    'telepon': teleponController.text,
                  });

                  final updatedAdmin = admin.copyWith(
                    username: usernameController.text,
                    password: passwordController.text,
                    telepon: teleponController.text,
                    fotoUrl: selectedImageUrl,
                    fotoBytes: selectedImageBytes,
                  );

                  setState(() {
                    admin = updatedAdmin;
                  });

                  ScaffoldMessenger.of(contextLocal).showSnackBar(
                    const SnackBar(content: Text("Profil berhasil diperbarui")),
                  );

                  Navigator.of(contextLocal).pop();
                } catch (e) {
                  if (contextLocal.mounted) {
                    ScaffoldMessenger.of(contextLocal).showSnackBar(
                      const SnackBar(content: Text("Gagal update profil")),
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

  @override
  Widget build(BuildContext context) {
    if (admin.nama == 'Loading...') {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    const menuColor = Colors.white;

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
        backgroundColor: const Color.fromRGBO(255, 142, 187, 1),
        actions: [
          GestureDetector(
            onTap: () {
              _showEditProfilDialog(context);
            },
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: admin.fotoBytes != null
                      ? MemoryImage(admin.fotoBytes!)
                      : AssetImage(
                              admin.fotoUrl ??
                                  'assets/images/user_placeholder.png',
                            )
                            as ImageProvider,
                ),
                const SizedBox(width: 8),
                Text(
                  admin.nama,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
        ],
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
                                'Klinik Pratama',
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
                      _buildSidebarItem(
                        Icons.group,
                        'Daftar User',
                        menuColor,
                        onTap: () {},
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

          // KONTEN UTAMA
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daftar User',
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
                          'Tambah User',
                          style: TextStyle(fontSize: 14),
                        ),
                        onPressed: _addUser,
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 250,
                        height: 33,
                        child: TextField(
                          controller: searchController,
                          decoration: InputDecoration(
                            hintText: 'Cari User...',
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
                                users = users.where((user) {
                                  final nama = user.namaLengkap.toLowerCase();
                                  final username = user.username.toLowerCase();
                                  final status = user.status.toLowerCase();
                                  final email = user.email.toLowerCase();
                                  final telepon = user.telepon.toLowerCase();
                                  return nama.contains(query) ||
                                      username.contains(query) ||
                                      status.contains(query) ||
                                      email.contains(query) ||
                                      telepon.contains(query);
                                }).toList();
                                _currentPage = 1;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: SingleChildScrollView(
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.7,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: _buildSortableHeader('No', null),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: _buildSortableHeader(
                                      'Nama Lengkap',
                                      'nama',
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: _buildSortableHeader(
                                      'Status',
                                      'status',
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: _buildSortableHeader(
                                      'Username',
                                      'username',
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: _buildHeaderCell('Password'),
                                  ),
                                  Expanded(
                                    flex: 4,
                                    child: _buildSortableHeader(
                                      'Email',
                                      'email',
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: _buildHeaderCell('Telepon'),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: _buildHeaderCell('Aksi'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.5,
                              child: ListView(
                                children: [
                                  ..._currentUsers.asMap().entries.map((entry) {
                                    final index = entry.key +
                                        (_currentPage - 1) * _itemsPerPage;
                                    final user = entry.value;
                                    final rowKey = index;
                                    return MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      onEnter: (_) =>
                                          setState(() => _hoveredRow = rowKey),
                                      onExit: (_) =>
                                          setState(() => _hoveredRow = null),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 150),
                                        decoration: BoxDecoration(
                                          color: _hoveredRow == rowKey
                                              ? Colors.grey.shade100
                                              : Colors.transparent,
                                          border: Border(
                                            bottom: BorderSide(
                                              color: Colors.grey.shade200,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 1,
                                              child: _buildDataCell("${index + 1}"),
                                            ),
                                            Expanded(
                                              flex: 3,
                                              child: _buildDataCell(
                                                user.namaLengkap,
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: _buildDataCell(user.status),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: _buildDataCell(
                                                user.username,
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: _buildDataCell(
                                                user.password,
                                              ),
                                            ),
                                            Expanded(
                                              flex: 4,
                                              child: _buildDataCell(user.email),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: _buildDataCell(
                                                user.telepon,
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Container(
                                                alignment: Alignment.center,
                                                height: 48,
                                                padding: const EdgeInsets.symmetric(
                                                  vertical: 8,
                                                ),
                                                decoration: BoxDecoration(
                                                  border: Border(
                                                    left: BorderSide(
                                                      color: Colors.grey.shade300,
                                                      width: 1,
                                                    ),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.edit,
                                                        color: Color(0xFFEA2070),
                                                        size: 18,
                                                      ),
                                                      onPressed: () => _editUser(user),
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.delete,
                                                        color: Color(0xFFEA2070),
                                                        size: 18,
                                                      ),
                                                      onPressed: () => _deleteUser(user.docId), // ✅ Gunakan docId
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                            if (_totalPages > 1) const SizedBox(height: 16),
                            if (_totalPages > 1)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Halaman $_currentPage dari $_totalPages',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.chevron_left, size: 18),
                                        onPressed: _currentPage == 1
                                            ? null
                                            : () {
                                                setState(() {
                                                  _currentPage--;
                                                });
                                              },
                                        color: _currentPage == 1
                                            ? Colors.grey
                                            : Colors.black,
                                      ),
                                      const SizedBox(width: 12),
                                      IconButton(
                                        icon: const Icon(Icons.chevron_right, size: 18),
                                        onPressed: _currentPage == _totalPages
                                            ? null
                                            : () {
                                                setState(() {
                                                  _currentPage++;
                                                });
                                              },
                                        color: _currentPage == _totalPages
                                            ? Colors.grey
                                            : Colors.black,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
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

  Widget _buildSortableHeader(String label, String? sortBy) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          if (sortBy != null) {
            _sortUsers(sortBy);
          }
        },
        child: Container(
          alignment: Alignment.center,
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              if (sortBy != null && _sortBy == sortBy)
                Icon(
                  _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 14,
                  color: Colors.grey.shade600,
                ),
            ],
          ),
        ),
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
              color: _hoveredItem == title
                  ? Colors.white12
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
              splashColor: Colors.white30,
              highlightColor: Colors.white10,
              child: ListTile(
                leading: Icon(icon, color: color, size: 20),
                title: _isSidebarCollapsed
                    ? null
                    : Text(
                        title,
                        style: TextStyle(color: color, fontSize: 14),
                      ),
                dense: true,
                horizontalTitleGap: 12,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}