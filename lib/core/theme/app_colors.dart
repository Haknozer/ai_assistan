import 'package:flutter/material.dart';

class AppColors {
  // Ana Renkler
  static const Color primaryColor = Color(0xFF1976D2);
  static const Color secondaryColor = Color(0xFF03DAC6);
  static const Color errorColor = Color(0xFFB00020);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color successColor = Color(0xFF4CAF50);

  // Arka Plan Renkleri (Light Theme - Varsayılan)
  static const Color backgroundColor = Color(0xFFFDFBFF);
  static const Color surfaceColor = Colors.white;
  static const Color cardColor = Colors.white;

  // Metin Renkleri (Light Theme - Varsayılan)
  static const Color primaryTextColor = Color(0xFF1A1A1A);
  static const Color secondaryTextColor = Color(0xFF666666);
  static const Color hintText = Color(0xFF999999);

  // Border Renkleri (Light Theme - Varsayılan)
  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color focusedBorderColor = Color(0xFF1976D2);
  static const Color errorBorderColor = Color(0xFFB00020);

  // Buton Background Renkleri (Light Theme - Varsayılan)
  static const Color buttonBackground = Color(0xFFF5F5F5);

  // Light Theme Renkleri
  static const Color lightBackgroundColor = Color(0xFFFDFBFF);
  static const Color lightSurfaceColor = Colors.white;
  static const Color lightCardColor = Colors.white;
  static const Color lightPrimaryTextColor = Color(0xFF1A1A1A);
  static const Color lightSecondaryTextColor = Color(0xFF666666);
  static const Color lightHintText = Color(0xFF999999);
  static const Color lightBorderColor = Color(0xFFE0E0E0);
  static const Color lightButtonBackground = Color(0xFFF5F5F5);

  // Dark Theme Renkleri
  static const Color darkBackgroundColor = Color(0xFF1C1B1F);
  static const Color darkSurfaceColor = Color(0xFF1E1E1E);
  static const Color darkCardColor = Color(0xFF2D2D2D);
  static const Color darkPrimaryTextColor = Color(0xFFFFFFFF);
  static const Color darkSecondaryTextColor = Color(0xFFB3B3B3);
  static const Color darkHintText = Color(0xFF808080);
  static const Color darkBorderColor = Color(0xFF424242);
  static const Color darkButtonBackground = Color(0xFF2D2D2D);

  // Responsive renkler (temaya göre değişir)
  static Color getBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkBackgroundColor : lightBackgroundColor;
  }

  static Color getSurfaceColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkSurfaceColor : lightSurfaceColor;
  }

  static Color getCardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkCardColor : lightCardColor;
  }

  static Color getPrimaryTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkPrimaryTextColor : lightPrimaryTextColor;
  }

  static Color getSecondaryTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkSecondaryTextColor : lightSecondaryTextColor;
  }

  static Color getHintTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkHintText : lightHintText;
  }

  static Color getBorderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkBorderColor : lightBorderColor;
  }

  static Color getButtonBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkButtonBackground : lightButtonBackground;
  }

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
