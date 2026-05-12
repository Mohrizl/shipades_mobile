import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import 'package:intl/intl.dart';

class PesanScreen extends StatefulWidget {
  const PesanScreen({super.key});
  @override
  State<PesanScreen> createState() => _PesanScreenState();
}

class _PesanScreenState extends State<PesanScreen> {
  List _list = [];
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
      final res = await AdminService.getPesan();
      if (res['success'] == true) {
        if (mounted) {
          setState(() {
            _list = res['data'] ?? [];
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteSelected() async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Pesan'),
        content: Text('Hapus ${_selectedIds.length} pesan terpilih?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (confirm) {
      for (int id in _selectedIds) {
        await AdminService.deletePesan(id);
      }
      setState(() {
        _list.removeWhere((p) => _selectedIds.contains(p['id']));
        _selectedIds.clear();
        _isSelecting = false;
      });
    }
  }

  void _showReply(Map pesan) {
    final replyC = TextEditingController(text: pesan['balasan'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 20, left: 20, right: 20
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Detail Pesan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const Divider(),
              Text('Dari: ${pesan['nama']}', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(pesan['email'] ?? '-', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 12),
              const Text('Subjek:', style: TextStyle(fontSize: 11, color: Colors.grey)),
              Text(pesan['subjek'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              const Text('Pesan:', style: TextStyle(fontSize: 11, color: Colors.grey)),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                child: Text(pesan['pesan'] ?? ''),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: replyC,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Balas Pesan',
                  hintText: 'Tulis balasan di sini...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              StatefulBuilder(
                builder: (context, setModalState) {
                  bool isSending = false;
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSending ? null : () async {
                        if (replyC.text.trim().isEmpty) return;
                        setModalState(() => isSending = true);
                        try {
                          final res = await AdminService.balasPesan(
                            int.parse(pesan['id'].toString()), 
                            replyC.text.trim()
                          );
                          
                          if (res['success'] == true) {
                            if (!mounted) return;
                            Navigator.pop(context);
                            _load();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Balasan berhasil dikirim'), backgroundColor: Colors.green),
                            );
                          } else {
                            // INI PERINTAHNYA: Menampilkan pesan error asli dari server
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('GAGAL DARI SERVER: ${res['message']}'), 
                                  backgroundColor: Colors.red,
                                  duration: const Duration(seconds: 8),
                                  action: SnackBarAction(label: 'OKE', textColor: Colors.white, onPressed: () {}),
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Kesalahan Aplikasi: $e'), backgroundColor: Colors.orange),
                            );
                          }
                        } finally {
                          if (mounted) setModalState(() => isSending = false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isSending 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Kirim Balasan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  );
                }
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // This function is kept for potential future single-item delete UI
  // ignore: unused_element
  Future<void> _hapusPesan(int id) async {
    try {
      final res = await AdminService.deletePesan(id);
      if (res['success'] == true) {
        setState(() => _list.removeWhere((e) => e['id'] == id));
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pesan berhasil dihapus')));
      } else {
        throw res['message'] ?? 'Gagal menghapus';
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_isSelecting ? '${_selectedIds.length} Terpilih' : 'Pesan Masuk', 
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    Text(_isSelecting ? 'Pilih pesan untuk dihapus' : 'Aduan & Saran dari Warga', 
                      style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
                _isSelecting 
                ? Row(
                    children: [
                      IconButton(onPressed: () => setState(() { _isSelecting = false; _selectedIds.clear(); }), icon: const Icon(Icons.close, color: Colors.white)),
                      IconButton(onPressed: _selectedIds.isEmpty ? null : _deleteSelected, icon: const Icon(Icons.delete, color: Colors.white)),
                    ],
                  )
                : IconButton(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh, color: Colors.white),
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
                            itemBuilder: (_, i) {
                              final p = _list[i];
                              return _buildMessageCard(p);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard(Map p) {
    bool isReplied = p['balasan'] != null;
    bool isSelected = _selectedIds.contains(p['id']);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? Colors.green.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isSelected ? Border.all(color: const Color(0xFF2E7D32)) : null,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: _isSelecting
          ? Checkbox(
              value: isSelected,
              onChanged: (val) {
                setState(() {
                  if (val!) {
                    _selectedIds.add(p['id']);
                  } else {
                    _selectedIds.remove(p['id']);
                  }
                });
              },
              activeColor: const Color(0xFF2E7D32),
            )
          : CircleAvatar(
              backgroundColor: isReplied ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
              child: Icon(
                isReplied ? Icons.mark_email_read : Icons.mark_email_unread, 
                color: isReplied ? Colors.green : Colors.orange,
                size: 20,
              ),
            ),
        title: Text(p['subjek'] ?? 'No Subject', 
          style: TextStyle(fontWeight: isReplied ? FontWeight.normal : FontWeight.bold, fontSize: 15)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(p['nama'] ?? 'Anonim', style: const TextStyle(fontSize: 12, color: Colors.black87)),
            Text(p['pesan'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            if (p['created_at'] != null)
              Text(
                DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(p['created_at'])),
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
          ],
        ),
        trailing: !_isSelecting && isReplied 
          ? const Icon(Icons.check_circle, color: Colors.green, size: 18)
          : (!_isSelecting ? const Icon(Icons.chevron_right, color: Colors.grey) : null),
        onLongPress: () {
          setState(() {
            _isSelecting = true;
            _selectedIds.add(p['id']);
          });
        },
        onTap: () {
          if (_isSelecting) {
            setState(() {
              if (isSelected) {
                _selectedIds.remove(p['id']);
                if (_selectedIds.isEmpty) _isSelecting = false;
              } else {
                _selectedIds.add(p['id']);
              }
            });
          } else {
            _showReply(p);
          }
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mail_outline, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('Belum ada pesan masuk', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
