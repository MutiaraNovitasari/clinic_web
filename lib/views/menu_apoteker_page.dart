// lib/views/menu_apoteker_page.dart
// ignore_for_file: use_build_context_synchronously
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'login_page.dart';

class MenuApotekerPage extends StatefulWidget {
  const MenuApotekerPage({super.key});

  @override
  State<MenuApotekerPage> createState() => _MenuApotekerPageState();
}

class _MenuApotekerPageState extends State<MenuApotekerPage> {
  String _userName = 'Apoteker';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = firebase.FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          _userName = doc.data()?['nama'] ?? 'Apoteker';
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
            const Text('Resep Obat dari Dokter', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('resep_obat')
                    .where('status', isEqualTo: 'Baru')
                    .orderBy('tanggal', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return const Text("Gagal muat data");
                  if (!snapshot.hasData) return const CircularProgressIndicator();

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final doc = snapshot.data!.docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      return ListTile(
                        title: Text(data['namaPasien']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("RM: ${data['nomorRekamMedis']}"),
                            Text("Diagnosis: ${data['diagnosis']}"),
                            Text("Resep: ${data['resep']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text("Dokter: ${data['dokter']}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        trailing: ElevatedButton(
                          onPressed: () async {
                            await FirebaseFirestore.instance.collection('resep_obat').doc(doc.id).update({
                              'status': 'Diproses',
                              'tanggalDiproses': DateTime.now(),
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Resep sedang diproses")),
                            );
                          },
                          child: const Text("Proses", style: TextStyle(color: Colors.white)),
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
}