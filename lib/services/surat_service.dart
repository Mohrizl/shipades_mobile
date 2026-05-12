import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/surat_model.dart';
import 'auth_service.dart';

class SuratService {
  // 1. Ambil Daftar Surat Saya
  static Future<List<SuratModel>> getSuratSaya() async {
    final token = await AuthService.getToken();
    try {
      // BACKEND: r.get('/', c.myList); -> Jadi cukup /api/surat
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/surat'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));
      
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        var content = data['data'];
        List? items;
        
        if (content is List) {
          items = content;
        } else if (content is Map) {
          // Menangani jika dibungkus dalam pagination
          items = content['data'] ?? content['results'] ?? content['items'] ?? [];
        }
        
        return items?.map((e) => SuratModel.fromJson(e)).toList() ?? [];
      }
    } catch (e) {
      // Log error silently
    }
    return [];
  }

  // 2. Ambil Statistik (Total, Menunggu, Diproses) untuk di Beranda
  static Future<Map<String, dynamic>> getStats() async {
    final token = await AuthService.getToken();
    try {
      // BACKEND: r.get('/stats', c.stats);
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/surat/stats'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        return data['data']; // Biasanya isinya {total: x, waiting: y, process: z}
      }
    } catch (e) {
      // Log error silently
    }
    return {'total': 0, 'waiting': 0, 'process': 0, 'done': 0};
  }

  static Future<Map<String, dynamic>> ajukanSurat({
    required String jenisSuratId,
    required String keperluan,
    required String fotoKtpPath,
    String? dokumenPendukungPath,
  }) async {
    final token = await AuthService.getToken();
    final request = http.MultipartRequest(
      'POST', Uri.parse('${ApiConfig.baseUrl}/surat'),
    );
    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });
    request.fields['jenis_surat_id'] = jenisSuratId;
    request.fields['keperluan'] = keperluan;
    
    if (fotoKtpPath.isNotEmpty) {
      request.files.add(await http.MultipartFile.fromPath('foto_ktp', fotoKtpPath));
    }
    
    if (dokumenPendukungPath != null && dokumenPendukungPath.isNotEmpty) {
      request.files.add(await http.MultipartFile.fromPath('dokumen_pendukung', dokumenPendukungPath));
    }

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    
    try {
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Gagal memproses respon server.'};
    }
  }

  static Future<List<Map<String, dynamic>>> getJenisSurat() async {
    final token = await AuthService.getToken();
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/jenis-surat'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));
      
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        final List? items = data['data'] is List 
            ? data['data'] 
            : (data['data']?['data'] as List?);
        return List<Map<String, dynamic>>.from(items ?? []);
      }
    } catch (e) {
      // Log error silently
    }
    return [];
  }
}
