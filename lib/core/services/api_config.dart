import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  // ─────────────────────────────────────────────────────────────────────
  // PRODUCTION: Set useProduction = true and put your EC2 IP/domain here
  // ─────────────────────────────────────────────────────────────────────
  static const bool useProduction = true;
  static const String prodUrl = 'https://seekr-mz2m.onrender.com/';

  // ─────────────────────────────────────────────────────────────────────
  // LOCAL DEV on a REAL PHYSICAL DEVICE (USB debugging):
  //   Uses your PC's Wi-Fi IP — NOT 10.0.2.2 (that's emulator only!)
  //   To find your IP: run `ipconfig` in cmd → look for Wi-Fi IPv4 Address
  //   ⚠️ Update this if your router gives you a different IP next time
  // ─────────────────────────────────────────────────────────────────────
  static const String devPhysicalDeviceUrl = 'http://192.168.31.120:8000';

  static String get baseUrl {
    if (useProduction) {
      return prodUrl;
    }

    if (kIsWeb) {
      return 'http://localhost:8000';
    }

    try {
      if (Platform.isAndroid) {
        // Real physical device needs the PC's LAN IP, not the emulator alias
        return devPhysicalDeviceUrl;
      }
    } catch (e) {
      // Platform check not available in some environments
    }

    // iOS and Desktop (Windows/macOS/Linux)
    return 'http://localhost:8000';
  }
}