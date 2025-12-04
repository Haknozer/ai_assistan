import 'package:flutter/material.dart';

/// Analitik yardımcı fonksiyonları
class AnalyticsUtils {
  /// Trend değerine göre ikon döndürür
  static IconData getTrendIcon(String trendValue) {
    if (trendValue.contains('+')) {
      return Icons.trending_up;
    } else if (trendValue.contains('-')) {
      return Icons.trending_down;
    } else {
      return Icons.trending_flat;
    }
  }

  /// Trend değerine göre renk döndürür
  static Color getTrendColor(String trendValue) {
    if (trendValue.contains('+')) {
      return Colors.green;
    } else if (trendValue.contains('-')) {
      return Colors.red;
    } else {
      return Colors.grey;
    }
  }

  /// Yüzde değerini formatla
  static String formatPercentage(double value) {
    return '${value.toStringAsFixed(0)}%';
  }

  /// Sayıyı kısa formata çevir (örn: 1200 -> 1.2K)
  static String formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  /// Responsive font size hesapla
  static double calculateFontSize({
    required double screenWidth,
    required double baseSize,
    double minSize = 8,
    double maxSize = 50,
  }) {
    final scaleFactor = (screenWidth / 1200).clamp(0.7, 1.2);
    return (baseSize * scaleFactor).clamp(minSize, maxSize);
  }

  /// Grid layout parametrelerini hesapla
  static GridLayoutParams calculateGridLayout(double maxWidth) {
    if (maxWidth > 1200) {
      // Large Desktop
      return const GridLayoutParams(
        crossAxisCount: 4,
        childAspectRatio: 1.4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      );
    } else if (maxWidth > 600) {
      // Small Desktop / Tablet
      return const GridLayoutParams(
        crossAxisCount: 2,
        childAspectRatio: 1.3,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
      );
    } else {
      // Mobile
      return const GridLayoutParams(
        crossAxisCount: 1,
        childAspectRatio: 2.5,
        mainAxisSpacing: 12,
        crossAxisSpacing: 0,
      );
    }
  }
}

/// Grid layout parametreleri
class GridLayoutParams {
  final int crossAxisCount;
  final double childAspectRatio;
  final double mainAxisSpacing;
  final double crossAxisSpacing;

  const GridLayoutParams({
    required this.crossAxisCount,
    required this.childAspectRatio,
    required this.mainAxisSpacing,
    required this.crossAxisSpacing,
  });
}

