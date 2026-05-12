import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/notifikasi_model.dart';
import 'auth_service.dart';

class NotifService {
  static Future<List<NotifikasiModel>> getNotifikasi() async {
    final token = await AuthService.getToken();
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/notifikasi'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (res.body.startsWith('<!DOCTYPE') || res.body.startsWith('<html')) {
        return [];
      }

      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        final List? items = data['data'] is List 
            ? data['data'] 
            : (data['data']?['data'] as List?);
        return (items ?? []).map((e) => NotifikasiModel.fromJson(e)).toList();
      }
    } catch (e) {
      // Log error silently or use a logger
    }
    return [];
  }

  static Future<int> getUnreadCount() async {
    final notifs = await getNotifikasi();
    return notifs.where((n) => !n.dibaca).length;
  }

  static Future<void> tandaiBaca(int id) async {
    final token = await AuthService.getToken();
    try {
      await http.put(
        Uri.parse('${ApiConfig.baseUrl}/notifikasi/$id/baca'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
    } catch (e) {
      // Log error silently
    }
  }

  static Future<bool> hapusNotifikasi(int id) async {
    final token = await AuthService.getToken();
    try {
      final res = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/notifikasi/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200 || res.statusCode == 204) {
        final data = jsonDecode(res.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}