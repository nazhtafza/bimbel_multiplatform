class PaketModel {
  final String id;
  final String namaPaket;
  final int nominal;
  final String badgeLetter;
  final DateTime? createdAt;

  PaketModel({
    required this.id,
    required this.namaPaket,
    required this.nominal,
    String? badgeLetter,
    this.createdAt,
  }) : badgeLetter = badgeLetter ?? (namaPaket.isNotEmpty ? namaPaket[0].toUpperCase() : 'A');

  factory PaketModel.fromMap(Map<String, dynamic> map) {
    final nama = map['nama_paket']?.toString() ?? map['nama']?.toString() ?? '';
    return PaketModel(
      id: map['id']?.toString() ?? '',
      namaPaket: nama,
      nominal: (map['nominal'] is int)
          ? map['nominal'] as int
          : int.tryParse(map['nominal']?.toString() ?? '0') ?? 0,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nama_paket': namaPaket,
      'nominal': nominal,
    };
  }

  PaketModel copyWith({
    String? id,
    String? namaPaket,
    int? nominal,
    String? badgeLetter,
    DateTime? createdAt,
  }) {
    return PaketModel(
      id: id ?? this.id,
      namaPaket: namaPaket ?? this.namaPaket,
      nominal: nominal ?? this.nominal,
      badgeLetter: badgeLetter ?? this.badgeLetter,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
