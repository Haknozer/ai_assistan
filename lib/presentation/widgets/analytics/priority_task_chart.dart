import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// Öncelik Bazlı Görev İstatistiği Grafiği
class PriorityTaskChart extends StatelessWidget {
  const PriorityTaskChart({super.key});

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
            'Öncelik Bazlı Görevler',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Görevlerin öncelik seviyelerine göre dağılımı',
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
        centerSpaceRadius: 0, // Klasik pasta grafiği
        sections: _getPieSections(context),
      ),
    );
  }

  List<PieChartSectionData> _getPieSections(BuildContext context) {
    // Öncelik verileri: [kritik, yüksek, orta, düşük]
    final priorityData = [8, 15, 12, 6];

    return List.generate(4, (index) {
      final value = priorityData[index];
      final color = _getPriorityColor(index);
      _getPercentage(index);

      return PieChartSectionData(
        color: color,
        value: value.toDouble(),
        title: '$value',
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        titlePositionPercentageOffset: 0.6,
      );
    });
  }

  double _getPercentage(int index) {
    final priorityData = [8, 15, 12, 6]; // Kritik, Yüksek, Orta, Düşük
    final total = priorityData.reduce((a, b) => a + b);
    return (priorityData[index] / total * 100).roundToDouble();
  }

  Color _getPriorityColor(int index) {
    switch (index) {
      case 0: // Kritik
        return Colors.red;
      case 1: // Yüksek
        return Colors.orange;
      case 2: // Orta
        return Colors.blue;
      case 3: // Düşük
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildLegend(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        _buildLegendItem(context, 'Kritik', Colors.red, 8),
        _buildLegendItem(context, 'Yüksek', Colors.orange, 15),
        _buildLegendItem(context, 'Orta', Colors.blue, 12),
        _buildLegendItem(context, 'Düşük', Colors.green, 6),
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
