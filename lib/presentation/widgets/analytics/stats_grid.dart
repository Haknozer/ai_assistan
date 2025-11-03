import 'package:flutter/material.dart';
import '../../screens/analytics/data/mock_analytics.dart';
import '../../screens/analytics/utils/analytics_utils.dart';
import 'stat_card.dart';

/// İstatistik kartları grid widget'ı - Responsive grid layout
class StatsGrid extends StatelessWidget {
  final List<StatCardData> stats;

  const StatsGrid({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layoutParams = AnalyticsUtils.calculateGridLayout(constraints.maxWidth);

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: layoutParams.crossAxisCount,
          childAspectRatio: layoutParams.childAspectRatio,
          mainAxisSpacing: layoutParams.mainAxisSpacing,
          crossAxisSpacing: layoutParams.crossAxisSpacing,
          children: stats.map((stat) => StatCard(data: stat)).toList(),
        );
      },
    );
  }
}

