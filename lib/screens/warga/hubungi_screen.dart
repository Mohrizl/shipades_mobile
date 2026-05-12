import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/auth_service.dart';
import '../../config/api_config.dart';

class HubungiScreen extends StatefulWidget {
  const HubungiScreen({super.key});
  @override
  State<HubungiScreen> createState() => _HubungiScreenState();
}

class _HubungiScreenState extends State<HubungiScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaC = TextEditingController();
  final _emailC = TextEditingController();
  final _subjekC = TextEditingController();
  final _pesanC = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getUser();
    if (user != null) {
      _namaC.text = user.nama;
      _emailC.text = user.email;
    }
  }

  Future<void> _kirim() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    
    final token = await AuthService.getToken();
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/kontak'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'nama': _namaC.text,
          'email': _emailC.text,
          'subjek': _subjekC.text,
          'pesan': _pesanC.text,
        }),
      );
      
      if (res.body.startsWith('<!DOCTYPE')) {
        throw 'Server error: Terjadi kesalahan pada server (HTML response).';
      }

      final data = jsonDecode(res.body);
      if (!mounted) return;
      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pesan berhasil dikirim!'), backgroundColor: Colors.green),
        );
        _subjekC.clear();
        _pesanC.clear();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim pesan: $e'), backgroundColor: Colors.red),
      );
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 30),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hubungi Admin', 
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      Text('Kirimkan pertanyaan atau keluhan Anda', 
                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                  Icon(Icons.support_agent, color: Colors.white, size: 40),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Form Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15)],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.edit_note, color: Color(0xFF2E7D32)),
                              SizedBox(width: 8),
                              Text('Kirim Pesan Baru', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                          const Divider(height: 32),
                          _buildField('Nama Lengkap', _namaC, Icons.person_outline, readOnly: true),
                          const SizedBox(height: 16),
                          _buildField('Email', _emailC, Icons.email_outlined, readOnly: true),
                          const SizedBox(height: 16),
                          _buildField('Subjek', _subjekC, Icons.topic_outlined, hint: 'Contoh: Cara mengajukan surat'),
                          const SizedBox(height: 16),
                          _buildField('Pesan', _pesanC, Icons.chat_bubble_outline, hint: 'Tulis pesan Anda...', maxLines: 4),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _loading ? null : _kirim,
                              icon: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.send),
                              label: const Text('Kirim Pesan', style: TextStyle(fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Info Cards
                  _buildContactInfo('Alamat Kantor Desa', 'Jl. Raya Sini No. 1, Kec. Sini, Kab. Tasik 44194', Icons.location_on_outlined),
                  const SizedBox(height: 12),
                  _buildContactInfo('Jam Pelayanan', 'Senin - Jumat: 08.00 - 16.00 WIB\nSabtu: 08.00 - 12.00 WIB', Icons.access_time),
                  const SizedBox(height: 12),
                  _buildContactInfo('Nomor Telepon', '(0262) 123-4567', Icons.phone_outlined),
                  const SizedBox(height: 12),
                  _buildContactInfo('Email Resmi', 'admin@desasini.id', Icons.mail_outline),

                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Color(0xFF2E7D32), size: 20),
                        SizedBox(width: 12),
                        Expanded(child: Text('Pesan akan dibalas dalam 1x24 jam hari kerja. Balasan tampil di bagian notifikasi.', style: TextStyle(fontSize: 12, color: Color(0xFF1B5E20)))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, {bool readOnly = false, String? hint, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          maxLines: maxLines,
          validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.grey),
            filled: true,
            fillColor: readOnly ? Colors.grey[100] : Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2E7D32))),
          ),
        ),
      ],
    );
  }

  Widget _buildContactInfo(String title, String desc, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[200]!)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: const Color(0xFF2E7D32), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(desc, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
