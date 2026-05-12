import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nikC = TextEditingController();
  final _namaC = TextEditingController();
  final _emailC = TextEditingController();
  final _passC = TextEditingController();
  final _telponC = TextEditingController();
  final _alamatC = TextEditingController();
  bool _loading = false, _obscure = true;

  Future<void> _register() async {
    if (_nikC.text.isEmpty || _namaC.text.isEmpty ||
        _emailC.text.isEmpty || _passC.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Semua field wajib diisi')));
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await AuthService.register({
        'nik': _nikC.text.trim(),
        'name': _namaC.text.trim(), // Backend menggunakan 'name'
        'email': _emailC.text.trim(),
        'password': _passC.text,
        'phone': _telponC.text.trim(), // Backend menggunakan 'phone'
        'address': _alamatC.text.trim(), // Backend menggunakan 'address'
      });
      if (!mounted) return;
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registrasi berhasil! Silakan login'), backgroundColor: Colors.green));
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const LoginScreen()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Registrasi gagal'), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat terhubung ke server'), backgroundColor: Colors.red));
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Buat Akun Baru', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Silakan lengkapi data diri Anda untuk menggunakan layanan kependudukan digital.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 32),
            _buildSectionTitle('Informasi Login'),
            const SizedBox(height: 12),
            _buildField(_emailC, 'Email', Icons.email_outlined, type: TextInputType.emailAddress),
            const SizedBox(height: 16),
            TextField(
              controller: _passC,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF2E7D32)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
                ),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildSectionTitle('Data Kependudukan'),
            const SizedBox(height: 12),
            _buildField(_nikC, 'NIK (Sesuai KTP)', Icons.badge_outlined, type: TextInputType.number),
            const SizedBox(height: 16),
            _buildField(_namaC, 'Nama Lengkap', Icons.person_outline),
            const SizedBox(height: 16),
            _buildField(_telponC, 'Nomor Telepon/WA', Icons.phone_android_outlined, type: TextInputType.phone),
            const SizedBox(height: 16),
            TextField(
              controller: _alamatC,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Alamat Lengkap',
                alignLabelWithHint: true,
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 40),
                  child: Icon(Icons.home_outlined, color: Color(0xFF2E7D32)),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: _loading
                    ? const SizedBox(height: 20, width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Daftar Sekarang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Sudah punya akun?'),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Masuk di sini', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
    );
  }

  Widget _buildField(TextEditingController c, String label, IconData icon,
      {TextInputType? type}) {
    return TextField(
      controller: c,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF2E7D32)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
        ),
      ),
    );
  }
}
