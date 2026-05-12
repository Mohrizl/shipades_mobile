import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';

class AuthService {
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode != 200 && res.statusCode != 201) {
        try {
          final errorData = jsonDecode(res.body);
          return {'success': false, 'message': errorData['message'] ?? 'Login gagal (${res.statusCode})'};
        } catch (_) {
          return {'success': false, 'message': 'Terjadi kesalahan server (${res.statusCode})'};
        }
      }

      final responseData = jsonDecode(res.body);
      if (responseData['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        final data = responseData['data'];
        if (data != null) {
          await prefs.setString('token', data['token'].toString());
          await prefs.setString('user', jsonEncode(data['user']));
        }
      }
      return responseData;
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> body) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final Map<String, String> payload = {
        'name': body['name'] ?? body['nama'] ?? '',
        'phone': body['phone'] ?? body['telepon'] ?? '',
        'address': body['address'] ?? body['alamat'] ?? '',
      };

      final url = '${ApiConfig.baseUrl}/auth/profile';

      final res = await http.put(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));

      final responseData = jsonDecode(res.body);

      if (res.statusCode == 200 && responseData['success'] == true) {
        final userStr = prefs.getString('user');
        if (userStr != null) {
          final userData = jsonDecode(userStr);
          userData['name'] = payload['name'];
          userData['phone'] = payload['phone'];
          userData['address'] = payload['address'];
          await prefs.setString('user', jsonEncode(userData));
        }
        return {'success': true, 'message': responseData['message'] ?? 'Profil berhasil diperbarui'};
      }

      return {
        'success': false,
        'message': responseData['message'] ?? 'Gagal memperbarui profil'
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan koneksi atau timeout.'};
    }
  }

  static Future<Map<String, dynamic>> changePassword(String current, String newPass) async {
    try {
      final token = await getToken();
      final res = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/auth/change-password'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: jsonEncode({
          'old_password': current,
          'new_password': newPass,
        }),
      ).timeout(const Duration(seconds: 10));

      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Gagal mengubah password: $e'};
    }
  }

  static Future<Map<String, dynamic>> register(Map<String, dynamic> body) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/register'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode(body),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<String?> getToken() async => (await SharedPreferences.getInstance()).getString('token');

  static Future<UserModel?> getUser() async {
    final str = (await SharedPreferences.getInstance()).getString('user');
    return str != null ? UserModel.fromJson(jsonDecode(str)) : null;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
  }

  static Future<bool> isLoggedIn() async => (await getToken()) != null;
}
