// lib/models/admin_model.dart
import 'dart:typed_data';

class Admin {
  final String id; // ✅ Tambahkan id
  final String nama;
  final String username;
  final String password;
  final String telepon;
  final String? fotoUrl;
  final Uint8List? fotoBytes;

  Admin({
    required this.id,
    required this.nama,
    required this.username,
    required this.password,
    required this.telepon,
    this.fotoUrl,
    this.fotoBytes,
  });

  Admin copyWith({
    String? id,
    String? nama,
    String? username,
    String? password,
    String? telepon,
    String? fotoUrl,
    Uint8List? fotoBytes,
  }) {
    return Admin(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      username: username ?? this.username,
      password: password ?? this.password,
      telepon: telepon ?? this.telepon,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      fotoBytes: fotoBytes ?? this.fotoBytes,
    );
  }
}