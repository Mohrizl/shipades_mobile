import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/surat_service.dart';
import 'dart:io';

class AjukanScreen extends StatefulWidget {
  final VoidCallback? onSuccess;
  const AjukanScreen({super.key, this.onSuccess});
  @override
  State<AjukanScreen> createState() => _AjukanScreenState();
}

class _AjukanScreenState extends State<AjukanScreen> {
  final _keperluanC = TextEditingController();
  List<Map<String, dynamic>> _jenisSurat = [];
  String? _selectedJenis;
  File? _fotoKtp;
  File? _dokumenPendukung;
  bool _loading = false, _loadingJenis = true;

  @override
  void initState() {
    super.initState();
    _loadJenis();
  }

  Future<void> _loadJenis() async {
    try {
      final data = await SuratService.getJenisSurat();
      if (mounted) {
        setState(() {
          _jenisSurat = data;
          _loadingJenis = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingJenis = false);
      }
    }
  }

  Future<void> _pickKtp() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Pilih Sumber Foto',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPickerOption(
                  icon: Icons.camera_alt_rounded,
                  label: 'Kamera',
                  onTap: () => _handlePick(ImageSource.camera),
                  color: Colors.blue,
                ),
                _buildPickerOption(
                  icon: Icons.photo_library_rounded,
                  label: 'Galeri',
                  onTap: () => _handlePick(ImageSource.gallery),
                  color: Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Future<void> _handlePick(ImageSource source) async {
    final img = await ImagePicker().pickImage(
      source: source,
      imageQuality: 50,
    );
    if (img != null) {
      setState(() => _fotoKtp = File(img.path));
    }
  }

  Future<void> _pickDokumen() async {
    final result = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'png']);
    if (result != null) setState(() => _dokumenPendukung = File(result.files.single.path!));
  }

  Future<void> _submit() async {
    if (_selectedJenis == null || _keperluanC.text.isEmpty || _fotoKtp == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lengkapi semua field dan foto KTP'), backgroundColor: Colors.orange));
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await SuratService.ajukanSurat(
        jenisSuratId: _selectedJenis!,
        keperluan: _keperluanC.text,
        fotoKtpPath: _fotoKtp!.path,
        dokumenPendukungPath: _dokumenPendukung?.path,
      );
      if (!mounted) return;
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Surat berhasil diajukan!'), backgroundColor: Colors.green));
        
        // Reset Form
        setState(() {
          _keperluanC.clear();
          _selectedJenis = null;
          _fotoKtp = null;
          _dokumenPendukung = null;
          _loading = false;
        });

        if (widget.onSuccess != null) {
          widget.onSuccess!();
        }
      } else {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Gagal mengajukan surat'), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error koneksi ke server'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingJenis) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32))),
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Pengajuan Baru', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Silakan pilih jenis surat dan lengkapi persyaratan yang diperlukan.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 32),
            
            // Pilih Jenis Surat
            const Text('Jenis Surat *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedJenis,
              decoration: InputDecoration(
                hintText: 'Pilih jenis surat...',
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
              ),
              items: _jenisSurat.map((j) => DropdownMenuItem(
                  value: j['id'].toString(), child: Text(j['nama']))).toList(),
              onChanged: (v) => setState(() => _selectedJenis = v),
            ),
            
            const SizedBox(height: 20),
            
            // Keperluan
            const Text('Keperluan *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
            const SizedBox(height: 8),
            TextField(
              controller: _keperluanC,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Tuliskan alasan/tujuan pengajuan surat...',
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Foto KTP
            const Text('Foto KTP *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickKtp,
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border.all(color: Colors.grey[200]!),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _fotoKtp != null
                    ? Stack(
                        children: [
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(_fotoKtp!, fit: BoxFit.cover),
                            ),
                          ),
                          Positioned(
                            right: 8, top: 8,
                            child: CircleAvatar(
                              backgroundColor: Colors.white,
                              radius: 15,
                              child: IconButton(
                                icon: const Icon(Icons.close, size: 15, color: Colors.red),
                                onPressed: () => setState(() => _fotoKtp = null),
                              ),
                            ),
                          )
                        ],
                      )
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt_outlined, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text('Ambil Foto KTP', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text('Pastikan data terlihat jelas', style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Dokumen Pendukung
            const Text('Dokumen Pendukung (PDF/JPG)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDokumen,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.05),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.attach_file, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _dokumenPendukung != null
                            ? _dokumenPendukung!.path.split('/').last
                            : 'Pilih file pendukung jika ada...',
                        style: TextStyle(
                          color: _dokumenPendukung != null ? Colors.blue : Colors.grey[600],
                          fontSize: 13,
                          fontWeight: _dokumenPendukung != null ? FontWeight.bold : FontWeight.normal
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Submit Button
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _loading
                  ? const SizedBox(height: 20, width: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Kirim Pengajuan Sekarang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
