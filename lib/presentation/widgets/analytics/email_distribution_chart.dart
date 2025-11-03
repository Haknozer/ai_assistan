import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// E-posta Dağılımı Grafiği
class EmailDistributionChart extends StatelessWidget {
  const EmailDistributionChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Text(
            'E-posta Dağılımı',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bu haftaki e-posta kategorileri',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
          ),
          const SizedBox(height: 24),

          // Grafik
          SizedBox(
            height: 300,
            child: _buildChart(context),
          ),

          const SizedBox(height: 16),

          // Legend
          _buildLegend(context),
        ],
      ),
    );
  }

  Widget _buildChart(BuildContext context) {
    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(
          enabled: true,
        ),
        sectionsSpace: 1,
        centerSpaceRadius: 0, // Klasik pasta grafiği için ortası boş değil
        sections: _getPieSections(context),
      ),
    );
  }

  List<PieChartSectionData> _getPieSections(BuildContext context) {
    // E-posta kategori verileri: [kategori, değer, renk]
    final emailData = [
      ['Önemli', 42, Colors.red],
      ['İş', 68, Colors.blue],
      ['Kişisel', 28, Colors.green],
      ['Promosyon', 18, Colors.orange],
    ];

    return List.generate(emailData.length, (index) {
      final value = emailData[index][1] as int;
      final color = emailData[index][2] as Color;
      final percentage = _getPercentage(index);

      return PieChartSectionData(
        color: color,
        value: value.toDouble(),
        title: '%$percentage',
        radius: 100, // Daha küçük radius - yazılar ortaya daha yakın
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        titlePositionPercentageOffset: 0.6, // Yazıları ortadan daha uzağa taşı
        // Badge kaldırıldı - klasik pasta grafiği
      );
    });
  }

  double _getPercentage(int index) {
    final emailData = [42, 68, 28, 18]; // Önemli, İş, Kişisel, Promosyon
    final total = emailData.reduce((a, b) => a + b);
    return (emailData[index] / total * 100).roundToDouble();
  }

  String _getEmailCategory(int index) {
    const categories = ['Önemli', 'İş', 'Kişisel', 'Promosyon'];
    return categories[index];
  }

  Widget _buildLegend(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        _buildLegendItem(context, 'Önemli', Colors.red, 42),
        _buildLegendItem(context, 'İş', Colors.blue, 68),
        _buildLegendItem(context, 'Kişisel', Colors.green, 28),
        _buildLegendItem(context, 'Promosyon', Colors.orange, 18),
      ],
    );
  }

  Widget _buildLegendItem(BuildContext context, String label, Color color, int value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label ($value)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
        ),
      ],
    );
  }
}
