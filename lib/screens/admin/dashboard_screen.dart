import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/auth_service.dart';
import '../../services/admin_service.dart';
import '../login_screen.dart';
import 'kelola_screen.dart';
import 'pesan_screen.dart';
import 'warga_screen.dart';
import 'package:intl/intl.dart';
import '../../models/surat_model.dart';
import '../../services/notif_service.dart';
import 'notif_admin_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  Map<String, dynamic> _stats = {};
  List<SuratModel> _latestSubmissions = [];
  bool _loading = true;
  int _unreadNotif = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadNotifCount();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadData();
      _loadNotifCount();
    });
  }

  Future<void> _loadNotifCount() async {
    final count = await NotifService.getUnreadCount();
    if (mounted) setState(() => _unreadNotif = count);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final res = await AdminService.getDashboard();
      if (mounted && res['success'] == true) {
        final content = res['data'];
        setState(() {
          _stats = content['stats'] ?? {};
          
          final List listData = content['recent'] ?? [];
          // BATASI CUMA 3 ITEM SAJA
          _latestSubmissions = listData
              .take(3)
              .map((e) => SuratModel.fromJson(Map<String, dynamic>.from(e)))
              .toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar dari mode Admin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Keluar', style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await AuthService.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _DashboardTab(
        stats: _stats, 
        latest: _latestSubmissions, 
        loading: _loading, 
        unreadNotif: _unreadNotif,
        onRefresh: () async {
          await _loadData();
          await _loadNotifCount();
        },
      ), 
      const KelolaScreen(), 
      const WargaScreen(),
      const PesanScreen()
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: const Color(0xFF2E7D32),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_rounded), label: 'Kelola'),
          BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: 'Warga'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_rounded), label: 'Pesan'),
        ],
      ),
      floatingActionButton: _currentIndex == 0 ? FloatingActionButton(
        onPressed: _logout,
        backgroundColor: Colors.redAccent,
        mini: true,
        child: const Icon(Icons.power_settings_new, color: Colors.white),
      ) : null,
    );
  }
}

class _DashboardTab extends StatelessWidget {
  final Map<String, dynamic> stats;
  final List<SuratModel> latest;
  final bool loading;
  final int unreadNotif;
  final Future<void> Function() onRefresh;
  const _DashboardTab({
    required this.stats, 
    required this.latest, 
    required this.loading, 
    required this.unreadNotif,
    required this.onRefresh
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            _buildHeader(context),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsGrid(),
                  const SizedBox(height: 32),
                  const Text('Pengajuan Terbaru', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (loading) const Center(child: CircularProgressIndicator())
                  else if (latest.isEmpty) _buildEmpty()
                  else ...latest.map((item) => _buildItem(context, item)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)]),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Dashboard Admin', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              // Tombol Notifikasi
              Stack(
                children: [
                  IconButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotifAdminScreen())),
                    icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 28),
                  ),
                  if (unreadNotif > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          unreadNotif > 9 ? '9+' : '$unreadNotif',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          Text(DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now()), style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _StatCard('Pending', '${stats['pending'] ?? 0}', const Color(0xFFF59E0B)),
        _StatCard('Diproses', '${stats['diproses'] ?? 0}', const Color(0xFF3B82F6)),
        _StatCard('Selesai', '${stats['selesai'] ?? 0}', const Color(0xFF8B5CF6)),
        _StatCard('Total', '${stats['total'] ?? 0}', const Color(0xFF10B981)),
      ],
    );
  }

  Widget _buildItem(BuildContext context, SuratModel item) {
    // Get initials for avatar
    String initials = "";
    if (item.namaWarga.isNotEmpty) {
      List<String> names = item.namaWarga.split(" ");
      initials = names[0][0].toUpperCase();
      if (names.length > 1) initials += names[1][0].toUpperCase();
    }

    // Get short code from jenis surat (e.g. SKU, SKTM)
    String shortCode = "SURAT";
    if (item.jenisSurat.contains("Usaha")) shortCode = "SKU";
    else if (item.jenisSurat.contains("Tidak Mampu")) shortCode = "SKTM";
    else if (item.jenisSurat.contains("Domisili")) shortCode = "SKD";
    else if (item.jenisSurat.contains("Penduduk")) shortCode = "SKPD";
    else if (item.jenisSurat.contains("Menikah")) shortCode = "SKM";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          // Avatar & Name
          Expanded(
            flex: 5,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFFE8F5E9),
                  child: Text(initials, style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 10)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(item.namaWarga, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis),
                      if (item.nikWarga != '-' && item.nikWarga.isNotEmpty)
                        Text(item.nikWarga, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Type
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(4)),
                  child: Text(shortCode, style: const TextStyle(color: Color(0xFF2E7D32), fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                Text(item.jenisSurat, style: const TextStyle(fontSize: 10, color: Colors.grey), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),

          // Date
          Expanded(
            flex: 3,
            child: Text(item.tanggal, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ),

          // Status Badge
          _statusBadge(item.status),
        ],
      ),
    );
  }

  Widget _statusBadge(String s) {
    Color mainColor;
    Color bgColor;

    switch (s.toLowerCase()) {
      case 'pending':
      case 'menunggu':
        mainColor = const Color(0xFFF59E0B);
        bgColor = const Color(0xFFFEF3C7);
        s = 'Menunggu';
        break;
      case 'diproses':
        mainColor = const Color(0xFF3B82F6);
        bgColor = const Color(0xFFDBEAFE);
        s = 'Diproses';
        break;
      case 'disetujui':
        mainColor = const Color(0xFF10B981);
        bgColor = const Color(0xFFD1FAE5);
        s = 'Disetujui';
        break;
      case 'ditolak':
        mainColor = const Color(0xFFEF4444);
        bgColor = const Color(0xFFFEE2E2);
        s = 'Ditolak';
        break;
      case 'selesai':
        mainColor = const Color(0xFF8B5CF6);
        bgColor = const Color(0xFFEDE9FE);
        s = 'Selesai';
        break;
      default:
        mainColor = Colors.grey;
        bgColor = Colors.grey.withValues(alpha: 0.1);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: mainColor, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(s, style: TextStyle(color: mainColor, fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildEmpty() => const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Belum ada data pengajuan terbaru', style: TextStyle(color: Colors.grey))));
}

class _StatCard extends StatelessWidget {
  final String title, value; final Color color;
  const _StatCard(this.title, this.value, this.color);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 5)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)), Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey))]),
    );
  }
}
