import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/analytics/providers/analytics_provider.dart';

/// E-posta Dağılımı Grafiği
class EmailDistributionChart extends ConsumerWidget {
  const EmailDistributionChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailDistributionAsync = ref.watch(emailDistributionProvider);

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
            'E-posta kategorileri (tüm zamanlar)',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
          ),
          const SizedBox(height: 24),

          // Grafik
          SizedBox(
            height: 300,
            child: emailDistributionAsync.when(
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
          emailDistributionAsync.when(
            data: (data) => _buildLegend(context, data),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(BuildContext context, Map<String, int> data) {
    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(
          enabled: true,
        ),
        sectionsSpace: 1,
        centerSpaceRadius: 0, // Klasik pasta grafiği için ortası boş değil
        sections: _getPieSections(context, data),
      ),
    );
  }

  List<PieChartSectionData> _getPieSections(
    BuildContext context,
    Map<String, int> data,
  ) {
    // Map verisini listeye çevir
    final entries = data.entries.toList();
    final total = entries.fold<int>(0, (sum, e) => sum + e.value);

    if (total == 0) {
      return [
        PieChartSectionData(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          value: 1,
          title: '%0',
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

    return List.generate(entries.length, (index) {
      final entry = entries[index];
      final value = entry.value;
      final color = _getColorForLabel(entry.key, index);
      final percentage = (value / total * 100).round();

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
      );
    });
  }

  Color _getColorForLabel(String label, int index) {
    switch (label.toLowerCase()) {
      case 'görev':
        return Colors.blue;
      case 'toplantı':
        return Colors.green;
      case 'staj':
        return Colors.orange;
      case 'reklam':
        return Colors.red;
      case 'diğer':
        return Colors.grey;
      default:
        const colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.grey];
        return colors[index % colors.length];
    }
  }

  Widget _buildLegend(BuildContext context, Map<String, int> data) {
    final entries = data.entries.toList();
    final total = entries.fold<int>(0, (sum, e) => sum + e.value);
    
    if (total == 0) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: entries.map((entry) {
        final color = _getColorForLabel(entry.key, entries.indexOf(entry));
        final percentage = total > 0 ? (entry.value / total * 100).round() : 0;
        
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
              '${entry.key} ($percentage%)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
            ),
          ],
        );
      }).toList(),
    );
  }

}
