import 'package:flutter/material.dart';

class AppColors {
  // Ana Renkler
  static const Color primaryColor = Color(0xFF1976D2);
  static const Color secondaryColor = Color(0xFF03DAC6);
  static const Color errorColor = Color(0xFFB00020);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color successColor = Color(0xFF4CAF50);

  // Arka Plan Renkleri
  static const Color backgroundColor = Color(0xFFFDFBFF);
  static const Color surfaceColor = Colors.white;
  static const Color cardColor = Colors.white;

  // Metin Renkleri
  static const Color primaryTextColor = Color(0xFF1A1A1A);
  static const Color secondaryTextColor = Color(0xFF666666);
  static const Color hintText = Color(0xFF999999);

  // Border Renkleri
  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color focusedBorderColor = Color(0xFF1976D2);
  static const Color errorBorderColor = Color(0xFFB00020);

  // Buton Background Renkleri
  static const Color buttonBackground = Color(0xFFF5F5F5);

  // Gradient'ler
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, Color(0xFF64B5F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shadow'lar
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];
}