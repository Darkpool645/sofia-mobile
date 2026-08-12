import 'package:flutter/material.dart';

// Paleta SOFIA (igual que el prototipo): pizarra + marigold.
class SofiaColors {
  static const brand = Color(0xFF2B3556);
  static const gold = Color(0xFFDE9425);
  static const paper = Color(0xFFFAF9F5);
  static const ink = Color(0xFF222A3D);
  static const soft = Color(0xFF6A7080);
}

ThemeData buildSofiaTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: SofiaColors.brand,
    primary: SofiaColors.brand,
    secondary: SofiaColors.gold,
    brightness: Brightness.light,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: SofiaColors.paper,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFECEAE3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFECEAE3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: SofiaColors.brand, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: SofiaColors.brand,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
  );
}