import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../models/user_model.dart';

class WargaScreen extends StatefulWidget {
  const WargaScreen({super.key});
  @override
  State<WargaScreen> createState() => _WargaScreenState();
}

class _WargaScreenState extends State<WargaScreen> {
  List<UserModel> _list = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final res = await AdminService.getWarga();
      if (res['success'] == true) {
        var items = res['data'];
        if (items is Map && items.containsKey('data')) {
          items = items['data'];
        }
        final List listData = items ?? [];
        setState(() => _list = listData.map((e) => UserModel.fromJson(e)).toList());
      }
    } catch (e) {
      debugPrint("Error load warga: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _hapusWarga(int id) async {
    try {
      final res = await AdminService.deleteWarga(id);
      if (res['success'] == true) {
        setState(() => _list.removeWhere((e) => e.id == id));
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data warga berhasil dihapus')));
      } else {
        throw res['message'] ?? 'Gagal menghapus';
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menghapus data warga')));
    }
  }

  void _showDetail(UserModel w) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Detail Warga', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const Divider(),
            Expanded(
              child: ListView(
                children: [
                  _buildDetailItem('Nama Lengkap', w.nama),
                  _buildDetailItem('NIK', w.nik),
                  _buildDetailItem('Nomor Telepon', w.telepon),
                  _buildDetailItem('Email', w.email),
                  _buildDetailItem('Alamat', w.alamat),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      body: Column(
        children: [
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Data Warga', 
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    Text('Kelola informasi penduduk desa', 
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
                IconButton(onPressed: _load, icon: const Icon(Icons.refresh, color: Colors.white)),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _list.isEmpty 
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _list.length,
                        itemBuilder: (_, i) {
                          final w = _list[i];
                          return _buildWargaCard(w);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildWargaCard(UserModel w) {
    return Dismissible(
      key: Key(w.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Hapus Data'),
            content: Text('Apakah Anda yakin ingin menghapus data ${w.nama}?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
            ],
          ),
        );
      },
      onDismissed: (direction) => _hapusWarga(w.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: CircleAvatar(
            backgroundColor: const Color(0xFF2E7D32).withValues(alpha: 0.1),
            child: const Icon(Icons.person, color: Color(0xFF2E7D32)),
          ),
          title: Text(w.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('NIK: ${w.nik}', style: const TextStyle(fontSize: 12)),
              Text('Telp: ${w.telepon}', style: const TextStyle(fontSize: 12)),
            ],
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          onTap: () => _showDetail(w),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('Belum ada data warga', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
