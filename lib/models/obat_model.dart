// lib/models/obat_model.dart
class Obat {
  final String id; // ✅ String, bukan int
  final String namaObat;
  final String kategoriObat;
  final int stokObat;
  final String jenisObat;
  final int harga;

  Obat({
    required this.id,
    required this.namaObat,
    required this.kategoriObat,
    required this.stokObat,
    required this.jenisObat,
    required this.harga,
  });

  Map<String, dynamic> toMap() {
    return {
      'namaObat': namaObat,
      'kategoriObat': kategoriObat,
      'stokObat': stokObat,
      'jenisObat': jenisObat,
      'harga': harga,
    };
  }

  factory Obat.fromMap(String id, Map<String, dynamic> map) {
    return Obat(
      id: id, // ✅ Ambil dari Firestore
      namaObat: map['namaObat'],
      kategoriObat: map['kategoriObat'],
      stokObat: map['stokObat'],
      jenisObat: map['jenisObat'],
      harga: map['harga'],
    );
  }
}