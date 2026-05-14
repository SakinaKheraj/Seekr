import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  // ─────────────────────────────────────────────────────────────────────
  // PRODUCTION URLs
  // ─────────────────────────────────────────────────────────────────────
  static const String prodUrlWeb = 'https://seekr-mz2m.onrender.com';   // Web → Render (HTTPS)
  static const String prodUrlMobile = 'http://16.170.196.76';            // Android → EC2 (fast)

 
  static const bool useProduction = true;
  static const String devPhysicalDeviceUrl = 'http://192.168.31.120:8000';

  static String get baseUrl {
    if (useProduction) {
      if (kIsWeb) {
        return prodUrlWeb;    // Web app uses Render (HTTPS)
      }
      return prodUrlMobile;   // Android uses EC2 (no cold start)
    }

    if (kIsWeb) {
      return 'http://localhost:8000';
    }

    try {
      if (Platform.isAndroid) {
        return devPhysicalDeviceUrl;
      }
    } catch (e) {
      // Platform check not available in some environments
    }

    return 'http://localhost:8000';
  }
}