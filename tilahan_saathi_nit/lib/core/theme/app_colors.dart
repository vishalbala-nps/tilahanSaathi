import 'package:flutter/material.dart';

/// Brand colors for Tilahan Saathi.
abstract final class AppColors {
  static const primary = Color(0xFF3FA34D);
  static const secondary = Color(0xFF7BC96F);
  static const accent = Color(0xFFF6C445);
  static const skyBlue = Color(0xFF61C9F8);
  static const earthBrown = Color(0xFF9C6B3E);
  static const background = Color(0xFFF9FCF7);
  static const surface = Colors.white;
  static const textPrimary = Color(0xFF1A2E1A);
  static const textSecondary = Color(0xFF5A6B5A);
  static const error = Color(0xFFD32F2F);

  static const splashGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );
}
