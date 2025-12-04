import 'package:flutter/material.dart';

/// Mock analitik verileri - Test ve geliştirme için
class MockAnalytics {
  /// İstatistik kartları için veriler
  static List<StatCardData> get statCards => [
        const StatCardData(
          title: 'Tamamlanan Görevler',
          mainValue: '24',
          subValue: '38 görevden',
          trendValue: '%63 Tamamlandı',
          icon: Icons.task_alt,
          color: Colors.green,
        ),
        const StatCardData(
          title: 'Toplantılar',
          mainValue: 'Bu ay 12',
          subValue: 'Toplamda 23',
          trendValue: '+3 geçen aya göre',
          icon: Icons.groups,
          color: Colors.blue,
        ),
        const StatCardData(
          title: 'E-posta',
          mainValue: '156',
          subValue: 'Bu hafta',
          trendValue: '42 önemli',
          icon: Icons.email,
          color: Colors.purple,
        ),
        const StatCardData(
          title: 'Verimlilik Skoru',
          mainValue: '85%',
          subValue: 'Hedef: 80%',
          trendValue: '+5% artış',
          icon: Icons.trending_up,
          color: Colors.orange,
        ),
      ];

  /// Haftalık görev istatistikleri
  static Map<String, int> get weeklyTasks => {
        'Pzt': 5,
        'Sal': 8,
        'Çar': 6,
        'Per': 7,
        'Cum': 9,
        'Cmt': 3,
        'Paz': 2,
      };

  /// E-posta dağılım verileri
  static Map<String, int> get emailDistribution => {
        'Gelen': 89,
        'Gönderilen': 45,
        'Spam': 12,
        'Taslak': 10,
      };

  /// Aylık toplantı trendi
  static Map<String, int> get monthlyMeetings => {
        'Oca': 8,
        'Şub': 10,
        'Mar': 7,
        'Nis': 12,
        'May': 9,
        'Haz': 11,
      };

  /// Öncelik bazlı görevler
  static Map<String, int> get priorityTasks => {
        'Acil': 5,
        'Yüksek': 12,
        'Orta': 18,
        'Düşük': 8,
      };
}

/// İstatistik kartı veri modeli
class StatCardData {
  final String title;
  final String mainValue;
  final String subValue;
  final String trendValue;
  final IconData icon;
  final Color color;

  const StatCardData({
    required this.title,
    required this.mainValue,
    required this.subValue,
    required this.trendValue,
    required this.icon,
    required this.color,
  });
}

