import 'package:flutter/material.dart';

class TransaksiModel {
  final String id;
  final String? siswaId;
  final String? paketId;
  final String namaSiswa;
  final int nominal;
  final String status; // 'Lunas', 'Jatuh Tempo', 'Belum Bayar'
  final String metode;
  final String tanggal;
  final String? catatan;
  final String? kategori;

  const TransaksiModel({
    required this.id,
    this.siswaId,
    this.paketId,
    required this.namaSiswa,
    required this.nominal,
    this.status = 'Lunas',
    this.metode = 'Tunai (Cash)',
    required this.tanggal,
    this.catatan,
    this.kategori,
  });

  Color get avatarColor {
    final colors = [
      const Color(0xFF7B7FD4),
      const Color(0xFFD47BAA),
      const Color(0xFFD47B7B),
      const Color(0xFF5A8FD8),
      const Color(0xFF5AB697),
    ];
    if (namaSiswa.isEmpty) return colors[0];
    final index = namaSiswa.codeUnits.reduce((a, b) => a + b) % colors.length;
    return colors[index];
  }

  factory TransaksiModel.fromMap(Map<String, dynamic> map) {
    return TransaksiModel(
      id: map['id']?.toString() ?? '',
      siswaId: map['siswa_id']?.toString(),
      paketId: map['paket_id']?.toString() ?? map['id_paket']?.toString(),
      namaSiswa: map['nama_siswa']?.toString() ?? map['siswa']?['nama']?.toString() ?? 'Siswa',
      nominal: (map['nominal'] is int)
          ? map['nominal'] as int
          : int.tryParse(map['nominal']?.toString() ?? '0') ?? 0,
      status: map['status']?.toString() ?? 'Lunas',
      metode: (map['metode']?.toString().toLowerCase() == 'cash')
          ? 'Tunai (Cash)'
          : (map['metode']?.toString().toLowerCase() == 'transfer')
              ? 'Transfer Bank'
              : (map['metode']?.toString() ?? 'Tunai (Cash)'),
      tanggal: map['tanggal']?.toString() ?? '',
      catatan: map['catatan']?.toString(),
      kategori: map['kategori']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nama_siswa': namaSiswa,
      if (siswaId != null) 'siswa_id': siswaId,
      if (paketId != null) 'paket_id': paketId,
      'nominal': nominal,
      'status': status,
      'metode': metode,
      'tanggal': tanggal,
      if (catatan != null) 'catatan': catatan,
      if (kategori != null) 'kategori': kategori,
    };
  }

  TransaksiModel copyWith({
    String? id,
    String? siswaId,
    String? paketId,
    String? namaSiswa,
    int? nominal,
    String? status,
    String? metode,
    String? tanggal,
    String? catatan,
    String? kategori,
  }) {
    return TransaksiModel(
      id: id ?? this.id,
      siswaId: siswaId ?? this.siswaId,
      paketId: paketId ?? this.paketId,
      namaSiswa: namaSiswa ?? this.namaSiswa,
      nominal: nominal ?? this.nominal,
      status: status ?? this.status,
      metode: metode ?? this.metode,
      tanggal: tanggal ?? this.tanggal,
      catatan: catatan ?? this.catatan,
      kategori: kategori ?? this.kategori,
    );
  }
}
