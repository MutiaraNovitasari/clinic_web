// lib/models/user_model.dart
import 'dart:typed_data';

class User {
  /// ID dokumen dari Firestore
  final String docId;

  /// Data Utama
  final String namaLengkap;
  final String status; // Dokter, Resepsionis, Apoteker
  final String username;
  final String password;
  final String email;
  final String telepon;

  /// Foto Profil
  final String? fotoUrl; // URL alternatif (jika pakai Firebase Storage)
  final Uint8List? fotoBytes; // Simpan langsung di Firestore (untuk web)

  /// Timestamp
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    required this.docId,
    required this.namaLengkap,
    required this.status,
    required this.username,
    required this.password,
    required this.email,
    required this.telepon,
    this.fotoUrl,
    this.fotoBytes,
    this.createdAt,
    this.updatedAt,
  });

  User copyWith({
    String? docId,
    String? namaLengkap,
    String? status,
    String? username,
    String? password,
    String? email,
    String? telepon,
    String? fotoUrl,
    Uint8List? fotoBytes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      docId: docId ?? this.docId,
      namaLengkap: namaLengkap ?? this.namaLengkap,
      status: status ?? this.status,
      username: username ?? this.username,
      password: password ?? this.password,
      email: email ?? this.email,
      telepon: telepon ?? this.telepon,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      fotoBytes: fotoBytes ?? this.fotoBytes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Konversi dari Firestore ke objek User
  factory User.fromMap(String docId, Map<String, dynamic> data) {
    return User(
      docId: docId,
      namaLengkap: data['namaLengkap'] as String? ?? '',
      status: data['status'] as String? ?? '',
      username: data['username'] as String? ?? '',
      password: data['password'] as String? ?? '',
      email: data['email'] as String? ?? '',
      telepon: data['telepon'] as String? ?? '',
      fotoUrl: data['fotoUrl'] as String?,
      fotoBytes: data['fotoBytes'] is List
          ? Uint8List.fromList((data['fotoBytes'] as List<dynamic>).map((e) => e as int).toList())
          : null,
      createdAt: (data['createdAt'] as DateTime?) ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as DateTime?) ?? DateTime.now(),
    );
  }

  /// Konversi dari User ke Map untuk Firestore
  Map<String, dynamic> toMap() {
    return {
      'namaLengkap': namaLengkap,
      'status': status,
      'username': username,
      'password': password,
      'email': email,
      'telepon': telepon,
      'fotoUrl': fotoUrl,
      'fotoBytes': fotoBytes, // Bisa disimpan langsung di Firestore (web)
      'createdAt': createdAt ?? DateTime.now(),
      'updatedAt': DateTime.now(),
    };
  }

  @override
  String toString() {
    return 'User(docId: $docId, namaLengkap: $namaLengkap, status: $status, username: $username, email: $email, telepon: $telepon)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is User &&
        other.docId == docId &&
        other.namaLengkap == namaLengkap &&
        other.status == status &&
        other.username == username &&
        other.email == email &&
        other.telepon == telepon &&
        other.fotoUrl == fotoUrl;
  }

  @override
  int get hashCode {
    return docId.hashCode ^
        namaLengkap.hashCode ^
        status.hashCode ^
        username.hashCode ^
        email.hashCode ^
        telepon.hashCode ^
        (fotoUrl?.hashCode ?? 0);
  }
}