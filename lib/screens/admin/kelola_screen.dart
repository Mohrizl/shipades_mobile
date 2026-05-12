import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/admin_service.dart';
import '../../config/api_config.dart';
import '../../models/surat_model.dart';
import 'package:url_launcher/url_launcher.dart';

class KelolaScreen extends StatefulWidget {
  const KelolaScreen({super.key});
  @override
  State<KelolaScreen> createState() => _KelolaScreenState();
}

class _KelolaScreenState extends State<KelolaScreen> {
  List<SuratModel> _list = [];
  bool _loading = true;
  String _currentFilter = 'Semua';
  final List<String> _filters = ['Semua', 'Menunggu', 'Diproses', 'Disetujui', 'Selesai', 'Ditolak'];

  String _getUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final baseUrl = ApiConfig.baseUrl.split('/api')[0];
    String cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return cleanPath.contains('uploads/') || cleanPath.contains('storage/') 
        ? '$baseUrl/$cleanPath' 
        : '$baseUrl/uploads/$cleanPath';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      String? filterStatus;
      if (_currentFilter != 'Semua') {
        filterStatus = _currentFilter.toLowerCase();
        if (filterStatus == 'menunggu') filterStatus = 'pending';
      }
      final res = await AdminService.getAllSurat(status: filterStatus);
      if (res['success'] == true) {
        var content = res['data'];
        List items = [];
        if (content is List) {
          items = content;
        } else if (content is Map) {
          items = content['data'] ?? content['results'] ?? content['items'] ?? [];
        }
        setState(() => _list = items.map((e) => SuratModel.fromJson(e)).toList());
      }
    } catch (e) {
      debugPrint("Error load data: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(int id, String status) async {
    if (status == 'diproses') {
      final res = await AdminService.updateStatus(id, status, "");
      if (!context.mounted) return;
      if (res['success'] == true) {
        // Tutup modal detail agar tidak stale
        if (Navigator.canPop(context)) Navigator.pop(context);
        _load();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status berhasil diperbarui'), backgroundColor: Colors.green));
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: ${res['message']}'), backgroundColor: Colors.red));
      }
      return;
    }

    if (status == 'ditolak') {
      _showTolakDialog(id);
    } else if (status == 'disetujui') {
      _showSetujuiDialog(id);
    }
  }

  Future<void> _showTolakDialog(int id) async {
    final catatanC = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Tolak Pengajuan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, size: 18), color: Colors.grey),
          ],
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Berikan alasan penolakan yang jelas agar warga dapat memperbaiki pengajuannya.', style: TextStyle(fontSize: 13, color: Colors.black54)),
            const SizedBox(height: 16),
            const Text('Alasan Penolakan *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: catatanC,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Tuliskan alasan penolakan...',
                hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFFF1F8E9).withValues(alpha: 0.5),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(0, 0, 24, 16),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
          ElevatedButton.icon(
            onPressed: () async {
              if (catatanC.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alasan penolakan wajib diisi')));
                return;
              }
              Navigator.pop(context);
              _handleUpdateStatus(id, 'ditolak', catatanC.text);
            },
            icon: const Icon(Icons.close, size: 16, color: Colors.white),
            label: const Text('Tolak', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0),
          ),
        ],
      ),
    );
  }

  Future<void> _showSetujuiDialog(int id) async {
    final catatanC = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Setujui Pengajuan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, size: 18), color: Colors.grey),
          ],
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pengajuan akan disetujui dan warga akan mendapat notifikasi.', style: TextStyle(fontSize: 13, color: Colors.black54)),
            const SizedBox(height: 16),
            const Text('Catatan Admin (opsional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: catatanC,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Tambahkan catatan untuk warga...',
                hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFFF1F8E9).withValues(alpha: 0.5),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(0, 0, 24, 16),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              _handleUpdateStatus(id, 'disetujui', catatanC.text);
            },
            icon: const Icon(Icons.check, size: 16, color: Colors.white),
            label: const Text('Setujui', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0),
          ),
        ],
      ),
    );
  }

  Future<void> _handleUpdateStatus(int id, String status, String catatan) async {
    final res = await AdminService.updateStatus(id, status, catatan);
    if (!context.mounted) return;
    if (res['success'] == true) {
      // Tutup modal detail
      if (Navigator.canPop(context)) Navigator.pop(context);
      _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status berhasil diperbarui'), backgroundColor: Colors.green));
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: ${res['message']}'), backgroundColor: Colors.red));
    }
  }

  Future<void> _showTerbitkanDialog(int id) async {
    final catatanC = TextEditingController();
    String? filePath;
    String? fileName;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Terbitkan Surat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, size: 18), color: Colors.grey),
            ],
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Upload file surat resmi (PDF) yang sudah ditandatangani. Nomor surat dibuat otomatis.', style: TextStyle(fontSize: 13, color: Colors.black54)),
                const SizedBox(height: 16),
                const Text('Upload File Surat *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    FilePickerResult? result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['pdf', 'doc', 'docx'],
                    );
                    if (result != null) {
                      setDialogState(() {
                        filePath = result.files.single.path;
                        fileName = result.files.single.name;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
                          child: const Text('Choose File', style: TextStyle(fontSize: 12)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(fileName ?? 'No file chosen', style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Text('Format: PDF, DOC, DOCX. Maks 5MB', style: TextStyle(fontSize: 10, color: Colors.green)),
                const SizedBox(height: 16),
                const Text('Keterangan Tambahan (opsional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                TextField(
                  controller: catatanC,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Keterangan tambahan...',
                    hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFFF1F8E9).withValues(alpha: 0.5),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(0, 0, 24, 16),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
            ElevatedButton.icon(
              onPressed: () async {
                if (filePath == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File surat wajib dipilih')));
                  return;
                }
                Navigator.pop(context);
                if (!context.mounted) return;
                final res = await AdminService.terbitkanSurat(id, filePath!, catatanC.text.isEmpty ? "Surat resmi telah diterbitkan" : catatanC.text);
                if (!context.mounted) return;
                if (res['success'] == true) {
                  // Tutup Modal Detail yang ada di belakang dialog ini
                  if (Navigator.canPop(context)) Navigator.pop(context);
                  
                  _load(); // Refresh daftar utama
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Surat Berhasil Diterbitkan!'), backgroundColor: Colors.green));
                } else {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: ${res['message']}'), backgroundColor: Colors.red));
                }
              },
              icon: const Icon(Icons.print, size: 16, color: Colors.white),
              label: const Text('Terbitkan', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0),
            ),
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
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Detail Pengajuan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const Divider(),
            Expanded(
              child: ListView(
                children: [
                  _buildDetailItem('Nama Warga', s.namaWarga),
                  _buildDetailItem('NIK', s.nikWarga),
                  _buildDetailItem('Jenis Surat', s.jenisSurat),
                  _buildDetailItem('Keperluan', s.keperluan),
                  _buildDetailItem('Tanggal', s.tanggal),
                  const SizedBox(height: 20),
                  const Text('Lampiran KTP:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  _buildImagePreview(s.fotoKtp),
                  const SizedBox(height: 20),
                  const Text('Dokumen Pendukung:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  _buildDocPreview(s.dokumenPendukung),
                  
                  if (s.fileSurat != null || s.status.toLowerCase() == 'selesai') ...[
                    const Divider(height: 40),
                    const Text('Surat Resmi Diterbitkan:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2E7D32))),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.3))),
                      child: Row(
                        children: [
                          const Icon(Icons.picture_as_pdf, color: Color(0xFF2E7D32)),
                          const SizedBox(width: 12),
                          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('File Surat Resmi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), Text('Klik untuk mengecek kembali file', style: TextStyle(fontSize: 11, color: Colors.grey))])),
                          if (s.fileSurat != null && s.fileSurat!.isNotEmpty)
                            ElevatedButton(
                              onPressed: () => launchUrl(Uri.parse(SuratModel.getFullUrl(s.fileSurat)), mode: LaunchMode.externalApplication),
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                              child: const Text('Cek File', style: TextStyle(fontSize: 11)),
                            )
                          else
                            const Text('File tidak tersedia', style: TextStyle(color: Colors.red, fontSize: 10)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildActionButtons(s),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(SuratModel s) {
    final status = s.status.toLowerCase();
    
    return Row(
      children: [
        if (status == 'pending')
          Expanded(child: ElevatedButton(onPressed: () => _updateStatus(s.id, 'diproses'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text('Proses', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)))),
        
        if (status == 'diproses') ...[
          Expanded(
            child: OutlinedButton(
              onPressed: () => _showTolakDialog(s.id),
              style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFEF4444), side: const BorderSide(color: Color(0xFFEF4444)), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: const Text('Tolak'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _showSetujuiDialog(s.id),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: const Text('Setujui', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],

        if (status == 'disetujui')
          Expanded(child: ElevatedButton.icon(onPressed: () => _showTerbitkanDialog(s.id), icon: const Icon(Icons.print, color: Colors.white, size: 18), label: const Text('Terbitkan Surat Resmi', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))))),
      ],
    );
  }

  Widget _buildImagePreview(String? filename) {
    if (filename == null || filename.isEmpty) return Container(height: 150, decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)), child: const Center(child: Text('Tidak ada lampiran KTP')));
    
    String url = SuratModel.getFullUrl(filename);
    
    return InkWell(
      onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          url, height: 200, width: double.infinity, fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            height: 150, 
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)), 
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.broken_image, color: Colors.grey, size: 40),
                const SizedBox(height: 8),
                Text('Gagal memuat gambar', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                TextButton(onPressed: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication), child: const Text('Buka via Browser', style: TextStyle(fontSize: 11)))
              ],
            )
          ),
        ),
      ),
    );
  }

  Widget _buildDocPreview(String? filename) {
    if (filename == null || filename.isEmpty) return const Text('Tidak ada dokumen pendukung', style: TextStyle(color: Colors.grey, fontSize: 12));
    String url = SuratModel.getFullUrl(filename);
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication), 
        icon: const Icon(Icons.file_present), 
        label: const Text('Buka Dokumen'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.green[800],
          side: BorderSide(color: Colors.green[800]!),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)), Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))]));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      body: Column(
        children: [
          _buildHeader(),
          _buildFilterChips(),
          Expanded(
            child: _loading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(onRefresh: _load, child: _list.isEmpty ? _buildEmptyState() : ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 20), itemCount: _list.length, itemBuilder: (_, i) => _buildCard(_list[i]))),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(width: double.infinity, padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 30), decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)]), borderRadius: BorderRadius.vertical(bottom: Radius.circular(32))), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Kelola Pengajuan', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)), Text('Verifikasi dan proses dokumen warga', style: TextStyle(color: Colors.white70, fontSize: 13))]));
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.all(16), child: Row(children: _filters.map((f) => Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(f, style: TextStyle(color: _currentFilter == f ? Colors.white : Colors.black87, fontSize: 12)), selected: _currentFilter == f, selectedColor: const Color(0xFF2E7D32), onSelected: (v) { setState(() => _currentFilter = f); _load(); }))).toList()));
  }

  Widget _buildCard(SuratModel s) {
    return InkWell(
      onTap: () => _showDetail(s), 
      child: Container(
        margin: const EdgeInsets.only(bottom: 16), 
        padding: const EdgeInsets.all(16), 
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]), 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, 
              children: [
                Text(s.nomorPengajuan, style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 12)), 
                _buildBadge(s.status)
              ]
            ), 
            const SizedBox(height: 12), 
            Text(s.namaWarga, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), 
            if (s.nikWarga != '-' && s.nikWarga.isNotEmpty)
              Text(s.nikWarga, style: const TextStyle(color: Colors.grey, fontSize: 12)), 
            Text(s.jenisSurat, style: const TextStyle(color: Colors.grey, fontSize: 12)), 
            const Divider(height: 24), 
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Diajukan: ${s.tanggal}', style: const TextStyle(fontSize: 11, color: Colors.grey)), const Icon(Icons.chevron_right, size: 16, color: Colors.grey)])
          ]
        )
      )
    );
  }

  Widget _buildBadge(String s) {
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

  Widget _buildEmptyState() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.assignment_outlined, size: 60, color: Colors.grey), const SizedBox(height: 16), const Text('Tidak ada pengajuan', style: TextStyle(color: Colors.grey))]));
  }
}
