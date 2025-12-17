import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/analytics/providers/analytics_provider.dart';

/// Görev DURUMU Bazlı İstatistik Grafiği
class PriorityTaskChart extends ConsumerWidget {
  const PriorityTaskChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final priorityTasksAsync = ref.watch(priorityTasksProvider);

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
            'Görev Durumları',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Görevlerin durumlarına göre dağılımı',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
          ),
          const SizedBox(height: 24),

          // Grafik
          SizedBox(
            height: 300,
            child: priorityTasksAsync.when(
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

  Widget _buildChart(BuildContext context, Map<String, int> priorityDataMap) {
    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(
          enabled: true,
        ),
        sectionsSpace: 1,
        centerSpaceRadius: 0, // Klasik pasta grafiği
        sections: _getPieSections(context, priorityDataMap),
      ),
    );
  }

  List<PieChartSectionData> _getPieSections(
    BuildContext context,
    Map<String, int> priorityDataMap,
  ) {
    const order = ['Beklemede', 'Devam Ediyor', 'Tamamlandı', 'İptal Edildi'];

    final total =
        order.fold<int>(0, (sum, key) => sum + (priorityDataMap[key] ?? 0));

    if (total == 0) {
      return [
        PieChartSectionData(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          value: 1,
          title: '0',
          radius: 100,
          titleStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          titlePositionPercentageOffset: 0.6,
        ),
      ];
    }

    return List.generate(order.length, (index) {
      final key = order[index];
      final value = priorityDataMap[key] ?? 0;
      final color = _getPriorityColor(index);

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

  Color _getPriorityColor(int index) {
    switch (index) {
      case 0: // Beklemede
        return Colors.orange;
      case 1: // Devam Ediyor
        return Colors.blue;
      case 2: // Tamamlandı
        return Colors.green;
      case 3: // İptal Edildi
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildLegend(BuildContext context) {
    const labels = ['Beklemede', 'Devam Ediyor', 'Tamamlandı', 'İptal Edildi'];

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: List.generate(labels.length, (index) {
        final color = _getPriorityColor(index);
        final label = labels[index];
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
            ),
          ],
        );
      }),
    );
  }

}
