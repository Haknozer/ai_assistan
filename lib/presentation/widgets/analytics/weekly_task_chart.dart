import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/analytics/providers/analytics_provider.dart';

/// Haftalık Görev Tamamlama Grafiği
class WeeklyTaskChart extends ConsumerWidget {
  const WeeklyTaskChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyTasksAsync = ref.watch(weeklyTasksDetailedProvider);

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
            'Haftalık Görev Tamamlama',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tamamlanan vs Toplam Görev',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
          ),
          const SizedBox(height: 24),

          // Grafik
          SizedBox(
            height: 300,
            child: weeklyTasksAsync.when(
              data: (data) => _buildChart(context, data),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text(
                  'Veriler yüklenemedi',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Legend
          _buildLegend(context),
        ],
      ),
    );
  }

  Widget _buildChart(
    BuildContext context,
    Map<String, Map<String, int>> weeklyData,
  ) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _calculateMaxY(weeklyData),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => Theme.of(context).colorScheme.inverseSurface,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final day = _getDayName(group.x.toInt());
              final value = rod.toY.round();
              final label = rodIndex == 0 ? 'Tamamlanan' : 'Toplam';
              return BarTooltipItem(
                '$day\n$label: $value',
                TextStyle(
                  color: Theme.of(context).colorScheme.onInverseSurface,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _getDayName(value.toInt()),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 2,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                );
              },
              reservedSize: 40,
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: _getBarGroups(context, weeklyData),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 2,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
              strokeWidth: 1,
            );
          },
        ),
      ),
    );
  }

  List<BarChartGroupData> _getBarGroups(
    BuildContext context,
    Map<String, Map<String, int>> weeklyData,
  ) {
    const dayOrder = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

    return List.generate(dayOrder.length, (index) {
      final dayKey = dayOrder[index];
      final dayData = weeklyData[dayKey] ?? {'completed': 0, 'total': 0};
      final completed = (dayData['completed'] ?? 0).toDouble();
      final total = (dayData['total'] ?? 0).toDouble();

      return BarChartGroupData(
        x: index,
        barRods: [
          // Tamamlanan görevler
          BarChartRodData(
            toY: completed,
            color: Colors.green,
            width: 16,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
          // Toplam görevler
          BarChartRodData(
            toY: total,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            width: 16,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildLegend(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(context, 'Tamamlanan', Colors.green),
        const SizedBox(width: 24),
        _buildLegendItem(
          context,
          'Toplam',
          Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
      ],
    );
  }

  double _calculateMaxY(Map<String, Map<String, int>> weeklyData) {
    double max = 0;
    for (final day in weeklyData.values) {
      final total = (day['total'] ?? 0).toDouble();
      if (total > max) max = total;
    }
    if (max == 0) return 5;
    // Biraz boşluk bırak
    return (max + 2).clamp(5, 20);
  }

  Widget _buildLegendItem(BuildContext context, String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
        ),
      ],
    );
  }

  String _getDayName(int index) {
    const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    return days[index];
  }
}
