import '../config/api_config.dart';

class SuratModel {
  final int id;
  final String jenisSurat, keperluan, status, tanggal, nomorPengajuan, namaWarga, nikWarga;
  final String? fileSurat, fotoKtp, dokumenPendukung, catatanPetugas;

  SuratModel({
    required this.id, 
    required this.jenisSurat, 
    required this.keperluan,
    required this.status, 
    required this.tanggal, 
    required this.nomorPengajuan,
    required this.namaWarga,
    required this.nikWarga,
    this.fileSurat, 
    this.fotoKtp, 
    this.dokumenPendukung,
    this.catatanPetugas
  });

  // Helper untuk mendapatkan URL lengkap file
  static String getFullUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    
    // Ambil base URL dari ApiConfig dan hilangkan /api
    final String base = ApiConfig.baseUrl.replaceAll('/api', '');
    
    String cleanPath = path.startsWith('/') ? path.substring(1) : path;
    
    // Normalisasi path jika mengandung backslash dari Windows server
    cleanPath = cleanPath.replaceAll('\\', '/');

    // Jika path sudah mengandung uploads atau storage
    if (cleanPath.toLowerCase().contains('uploads/') || cleanPath.toLowerCase().contains('storage/')) {
      return '$base/$cleanPath';
    }
    
    // Jika hanya nama file saja
    return '$base/uploads/$cleanPath';
  }

  factory SuratModel.fromJson(Map<String, dynamic> j) {
    // Helper untuk membersihkan data string
    String? s(dynamic val) {
      if (val == null || val is Map || val is List) return null;
      String str = val.toString().trim();
      if (str.isEmpty || str == '-' || str == '.' || str.toLowerCase() == 'null') return null;
      return str;
    }

    // Helper untuk mengambil path file dari berbagai format (string atau object)
    String? getFilePath(dynamic val) {
      if (val == null) return null;
      if (val is String) return s(val);
      if (val is Map) {
        return s(val['path']) ?? s(val['url']) ?? s(val['file']) ?? s(val['filename']) ?? s(val['uri']) ?? s(val['surat_file']);
      }
      return null;
    }

    String name = 'Warga';
    String nik = '-';
    
    // Ambil path KTP dan Dokumen Pendukung untuk dikecualikan dalam pencarian file surat resmi
    String? ktpPath = getFilePath(j['foto_ktp']);
    String? dokPath = getFilePath(j['dokumen_pendukung']);

    // 1. CARI NAMA (Prioritas: Objek Nested -> Flat Keys -> Scan All Keys)
    for (var key in ['user', 'warga', 'penduduk', 'pemohon', 'pelapor', 'user_detail']) {
      var val = j[key];
      if (val is Map) {
        name = s(val['name']) ?? s(val['nama']) ?? s(val['nama_lengkap']) ?? s(val['full_name']) ?? name;
        if (name != 'Warga') break;
      } else if (val is String) {
        var cleaned = s(val);
        if (cleaned != null && cleaned.length > 2 && !cleaned.toLowerCase().contains('surat')) {
          name = cleaned;
          break;
        }
      }
    }

    if (name == 'Warga') {
      name = s(j['nama_warga']) ?? s(j['user_nama']) ?? s(j['warga_nama']) ?? 
             s(j['name']) ?? s(j['nama_pemohon']) ?? s(j['nama_lengkap']) ?? name;
    }

    if (name == 'Warga') {
      j.forEach((key, value) {
        if (name != 'Warga') return;
        String k = key.toLowerCase();
        if (k.contains('nama') || k.contains('name')) {
          String? val = s(value);
          if (val != null && val.length > 2 && !val.toLowerCase().contains('surat')) {
            name = val;
          }
        }
      });
    }

    // 2. CARI NIK
    for (var key in ['user', 'warga', 'penduduk', 'pemohon', 'pelapor', 'user_detail']) {
      var val = j[key];
      if (val is Map) {
        nik = s(val['nik']) ?? s(val['no_ktp']) ?? s(val['nomor_induk']) ?? s(val['ktp']) ?? nik;
        if (nik != '-') break;
      }
    }

    if (nik == '-') {
      nik = s(j['nik']) ?? s(j['no_ktp']) ?? s(j['nik_warga']) ?? s(j['user_nik']) ?? 
            s(j['warga_nik']) ?? s(j['nik_pemohon']) ?? s(j['nomor_induk']) ?? 
            s(j['ktp_nomor']) ?? s(j['ktp']) ?? s(j['no_identitas']) ?? s(j['identitas']) ?? nik;
    }

    if (nik == '-') {
      j.forEach((key, value) {
        if (nik != '-') return;
        String k = key.toLowerCase();
        if ((k.contains('nik') || k.contains('ktp') || k.contains('induk') || k.contains('identitas')) && !k.contains('foto')) {
          String? val = s(value);
          if (val != null && val.length >= 10) {
            nik = val;
          }
        }
      });
    }

    // 3. JENIS SURAT
    String jenis = 'Surat';
    var js = j['jenis_surat'];
    if (js is Map) {
      jenis = s(js['nama']) ?? s(js['name']) ?? jenis;
    } else {
      jenis = s(j['jenis_surat_nama']) ?? s(j['nama_surat']) ?? s(j['jenis_surat']) ?? jenis;
    }
    if (jenis == 'Surat') {
      var n = s(j['nama']);
      if (n != null && n.toLowerCase().contains('surat')) jenis = n;
    }

    // 4. CARI FILE SURAT (Agresif & Rekursif)
    String? fileSurat = getFilePath(j['surat_file']) ?? getFilePath(j['file_surat']) ?? 
                        getFilePath(j['file_resmi']) ?? getFilePath(j['surat_jadi']) ?? 
                        getFilePath(j['surat_hasil']) ?? getFilePath(j['file_path']) ??
                        getFilePath(j['path_surat']) ?? getFilePath(j['url_surat']) ?? 
                        getFilePath(j['file_terbit']) ?? getFilePath(j['surat_terbit']) ?? 
                        getFilePath(j['berkas_surat']) ?? getFilePath(j['dokumen_final']);

    // Fungsi pencarian rekursif untuk file (Deep Search)
    String? findFileRecursively(dynamic data, {int depth = 0, String? currentKey, bool ignoreFilters = false}) {
      if (depth > 15) return null; 
      if (data == null) return null;

      if (data is String) {
        String v = data.trim();
        String vLower = v.toLowerCase();
        
        bool isDoc = vLower.endsWith('.pdf') || vLower.endsWith('.doc') || vLower.endsWith('.docx') || 
                     vLower.contains('.pdf?') || vLower.contains('.doc?') || vLower.contains('.docx?') ||
                     vLower.contains('/surat/') || vLower.contains('/terbit/') || vLower.contains('/hasil/') ||
                     vLower.contains('/uploads/') || vLower.contains('/storage/') || vLower.contains('/download/');
        
        if (isDoc) {
          if (ignoreFilters) return v;

          if (currentKey != null) {
            String ck = currentKey.toLowerCase();
            List<String> officialKeys = [
              'surat_file', 'file_surat', 'file_resmi', 'surat_hasil', 'surat_jadi', 
              'berkas_surat', 'dokumen_final', 'hasil_surat', 'file_terbit', 'surat_terbit',
              'surat', 'hasil', 'penerbitan', 'file'
            ];
            if (officialKeys.any((k) => ck.contains(k))) return v;
          }

          if (ktpPath != null && vLower.contains(ktpPath.toLowerCase())) return null;
          if (dokPath != null && vLower.contains(dokPath.toLowerCase())) return null;

          List<String> identityKeywords = ['ktp', 'nik_', 'no_ktp', 'avatar', 'user_photo', 'selfie', 'profil'];
          if (identityKeywords.any((k) => vLower.contains(k))) return null;
          
          return v;
        }
      }

      if (data is Map) {
        var entries = data.entries.toList();
        entries.sort((a, b) {
          String ka = a.key.toString().toLowerCase();
          String kb = b.key.toString().toLowerCase();
          bool aP = ka.contains('surat') || ka.contains('resmi') || ka.contains('hasil') || ka.contains('final') || ka.contains('terbit');
          bool bP = kb.contains('surat') || kb.contains('resmi') || kb.contains('hasil') || kb.contains('final') || kb.contains('terbit');
          if (aP && !bP) return -1;
          if (!aP && bP) return 1;
          return 0;
        });

        for (var entry in entries) {
          var found = findFileRecursively(entry.value, depth: depth + 1, currentKey: entry.key.toString(), ignoreFilters: ignoreFilters);
          if (found != null) return found;
        }
      }

      if (data is List) {
        for (var item in data) {
          var found = findFileRecursively(item, depth: depth + 1, ignoreFilters: ignoreFilters);
          if (found != null) return found;
        }
      }
      return null;
    }

    if (fileSurat == null) {
      fileSurat = findFileRecursively(j);
    }
    
    if (fileSurat == null && s(j['status'])?.toLowerCase() == 'selesai') {
      fileSurat = findFileRecursively(j, ignoreFilters: true);
    }

    return SuratModel(
      id: int.tryParse(j['id']?.toString() ?? '0') ?? 0,
      nomorPengajuan: j['nomor_pengajuan']?.toString() ?? 'REQ-${j['id']}',
      jenisSurat: jenis,
      namaWarga: name,
      nikWarga: nik,
      keperluan: j['keperluan']?.toString() ?? '',
      status: j['status']?.toString() ?? 'pending',
      tanggal: j['created_at']?.toString().split('T')[0] ?? '',
      fileSurat: fileSurat,
      fotoKtp: ktpPath,
      dokumenPendukung: dokPath,
      catatanPetugas: s(j['catatan_petugas']) ?? s(j['keterangan']),
    );
  }
}
