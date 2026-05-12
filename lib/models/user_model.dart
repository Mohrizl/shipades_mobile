class UserModel {
  final int id;
  final String nama, email, nik, telepon, alamat, role;

  UserModel({required this.id, required this.nama, required this.email,
    required this.nik, required this.telepon, required this.alamat, required this.role});

  factory UserModel.fromJson(Map<String, dynamic> j) {
    // Fungsi pembantu untuk konversi ID dari String atau Int secara aman
    int parseId(dynamic id) {
      if (id == null) return 0;
      if (id is int) return id;
      return int.tryParse(id.toString()) ?? 0;
    }

    return UserModel(
      id: parseId(j['id'] ?? j['_id']),
      nama: j['name']?.toString() ?? j['nama']?.toString() ?? '', 
      email: j['email']?.toString() ?? '',
      nik: j['nik']?.toString() ?? '', 
      telepon: j['phone']?.toString() ?? j['telepon']?.toString() ?? j['no_hp']?.toString() ?? '',
      alamat: j['address']?.toString() ?? j['alamat']?.toString() ?? j['alamat_lengkap']?.toString() ?? '',
      role: j['role']?.toString() ?? 'warga',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'name': nama, 'email': email,
    'nik': nik, 'phone': telepon, 'address': alamat, 'role': role,
  };
}
