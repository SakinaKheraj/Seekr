import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000';
    }
    // Android emulator treats 10.0.2.2 as localhost of the host machine
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:8000';
      }
    } catch (e) {
      // Platform is not available in some environments
    }
    // iOS and Desktop (Windows/macOS/Linux)
    return 'http://localhost:8000';
  }
}
