import 'package:flutter/material.dart';

class MyColors {
  // ===== App Background =====
  static const Color backgroundStart = Color(0xFFF5F7FF);
  static const Color backgroundMid   = Color(0xFFE0E6FF);
  static const Color backgroundEnd   = Color(0xFFB6C4FF);

  // ===== Brand / Primary Gradient =====
  static const Color gradient1 = Color(0xFF5B7CFF);
  static const Color gradient2 = Color(0xFF1E3CFF);
  static const Color gradient3 = Color(0xFF0B1872);

  // ===== Glass UI =====
  static const Color glassBackground =
      Color.fromARGB(153, 255, 255, 255); // alpha ~0.6
  static const Color glassBorder =
      Color.fromARGB(64, 255, 255, 255); // subtle border

  // ===== Chat Bubbles =====
  static const Color userBubbleStart = gradient1;
  static const Color userBubbleEnd   = gradient2;

  static const Color botBubbleStart  = Colors.white;
  static const Color botBubbleEnd    = Color(0xFFF0F3FF);

  // ===== Text Colors =====
  static const Color primaryText = Color(0xFF1C1C1E);
  static const Color secondaryText = Color(0xFF6D6D6D);
  static const Color lightText = Colors.white;

  // ===== Icons & Buttons =====
  static const Color iconPrimary = Color(0xFF1E3CFF);
  static const Color iconLight = Colors.white;
  static const Color iconDark = Color(0xFF1C1C1E);

  // ===== Shadows =====
  static const Color shadowLight = Color.fromARGB(20, 0, 0, 0);


}
