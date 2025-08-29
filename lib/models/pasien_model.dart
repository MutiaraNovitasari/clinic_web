// lib/models/pasien_model.dart

/// Model untuk data pasien.
class Pasien {
  /// ID dokumen dari Firestore
  final String id;

  /// Nomor Rekam Medis (contoh: RM-142355)
  final String nomorRekamMedis;

  /// Nama lengkap pasien
  final String namaLengkap;

  /// Golongan darah (A+, B-, dll)
  final String golonganDarah;

  /// Jenis kelamin: "Laki-Laki" atau "Perempuan"
  final String jenisKelamin;

  /// Umur pasien dalam tahun
  final String umur;

  /// Nomor telepon pasien
  final String noTelepon;

  /// Status: "Pelajar", "Karyawan", dll
  final String status;

  /// Alergi obat (opsional)
  final String? alergiObat;

  Pasien({
    required this.id,
    required this.nomorRekamMedis,
    required this.namaLengkap,
    required this.golonganDarah,
    required this.jenisKelamin,
    required this.umur,
    required this.noTelepon,
    required this.status,
    this.alergiObat,
  });

  /// Membuat salinan objek dengan field yang bisa diubah.
  Pasien copyWith({
    String? id,
    String? nomorRekamMedis,
    String? namaLengkap,
    String? golonganDarah,
    String? jenisKelamin,
    String? umur,
    String? noTelepon,
    String? status,
    String? alergiObat,
  }) {
    return Pasien(
      id: id ?? this.id,
      nomorRekamMedis: nomorRekamMedis ?? this.nomorRekamMedis,
      namaLengkap: namaLengkap ?? this.namaLengkap,
      golonganDarah: golonganDarah ?? this.golonganDarah,
      jenisKelamin: jenisKelamin ?? this.jenisKelamin,
      umur: umur ?? this.umur,
      noTelepon: noTelepon ?? this.noTelepon,
      status: status ?? this.status,
      alergiObat: alergiObat ?? this.alergiObat,
    );
  }

  /// Konversi objek ke Map untuk disimpan di Firestore.
  Map<String, dynamic> toMap() {
    return {
      'nomorRekamMedis': nomorRekamMedis,
      'namaLengkap': namaLengkap,
      'golonganDarah': golonganDarah,
      'jenisKelamin': jenisKelamin,
      'umur': umur,
      'noTelepon': noTelepon,
      'status': status,
      'alergiObat': alergiObat ?? '', // Simpan sebagai string kosong jika null
    };
  }

  /// Buat objek Pasien dari data Firestore.
  factory Pasien.fromMap(String id, Map<String, dynamic> map) {
    return Pasien(
      id: id,
      nomorRekamMedis: map['nomorRekamMedis'] as String? ?? '',
      namaLengkap: map['namaLengkap'] as String? ?? '',
      golonganDarah: map['golonganDarah'] as String? ?? '',
      jenisKelamin: map['jenisKelamin'] as String? ?? '',
      umur: map['umur'] as String? ?? '',
      noTelepon: map['noTelepon'] as String? ?? '',
      status: map['status'] as String? ?? '',
      alergiObat: map['alergiObat'] as String?,
    );
  }

  @override
  String toString() {
    return 'Pasien(id: $id, nomorRekamMedis: $nomorRekamMedis, namaLengkap: $namaLengkap, golonganDarah: $golonganDarah, jenisKelamin: $jenisKelamin, umur: $umur, noTelepon: $noTelepon, status: $status, alergiObat: $alergiObat)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Pasien &&
        other.id == id &&
        other.nomorRekamMedis == nomorRekamMedis &&
        other.namaLengkap == namaLengkap &&
        other.golonganDarah == golonganDarah &&
        other.jenisKelamin == jenisKelamin &&
        other.umur == umur &&
        other.noTelepon == noTelepon &&
        other.status == status &&
        other.alergiObat == alergiObat;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        nomorRekamMedis.hashCode ^
        namaLengkap.hashCode ^
        golonganDarah.hashCode ^
        jenisKelamin.hashCode ^
        umur.hashCode ^
        noTelepon.hashCode ^
        status.hashCode ^
        alergiObat.hashCode;
  }
}