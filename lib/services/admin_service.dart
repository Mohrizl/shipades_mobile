import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class AdminService {
  static bool _isHtml(String body) => body.startsWith('<!DOCTYPE') || body.startsWith('<html');

  // Ambil data Dashboard
  static Future<Map<String, dynamic>> getDashboard() async {
    final token = await AuthService.getToken();
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/admin/dashboard'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (_isHtml(res.body)) return {'success': false, 'message': 'Server Error (HTML)'};
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Ambil semua daftar surat
  static Future<Map<String, dynamic>> getAllSurat({String? status, String? search}) async {
    final token = await AuthService.getToken();
    try {
      String url = '${ApiConfig.baseUrl}/admin/surat?limit=100';
      if (status != null && status != 'Semua') url += '&status=${status.toLowerCase()}';
      if (search != null) url += '&search=$search';

      final res = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (_isHtml(res.body)) return {'success': false, 'message': 'Server Error (HTML)'};
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Update Status Surat
  static Future<Map<String, dynamic>> updateStatus(int id, String status, String? catatan) async {
    final token = await AuthService.getToken();
    try {
      final res = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/admin/surat/$id/status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'status': status.toLowerCase(), 'catatan_petugas': catatan}),
      ).timeout(const Duration(seconds: 10));

      if (_isHtml(res.body)) return {'success': false, 'message': 'Gagal update status: Server Error'};
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Terbitkan Surat (Upload File Resmi)
  static Future<Map<String, dynamic>> terbitkanSurat(int id, String filePath, String? keterangan) async {
    final token = await AuthService.getToken();
    try {
      final request = http.MultipartRequest(
        'POST', Uri.parse('${ApiConfig.baseUrl}/admin/surat/$id/terbitkan'),
      );
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });
      request.files.add(await http.MultipartFile.fromPath('surat_file', filePath));
      if (keterangan != null) request.fields['keterangan'] = keterangan;

      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);
      
      if (_isHtml(res.body)) return {'success': false, 'message': 'Gagal menerbitkan: Server Error (HTML)'};
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Balas Pesan (Final Logical Attempt)
  static Future<Map<String, dynamic>> balasPesan(int id, String balasan) async {
    final token = await AuthService.getToken();
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final body = jsonEncode({'balasan': balasan});

    // Jalur yang paling logis berdasarkan sisa kemungkinan di backend Anda
    final routes = [
      {'url': '${ApiConfig.baseUrl}/admin/kontak/$id/balas', 'method': 'PATCH'},
      {'url': '${ApiConfig.baseUrl}/admin/kontak/$id/balas', 'method': 'POST'},
      {'url': '${ApiConfig.baseUrl}/admin/kontak/$id/balas', 'method': 'PUT'},
      {'url': '${ApiConfig.baseUrl}/admin/kontak/$id', 'method': 'PATCH'},
      {'url': '${ApiConfig.baseUrl}/admin/kontak/$id', 'method': 'PUT'},
      {'url': '${ApiConfig.baseUrl}/admin/kontak/$id/reply', 'method': 'POST'},
      {'url': '${ApiConfig.baseUrl}/admin/kontak/$id/reply', 'method': 'PATCH'},
      {'url': '${ApiConfig.baseUrl}/kontak/$id/balas', 'method': 'POST'},
    ];

    for (var r in routes) {
      try {
        http.Response res;
        String method = r['method']!;
        String url = r['url']!;

        if (method == 'POST') {
          res = await http.post(Uri.parse(url), headers: headers, body: body).timeout(const Duration(seconds: 5));
        } else if (method == 'PATCH') {
          res = await http.patch(Uri.parse(url), headers: headers, body: body).timeout(const Duration(seconds: 5));
        } else {
          res = await http.put(Uri.parse(url), headers: headers, body: body).timeout(const Duration(seconds: 5));
        }

        // Jika berhasil (200/201)
        if (res.statusCode == 200 || res.statusCode == 201) {
          return jsonDecode(res.body);
        }
        
        // Jika 422 (Error Validasi), berarti URL sudah BENAR tapi isinya ditolak (misal field name salah)
        if (res.statusCode == 422) {
          // Coba field lain jika 'balasan' ditolak
          final altBody = jsonEncode({'reply': balasan, 'message': balasan});
          final resAlt = await http.patch(Uri.parse(url), headers: headers, body: altBody).timeout(const Duration(seconds: 5));
          if (resAlt.statusCode == 200 || resAlt.statusCode == 201) return jsonDecode(resAlt.body);
          
          final data = jsonDecode(res.body);
          return {'success': false, 'message': 'URL Benar (${r['method']} $url), tapi validasi gagal: ${data['message'] ?? 'Cek field name'}'};
        }
      } catch (_) {}
    }

    return {
      'success': false, 
      'message': 'Gagal (404): Alamat tidak ditemukan.\n\nTips: Cek file "api.php" di backend, cari "balas" untuk kontak id: $id'
    };
  }

  // Hapus Pesan
  static Future<Map<String, dynamic>> deletePesan(int id) async {
    final token = await AuthService.getToken();
    try {
      final res = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/admin/kontak/$id'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (_isHtml(res.body)) return {'success': false, 'message': 'Gagal menghapus pesan'};
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Ambil Daftar Pesan
  static Future<Map<String, dynamic>> getPesan() async {
    final token = await AuthService.getToken();
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/admin/kontak'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (_isHtml(res.body)) return {'success': false, 'message': 'Gagal mengambil pesan'};
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Ambil Daftar Warga
  static Future<Map<String, dynamic>> getWarga() async {
    final token = await AuthService.getToken();
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/admin/warga'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (_isHtml(res.body)) return {'success': false, 'message': 'Gagal mengambil data warga'};
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Hapus Warga
  static Future<Map<String, dynamic>> deleteWarga(int id) async {
    final token = await AuthService.getToken();
    try {
      final res = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/admin/warga/$id'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (_isHtml(res.body)) return {'success': false, 'message': 'Gagal menghapus warga'};
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
