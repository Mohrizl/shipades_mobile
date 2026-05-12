import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/surat_service.dart';
import '../../models/surat_model.dart';
import '../../config/api_config.dart';

class StatusScreen extends StatefulWidget {
  const StatusScreen({super.key});
  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  List<SuratModel> _list = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _downloadFile(String? path) async {
    if (path == null || path.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File tidak tersedia')),
      );
      return;
    }

    // Gunakan helper dari model untuk standarisasi URL
    final String urlStr = SuratModel.getFullUrl(path);
    
    final Uri url = Uri.parse(urlStr);
    
    try {
      bool launched = await launchUrl(
        url, 
        mode: LaunchMode.externalApplication,
      );
      if (!launched) throw 'Could not launch $urlStr';
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuka file: $e')),
        );
      }
    }
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final items = await SuratService.getSuratSaya();
      if (mounted) {
        setState(() {
          _list = items;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _loading 
              ? const Center(child: CircularProgressIndicator()) 
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _list.isEmpty ? _buildEmpty() : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _list.length,
                    itemBuilder: (context, i) => _buildCard(_list[i]),
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity, padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 30),
      decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)]), borderRadius: BorderRadius.vertical(bottom: Radius.circular(32))),
      child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Status Pengajuan', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)), Text('Pantau progres pengajuan Anda', style: TextStyle(color: Colors.white70, fontSize: 13))]),
    );
  }

  Widget _buildCard(SuratModel s) {
    return InkWell(
      onTap: () => _showDetail(s),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(16), 
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(s.nomorPengajuan, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2E7D32))),
                _statusBadge(s.status),
              ],
            ),
            const SizedBox(height: 12),
            Text(s.jenisSurat, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Text(s.keperluan, style: const TextStyle(color: Colors.grey, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(s.tanggal, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                const Text('Lihat Detail >', style: TextStyle(color: Color(0xFF2E7D32), fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _showDetail(SuratModel s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Color(0xFFF4F7F6),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Detail Pengajuan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        _statusBadge(s.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(s.nomorPengajuan, style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
                    const Divider(height: 32),
                    
                    _detailItem('Jenis Surat', s.jenisSurat),
                    _detailItem('Keperluan', s.keperluan),
                    _detailItem('Tanggal Pengajuan', s.tanggal),
                    
                    if (s.status.toLowerCase() == 'ditolak' && s.catatanPetugas != null)
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red[100]!)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.red, size: 18),
                                SizedBox(width: 8),
                                Text('Alasan Ditolak:', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(s.catatanPetugas!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                          ],
                        ),
                      ),

                    const SizedBox(height: 24),
                    const Text('Dokumen Persyaratan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    _fileCard('Foto KTP', s.fotoKtp, Icons.badge_outlined),
                    _fileCard('Dokumen Pendukung', s.dokumenPendukung, Icons.file_present_rounded),
                    
                    if (s.status.toLowerCase() == 'selesai' || (s.fileSurat != null && s.fileSurat!.isNotEmpty)) ...[
                      const SizedBox(height: 24),
                      const Text('Hasil Pengajuan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white, 
                          borderRadius: BorderRadius.circular(16), 
                          border: Border.all(color: Colors.green[200]!),
                          boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.05), blurRadius: 10)]
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.description_rounded, color: Colors.green, size: 30),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Surat Resmi Terbit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  Text(s.nomorPengajuan, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => _downloadFile(s.fileSurat),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                elevation: 0,
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.download_rounded, size: 16),
                                  SizedBox(width: 4),
                                  Text('Unduh', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _fileCard(String label, String? path, IconData icon) {
    bool hasFile = path != null && path.isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
      child: ListTile(
        leading: Icon(icon, color: hasFile ? const Color(0xFF2E7D32) : Colors.grey),
        title: Text(label, style: const TextStyle(fontSize: 14)),
        subtitle: Text(hasFile ? 'Lihat Dokumen' : 'Tidak ada dokumen', style: TextStyle(fontSize: 11, color: hasFile ? const Color(0xFF2E7D32) : Colors.grey)),
        trailing: hasFile ? const Icon(Icons.chevron_right, size: 18) : null,
        onTap: hasFile ? () => _downloadFile(path) : null,
      ),
    );
  }

  Widget _statusBadge(String s) {
    String displayStatus = s.toLowerCase() == 'pending' ? 'Menunggu' : (s[0].toUpperCase() + s.substring(1).toLowerCase());
    Color mainColor;
    Color bgColor;

    switch (s.toLowerCase()) {
      case 'pending':
      case 'menunggu':
        mainColor = const Color(0xFFF59E0B);
        bgColor = const Color(0xFFFEF3C7);
        displayStatus = 'Menunggu';
        break;
      case 'diproses':
        mainColor = const Color(0xFF3B82F6);
        bgColor = const Color(0xFFDBEAFE);
        break;
      case 'disetujui':
        mainColor = const Color(0xFF10B981);
        bgColor = const Color(0xFFD1FAE5);
        break;
      case 'ditolak':
        mainColor = const Color(0xFFEF4444);
        bgColor = const Color(0xFFFEE2E2);
        break;
      case 'selesai':
        mainColor = const Color(0xFF8B5CF6);
        bgColor = const Color(0xFFEDE9FE);
        break;
      default:
        mainColor = Colors.grey;
        bgColor = Colors.grey.withValues(alpha: 0.1);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: mainColor, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(displayStatus, style: TextStyle(color: mainColor, fontSize: 9, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.description_outlined, size: 60, color: Colors.grey[300]), const SizedBox(height: 16), const Text('Belum ada pengajuan', style: TextStyle(color: Colors.grey))]));
  }
}
