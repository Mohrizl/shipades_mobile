class NotifikasiModel {
  final int id;
  final String judul, pesan, tipe;
  bool dibaca;
  final String tanggal;

  NotifikasiModel({required this.id, required this.judul, required this.pesan,
    required this.tipe, required this.dibaca, required this.tanggal});

  factory NotifikasiModel.fromJson(Map<String, dynamic> j) => NotifikasiModel(
    id: j['id'],
    judul: j['judul'] ?? '',
    pesan: j['pesan'] ?? '',
    tipe: j['tipe'] ?? 'info',
    dibaca: j['dibaca'] == 1 || j['dibaca'] == true,
    tanggal: j['created_at'] ?? '',
  );
}