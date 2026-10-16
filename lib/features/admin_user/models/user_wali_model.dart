import 'package:flutter/material.dart';

class UserWaliModel {
  final String id;
  final String nama;
  final String email;
  final String? noHp;
  final String namaSiswa;
  final String role;
  final DateTime? lastLogin;
  final DateTime? createdAt;
  final String statusSpp; // 'Lunas', 'Belum Lunas', 'Jatuh Tempo'
  final int totalTagihan;
  final int totalRiwayat;

  const UserWaliModel({
    required this.id,
    required this.nama,
    required this.email,
    this.noHp,
    required this.namaSiswa,
    this.role = 'Wali',
    this.lastLogin,
    this.createdAt,
    this.statusSpp = 'Belum Lunas',
    this.totalTagihan = 250000,
    this.totalRiwayat = 1,
  });

  Color get avatarColor {
    final colors = [
      const Color(0xFF6200EE),
      const Color(0xFF7B1FA2),
      const Color(0xFF0288D1),
      const Color(0xFF00897B),
      const Color(0xFFE65100),
      const Color(0xFFC2185B),
    ];
    if (nama.isEmpty) return colors[0];
    final index = nama.codeUnits.reduce((a, b) => a + b) % colors.length;
    return colors[index];
  }

  String get lastLoginFormatted {
    if (lastLogin == null) return 'Belum pernah login';
    final now = DateTime.now();
    final diff = now.difference(lastLogin!);

    if (diff.inMinutes < 1) {
      return 'Baru saja';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} menit yang lalu';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} jam yang lalu';
    } else if (diff.inDays == 1) {
      return 'Kemarin';
    } else {
      return '${diff.inDays} hari yang lalu';
    }
  }

  factory UserWaliModel.fromMap(Map<String, dynamic> map) {
    return UserWaliModel(
      id: map['id']?.toString() ?? '',
      nama: map['nama']?.toString() ?? map['name']?.toString() ?? 'Wali Murid',
      email: map['email']?.toString() ?? '',
      noHp: map['no_hp']?.toString() ?? map['phone']?.toString() ?? '0812-3456-7890',
      namaSiswa: map['nama_siswa']?.toString() ?? map['siswa']?.toString() ?? 'Siswa',
      role: map['role']?.toString() ?? 'Wali',
      lastLogin: map['last_login'] != null
          ? DateTime.tryParse(map['last_login'].toString())
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      statusSpp: map['status_spp']?.toString() ?? 'Belum Lunas',
      totalTagihan: (map['total_tagihan'] is int)
          ? map['total_tagihan'] as int
          : int.tryParse(map['total_tagihan']?.toString() ?? '250000') ?? 250000,
      totalRiwayat: (map['total_riwayat'] is int)
          ? map['total_riwayat'] as int
          : int.tryParse(map['total_riwayat']?.toString() ?? '1') ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'email': email,
      'no_hp': noHp,
      'nama_siswa': namaSiswa,
      'role': role,
      'last_login': lastLogin?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'status_spp': statusSpp,
      'total_tagihan': totalTagihan,
      'total_riwayat': totalRiwayat,
    };
  }

  UserWaliModel copyWith({
    String? id,
    String? nama,
    String? email,
    String? noHp,
    String? namaSiswa,
    String? role,
    DateTime? lastLogin,
    DateTime? createdAt,
    String? statusSpp,
    int? totalTagihan,
    int? totalRiwayat,
  }) {
    return UserWaliModel(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      email: email ?? this.email,
      noHp: noHp ?? this.noHp,
      namaSiswa: namaSiswa ?? this.namaSiswa,
      role: role ?? this.role,
      lastLogin: lastLogin ?? this.lastLogin,
      createdAt: createdAt ?? this.createdAt,
      statusSpp: statusSpp ?? this.statusSpp,
      totalTagihan: totalTagihan ?? this.totalTagihan,
      totalRiwayat: totalRiwayat ?? this.totalRiwayat,
    );
  }
}
