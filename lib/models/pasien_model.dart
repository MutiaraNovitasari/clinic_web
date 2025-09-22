class Pasien {
  final String id;
  final String nomorRekamMedis;
  final String namaLengkap;
  final String alamat; // ✅ Baru
  final String jenisKelamin;
  final String umur;
  final String noTelepon;
  final String status;
  final String? alergiObat;

  Pasien({
    required this.id,
    required this.nomorRekamMedis,
    required this.namaLengkap,
    required this.alamat,
    required this.jenisKelamin,
    required this.umur,
    required this.noTelepon,
    required this.status,
    this.alergiObat,
  });

  Map<String, dynamic> toMap() {
    return {
      'nomorRekamMedis': nomorRekamMedis,
      'namaLengkap': namaLengkap,
      'alamat': alamat,
      'jenisKelamin': jenisKelamin,
      'umur': umur,
      'noTelepon': noTelepon,
      'status': status,
      'alergiObat': alergiObat,
    };
  }

  Pasien copyWith({
    String? id,
    String? nomorRekamMedis,
    String? namaLengkap,
    String? alamat,
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
      alamat: alamat ?? this.alamat,
      jenisKelamin: jenisKelamin ?? this.jenisKelamin,
      umur: umur ?? this.umur,
      noTelepon: noTelepon ?? this.noTelepon,
      status: status ?? this.status,
      alergiObat: alergiObat ?? this.alergiObat,
    );
  }

  factory Pasien.fromMap(String id, Map<String, dynamic> map) {
    return Pasien(
      id: id,
      nomorRekamMedis: map['nomorRekamMedis'],
      namaLengkap: map['namaLengkap'],
      alamat: map['alamat'], // ✅ Ambil alamat
      jenisKelamin: map['jenisKelamin'],
      umur: map['umur'],
      noTelepon: map['noTelepon'],
      status: map['status'],
      alergiObat: map['alergiObat'],
    );
  }
}