import 'dart:async';
import 'package:flutter/material.dart';
import '../services/platform_service.dart';
import 'package:sensors_plus/sensors_plus.dart';

class PlatformFeaturesScreen extends StatefulWidget {
  const PlatformFeaturesScreen({super.key});

  @override
  State<PlatformFeaturesScreen> createState() => _PlatformFeaturesScreenState();
}

class _PlatformFeaturesScreenState extends State<PlatformFeaturesScreen> {
  String _accelerometerData = 'Tidak ada data';
  StreamSubscription<AccelerometerEvent>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = PlatformService.getAccelerometerStream().listen((event) {
      if (mounted) {
        setState(() {
          _accelerometerData = 'X: ${event.x.toStringAsFixed(2)}, Y: ${event.y.toStringAsFixed(2)}, Z: ${event.z.toStringAsFixed(2)}';
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Platform Features'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildButton(
            text: 'Ambil Foto (Kamera)',
            icon: Icons.camera_alt,
            onPressed: () async {
              String? photoPath = await PlatformService.takePhoto();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(photoPath != null ? 'Foto diambil: $photoPath' : 'Gagal mengambil foto')),
              );
            },
          ),
          const SizedBox(height: 10),
          _buildButton(
            text: 'Dapatkan Lokasi (GPS)',
            icon: Icons.location_on,
            onPressed: () async {
              var position = await PlatformService.getCurrentLocation();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(position != null ? 'Lokasi: ${position.latitude}, ${position.longitude}' : 'Gagal mendapatkan lokasi')),
              );
            },
          ),
          const SizedBox(height: 10),
          _buildButton(
            text: 'Inisialisasi Push Notification',
            icon: Icons.notifications,
            onPressed: () async {
              await PlatformService.initializeNotifications();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifikasi diinisialisasi')),
              );
            },
          ),
          const SizedBox(height: 10),
          _buildButton(
            text: 'Autentikasi Biometrik (Cepat)',
            icon: Icons.fingerprint,
            onPressed: () async {
              bool authenticated = await PlatformService.authenticateBiometric();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(authenticated ? 'Autentikasi berhasil' : 'Autentikasi gagal')),
              );
            },
          ),
          const SizedBox(height: 10),
          _buildButton(
            text: 'Baca NFC',
            icon: Icons.nfc,
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mencari NFC...')));
              String? nfcData = await PlatformService.readNFC();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(nfcData != null ? 'NFC Data: $nfcData' : 'Tidak ada NFC terdeteksi')),
              );
            },
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 10),
          const Text('Data Accelerometer:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(_accelerometerData, style: const TextStyle(fontFamily: 'monospace')),
          ),
        ],
      ),
    );
  }

  Widget _buildButton({required String text, required IconData icon, required VoidCallback onPressed}) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2E7D32),
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.centerLeft,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFF2E7D32)),
        ),
      ),
    );
  }
}
