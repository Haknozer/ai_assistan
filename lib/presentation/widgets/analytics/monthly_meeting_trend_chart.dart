import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/analytics/providers/analytics_provider.dart';

/// Aylık Toplantı Trendi Grafiği
class MonthlyMeetingTrendChart extends ConsumerWidget {
  const MonthlyMeetingTrendChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthlyMeetingsAsync = ref.watch(monthlyMeetingsProvider);

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
            'Toplantı Trendi',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aylık toplantı dağılımı',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
          ),
          const SizedBox(height: 24),

          // Grafik
          SizedBox(
            height: 300,
            child: monthlyMeetingsAsync.when(
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

  Widget _buildChart(BuildContext context, Map<String, int> monthlyDataMap) {
    // Aylık toplantı sayılarından dinamik maxY ve aralık hesapla
    final spots = _getMeetingSpots(monthlyDataMap);
    final maxValue = spots.fold<double>(
      0,
      (prev, spot) => spot.y > prev ? spot.y : prev,
    );

    // Minimum ölçek: en az 5 olsun ki çizgi çok sıkışmasın
    double dynamicMaxY;
    if (maxValue <= 5) {
      dynamicMaxY = 5;
    } else if (maxValue <= 10) {
      dynamicMaxY = 10;
    } else if (maxValue <= 20) {
      dynamicMaxY = 20;
    } else if (maxValue <= 50) {
      dynamicMaxY = 50;
    } else if (maxValue <= 100) {
      dynamicMaxY = 100;
    } else {
      // Çok uç değerler için, en büyük değerin biraz üstünü al
      dynamicMaxY = (maxValue / 10).ceil() * 10;
    }

    // Y ekseni aralığı (grid + label)
    double yInterval;
    if (dynamicMaxY <= 10) {
      yInterval = 2;
    } else if (dynamicMaxY <= 20) {
      yInterval = 5;
    } else if (dynamicMaxY <= 50) {
      yInterval = 10;
    } else if (dynamicMaxY <= 100) {
      yInterval = 20;
    } else {
      yInterval = dynamicMaxY / 5;
    }

    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => Theme.of(context).colorScheme.inverseSurface,
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((spot) {
                final month = _getMonthName(spot.x.toInt());
                return LineTooltipItem(
                  '$month\n${spot.y.toInt()} toplantı',
                  TextStyle(
                    color: Theme.of(context).colorScheme.onInverseSurface,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: yInterval,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _getMonthName(value.toInt()),
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
              interval: yInterval,
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
        minX: 0,
        maxX: 11,
        minY: 0,
        maxY: dynamicMaxY,
        lineBarsData: [
          // Toplantı sayıları çizgisi
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                Theme.of(context).colorScheme.primary,
              ],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Theme.of(context).colorScheme.primary,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _getMeetingSpots(Map<String, int> monthlyDataMap) {
    const monthOrder = [
      'Oca',
      'Şub',
      'Mar',
      'Nis',
      'May',
      'Haz',
      'Tem',
      'Ağu',
      'Eyl',
      'Eki',
      'Kas',
      'Ara',
    ];

    return List.generate(monthOrder.length, (index) {
      final label = monthOrder[index];
      final value = (monthlyDataMap[label] ?? 0).toDouble();
      return FlSpot(index.toDouble(), value);
    });
  }

  Widget _buildLegend(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                Theme.of(context).colorScheme.primary,
              ],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Toplantı Sayısı',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
        ),
      ],
    );
  }

  String _getMonthName(int index) {
    const months = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
    return months[index];
  }
}
