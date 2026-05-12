import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/auth_service.dart';
import '../../services/notif_service.dart';
import '../../models/user_model.dart';
import 'ajukan_screen.dart';
import 'status_screen.dart';
import 'profil_screen.dart';
import 'notif_screen.dart';
import 'hubungi_screen.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../services/surat_service.dart';
import '../../models/surat_model.dart';
import '../admin/kelola_screen.dart';
import '../admin/warga_screen.dart';
import '../admin/pesan_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int _unreadNotif = 0;
  UserModel? _user;
  Timer? _timer;
  Map<String, dynamic> _stats = {};
  List<SuratModel> _latest = [];

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);
    _loadUser();
    _startPolling();
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getUser();
    if (mounted) setState(() => _user = user);
  }

  void _startPolling() {
    _refreshData();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _refreshData());
  }

  Future<void> _refreshData() async {
    if (!mounted) return;
    
    try {
      // 1. Ambil Statistik dari SuratService
      final statsData = await SuratService.getStats();
      
      // 2. Ambil Daftar Surat Terbaru dari SuratService
      final latestData = await SuratService.getSuratSaya();
      
      // 3. Ambil Notif
      final unread = await NotifService.getUnreadCount();

      if (mounted) {
        setState(() {
          _unreadNotif = unread;
          _stats = statsData;
          // Ambil 3 data terbaru saja untuk di beranda
          _latest = latestData.take(3).toList();
        });
      }
    } catch (e) {
      // Log error silently or use a proper logger
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _user?.role.toLowerCase() == 'admin';

    final pages = [
      _BerandaTab(
        user: _user, 
        stats: _stats,
        latest: _latest,
        onNavigate: (i) => setState(() => _currentIndex = i),
        unreadNotif: _unreadNotif,
        onRefresh: _refreshData,
      ),
      isAdmin ? const KelolaScreen() : AjukanScreen(onSuccess: () {
        _refreshData();
        setState(() => _currentIndex = 2);
      }),
      isAdmin ? const WargaScreen() : const StatusScreen(),
      const ProfilScreen(),
      isAdmin ? const PesanScreen() : const HubungiScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF2E7D32),
        unselectedItemColor: Colors.grey,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(
            icon: Icon(isAdmin ? Icons.assignment_outlined : Icons.add_circle_outline), 
            label: isAdmin ? 'Kelola' : 'Ajukan'
          ),
          BottomNavigationBarItem(
            icon: Icon(isAdmin ? Icons.people_outline : Icons.description_outlined), 
            label: isAdmin ? 'Warga' : 'Status'
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profil'),
          BottomNavigationBarItem(
            icon: Icon(isAdmin ? Icons.mail_outline : Icons.support_agent), 
            label: isAdmin ? 'Pesan' : 'Admin'
          ),
        ],
      ),
    );
  }
}

class _BerandaTab extends StatelessWidget {
  final UserModel? user;
  final Map<String, dynamic> stats;
  final List<SuratModel> latest;
  final Function(int) onNavigate;
  final int unreadNotif;
  final Future<void> Function() onRefresh;
  const _BerandaTab({this.user, required this.stats, required this.latest, required this.onNavigate, required this.unreadNotif, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final isAdmin = user?.role.toLowerCase() == 'admin';

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 40),
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
                      Text(isAdmin ? 'Dashboard Overview' : 'Halo Selamat Datang, ${(user?.nama ?? 'Warga').split(' ')[0]}!',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(DateFormat('EEEE, d MMM yyyy', 'id_ID').format(DateTime.now()), 
                          style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                  _buildNotifIcon(context),
                ],
              ),
            ),
  
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Transform.translate(
                offset: const Offset(0, -20),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _SmallStatCard('${stats['total'] ?? 0}', 'Total Pengajuan', Icons.folder_open, Colors.green),
                      const SizedBox(width: 12),
                      _SmallStatCard('${stats['pending'] ?? stats['menunggu'] ?? 0}', 'Menunggu', Icons.hourglass_empty, Colors.orange),
                      const SizedBox(width: 12),
                      _SmallStatCard('${stats['diproses'] ?? 0}', 'Diproses', Icons.sync, Colors.blue),
                      const SizedBox(width: 12),
                      _SmallStatCard('${isAdmin ? (stats['total_warga'] ?? 0) : (stats['selesai'] ?? stats['disetujui'] ?? 0)}', isAdmin ? 'Total Warga' : 'Selesai', isAdmin ? Icons.people : Icons.check_circle, Colors.purple),
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15)]),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _MenuIconButton(isAdmin ? Icons.assignment : Icons.add_task, isAdmin ? 'Kelola' : 'Ajukan', () => onNavigate(1)),
                    _MenuIconButton(isAdmin ? Icons.people : Icons.assignment, isAdmin ? 'Warga' : 'Status', () => onNavigate(2)),
                    _MenuIconButton(isAdmin ? Icons.mail : Icons.support_agent, isAdmin ? 'Pesan' : 'Hubungi', () => onNavigate(4)),
                    _MenuIconButton(Icons.person, 'Profil', () => onNavigate(3)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Pengajuan Terbaru', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  TextButton(onPressed: () => onNavigate(2), child: const Text('Lihat semua →', style: TextStyle(color: Colors.grey, fontSize: 12))),
                ],
              ),
            ),
            
            if (latest.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(20), width: double.infinity,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: const Center(child: Text('Belum ada data', style: TextStyle(color: Colors.grey))),
                ),
              )
            else
              ...latest.map((item) => _buildLatestItem(item, isAdmin)),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildNotifIcon(BuildContext context) {
    return Stack(
      children: [
        IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotifScreen())), icon: const Icon(Icons.notifications_none, color: Colors.white)),
        if (unreadNotif > 0)
          Positioned(right: 8, top: 8, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: Text(unreadNotif.toString(), style: const TextStyle(color: Colors.white, fontSize: 8)))),
      ],
    );
  }

  Widget _buildLatestItem(SuratModel s, bool isAdmin) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)]),
        child: Row(
          children: [
            const Icon(Icons.description, color: Colors.green),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  Text(isAdmin ? s.namaWarga : s.jenisSurat, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), 
                  Text(s.tanggal, style: const TextStyle(color: Colors.grey, fontSize: 10))
                ]
              )
            ),
            _statusBadge(s.status),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color = status == 'selesai' || status == 'disetujui' ? Colors.green : (status == 'ditolak' ? Colors.red : Colors.orange);
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)), child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)));
  }
}

class _SmallStatCard extends StatelessWidget {
  final String value, label; final IconData icon; final Color color;
  const _SmallStatCard(this.value, this.label, this.icon, this.color);
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: color, size: 20), const SizedBox(height: 8), Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey))]),
    );
  }
}

class _MenuIconButton extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap;
  const _MenuIconButton(this.icon, this.label, this.onTap);
  @override
  Widget build(BuildContext context) {
    return InkWell(onTap: onTap, child: Column(children: [Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: Colors.green)), const SizedBox(height: 8), Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))]));
  }
}
