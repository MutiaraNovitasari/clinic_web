// lib/models/anamnesa_awal.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class AnamnesaAwal {
  final String id; // document id
  final String pasienId;
  final String namaPasien;
  final String nomorRekamMedis;
  final String keluhan;
  final String beratBadan;
  final String tinggiBadan;
  final String suhuTubuh;
  final String tekananDarah;
  final DateTime tanggalKunjungan;
  final DateTime createdAt;

  AnamnesaAwal({
    required this.id,
    required this.pasienId,
    required this.namaPasien,
    required this.nomorRekamMedis,
    required this.keluhan,
    required this.beratBadan,
    required this.tinggiBadan,
    required this.suhuTubuh,
    required this.tekananDarah,
    required this.tanggalKunjungan,
    required this.createdAt,
  });

  // Konversi dari Firestore (Map → AnamnesaAwal)
  factory AnamnesaAwal.fromMap(Map<String, dynamic> map, String id) {
    return AnamnesaAwal(
      id: id,
      pasienId: map['pasienId'] ?? '',
      namaPasien: map['namaPasien'] ?? '',
      nomorRekamMedis: map['nomorRekamMedis'] ?? '',
      keluhan: map['keluhan'] ?? '',
      beratBadan: map['beratBadan'] ?? '',
      tinggiBadan: map['tinggiBadan'] ?? '',
      suhuTubuh: map['suhuTubuh'] ?? '',
      tekananDarah: map['tekananDarah'] ?? '',
      tanggalKunjungan: (map['tanggalKunjungan'] as Timestamp).toDate(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  // Konversi ke Firestore (AnamnesaAwal → Map)
  Map<String, dynamic> toMap() {
    return {
      'pasienId': pasienId,
      'namaPasien': namaPasien,
      'nomorRekamMedis': nomorRekamMedis,
      'keluhan': keluhan,
      'beratBadan': beratBadan,
      'tinggiBadan': tinggiBadan,
      'suhuTubuh': suhuTubuh,
      'tekananDarah': tekananDarah,
      'tanggalKunjungan': Timestamp.fromDate(tanggalKunjungan),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}