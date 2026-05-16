import 'dart:async';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:local_auth/local_auth.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:sensors_plus/sensors_plus.dart';

class PlatformService {
  static final LocalAuthentication _localAuth = LocalAuthentication();
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // Kamera
  static Future<String?> takePhoto() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return null;
      final firstCamera = cameras.first;
      final controller = CameraController(firstCamera, ResolutionPreset.medium);
      await controller.initialize();
      final image = await controller.takePicture();
      await controller.dispose();
      return image.path;
    } catch (e) {
      return null;
    }
  }

  // GPS
  static Future<Position?> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition();
  }

  // Push Notification
  static Future<void> initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(message.notification?.title ?? 'Notifikasi', message.notification?.body ?? '');
    });
  }

  static Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await _flutterLocalNotificationsPlugin.show(0, title, body, platformChannelSpecifics);
  }

  // Biometric Auth (Cepat)
  static Future<bool> authenticateBiometric() async {
    try {
      bool canAuthenticate = await _localAuth.canCheckBiometrics || await _localAuth.isDeviceSupported();
      if (!canAuthenticate) return false;

      return await _localAuth.authenticate(
        localizedReason: 'Autentikasi biometrik untuk akses cepat',
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
    } catch (e) {
      return false;
    }
  }

  // NFC
  static Future<String?> readNFC() async {
    bool isAvailable = await NfcManager.instance.isAvailable();
    if (!isAvailable) return null;

    Completer<String?> completer = Completer();
    NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      try {
        Ndef? ndef = Ndef.from(tag);
        if (ndef != null && ndef.cachedMessage != null) {
          String payload = String.fromCharCodes(ndef.cachedMessage!.records.first.payload);
          completer.complete(payload);
        } else {
          completer.complete(null);
        }
      } catch (e) {
        completer.complete(null);
      } finally {
        NfcManager.instance.stopSession();
      }
    });

    return completer.future.timeout(const Duration(seconds: 10), onTimeout: () => null);
  }

  // Accelerometer
  static Stream<AccelerometerEvent> getAccelerometerStream() {
    return accelerometerEventStream();
  }
}
