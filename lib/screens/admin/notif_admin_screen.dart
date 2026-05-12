import 'package:flutter/material.dart';
import '../../services/notif_service.dart';
import '../../models/notifikasi_model.dart';

class NotifAdminScreen extends StatefulWidget {
  const NotifAdminScreen({super.key});
  @override
  State<NotifAdminScreen> createState() => _NotifAdminScreenState();
}

class _NotifAdminScreenState extends State<NotifAdminScreen> {
  List<NotifikasiModel> _list = [];
  bool _loading = true;
  bool _isSelecting = false;
  final Set<int> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final data = await NotifService.getNotifikasi();
      if (mounted) {
        setState(() {
          _list = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteNotif(int id) async {
    final success = await NotifService.hapusNotifikasi(id);
    if (success) {
      await _load(); // Reload dari server untuk memastikan sinkronisasi
    }
  }

  Future<void> _deleteSelected() async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Notifikasi'),
        content: Text('Hapus ${_selectedIds.length} notifikasi terpilih?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (confirm) {
      setState(() => _loading = true);
      // Hapus secara paralel dan tunggu semua selesai
      await Future.wait(_selectedIds.map((id) => NotifService.hapusNotifikasi(id)));
      _selectedIds.clear();
      _isSelecting = false;
      await _load();
    }
  }

  Color _tipeColor(String tipe) {
    if (tipe.toLowerCase().contains('pesan')) return Colors.blue;
    return Colors.green;
  }

  IconData _tipeIcon(String tipe) {
    if (tipe.toLowerCase().contains('pesan')) return Icons.mail_outline;
    return Icons.assignment_outlined;
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
              gradient: LinearGradient(colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)]),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_isSelecting ? '${_selectedIds.length} Terpilih' : 'Notifikasi Admin', 
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    Text(_isSelecting ? 'Pilih notifikasi untuk dihapus' : 'Laporan pengajuan masuk dari warga', 
                      style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
                Row(
                  children: [
                    if (_list.isNotEmpty)
                      IconButton(
                        onPressed: () => setState(() => _isSelecting = !_isSelecting),
                        icon: Icon(_isSelecting ? Icons.close : Icons.edit_note, color: Colors.white),
                      ),
                    if (_isSelecting)
                      IconButton(
                        onPressed: _selectedIds.isEmpty ? null : _deleteSelected,
                        icon: const Icon(Icons.delete_sweep, color: Colors.white),
                      ),
                    if (!_isSelecting)
                      IconButton(onPressed: _load, icon: const Icon(Icons.refresh, color: Colors.white)),
                  ],
                )
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _list.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _list.length,
                            itemBuilder: (_, i) => _buildNotifCard(_list[i]),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotifCard(NotifikasiModel n) {
    bool isSelected = _selectedIds.contains(n.id);
    return Dismissible(
      key: Key('admin_notif_${n.id}'),
      direction: _isSelecting ? DismissDirection.none : DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (direction) => _deleteNotif(n.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? const Color(0xFF2E7D32) : Colors.transparent),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: _isSelecting 
            ? Checkbox(
                value: isSelected,
                onChanged: (val) {
                  setState(() {
                    if (val!) {
                      _selectedIds.add(n.id);
                    } else {
                      _selectedIds.remove(n.id);
                    }
                  });
                },
                activeColor: const Color(0xFF2E7D32),
              )
            : Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: _tipeColor(n.tipe).withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(_tipeIcon(n.tipe), color: _tipeColor(n.tipe), size: 20),
              ),
          title: Text(n.judul, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(n.pesan, style: const TextStyle(fontSize: 12, color: Colors.black87)),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 12, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(n.tanggal, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ],
          ),
          onLongPress: () {
            setState(() {
              _isSelecting = true;
              _selectedIds.add(n.id);
            });
          },
          onTap: () {
            if (_isSelecting) {
              setState(() {
                if (isSelected) {
                  _selectedIds.remove(n.id);
                  if (_selectedIds.isEmpty) _isSelecting = false;
                } else {
                  _selectedIds.add(n.id);
                }
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('Belum ada notifikasi', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
