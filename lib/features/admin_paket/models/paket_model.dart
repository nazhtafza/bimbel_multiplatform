class PaketModel {
  final String id;
  final String namaPaket;
  final int nominal;
  final String badgeLetter;
  final DateTime? createdAt;
  final DateTime? jatuhTempo;

  PaketModel({
    required this.id,
    required this.namaPaket,
    required this.nominal,
    String? badgeLetter,
    this.createdAt,
    this.jatuhTempo,
  }) : badgeLetter = badgeLetter ?? (namaPaket.isNotEmpty ? namaPaket[0].toUpperCase() : 'A');

  String get jatuhTempoFormatted {
    if (jatuhTempo == null) {
      final now = DateTime.now();
      return '10 ${_bulanName(now.month)} ${now.year}';
    }
    return '${jatuhTempo!.day} ${_bulanName(jatuhTempo!.month)} ${jatuhTempo!.year}';
  }

  static String _bulanName(int month) {
    const bulan = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    if (month >= 1 && month <= 12) return bulan[month - 1];
    return '';
  }

  factory PaketModel.fromMap(Map<String, dynamic> map) {
    final nama = map['nama_paket']?.toString() ?? map['nama']?.toString() ?? '';
    return PaketModel(
      id: map['id']?.toString() ?? '',
      namaPaket: nama,
      nominal: (map['nominal'] is int)
          ? map['nominal'] as int
          : int.tryParse(map['nominal']?.toString() ?? '0') ?? 0,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) : null,
      jatuhTempo: map['jatuh_tempo'] != null ? DateTime.tryParse(map['jatuh_tempo'].toString()) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama_paket': namaPaket,
      'nominal': nominal,
      if (jatuhTempo != null) 'jatuh_tempo': jatuhTempo!.toIso8601String(),
    };
  }

  PaketModel copyWith({
    String? id,
    String? namaPaket,
    int? nominal,
    String? badgeLetter,
    DateTime? createdAt,
    DateTime? jatuhTempo,
  }) {
    return PaketModel(
      id: id ?? this.id,
      namaPaket: namaPaket ?? this.namaPaket,
      nominal: nominal ?? this.nominal,
      badgeLetter: badgeLetter ?? this.badgeLetter,
      createdAt: createdAt ?? this.createdAt,
      jatuhTempo: jatuhTempo ?? this.jatuhTempo,
    );
  }
}
