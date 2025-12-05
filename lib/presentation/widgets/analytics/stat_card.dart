import 'package:flutter/material.dart';
import '../../../features/analytics/analytics_feature.dart';

/// İstatistik kartı widget'ı - Analitik özet bilgileri gösterir
class StatCard extends StatelessWidget {
  final StatCardData data;

  const StatCard({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 400;

        // Responsive font scaling
        final screenWidth = MediaQuery.of(context).size.width;

        final titleFontSize = AnalyticsUtils.calculateFontSize(
          screenWidth: screenWidth,
          baseSize: 13,
          minSize: 9,
          maxSize: 15,
        );
        final mainValueFontSize = AnalyticsUtils.calculateFontSize(
          screenWidth: screenWidth,
          baseSize: 28,
          minSize: 18,
          maxSize: 36,
        );
        final subValueFontSize = AnalyticsUtils.calculateFontSize(
          screenWidth: screenWidth,
          baseSize: 11,
          minSize: 9,
          maxSize: 13,
        );
        final trendValueFontSize = AnalyticsUtils.calculateFontSize(
          screenWidth: screenWidth,
          baseSize: 10,
          minSize: 8,
          maxSize: 12,
        );
        final iconSize = AnalyticsUtils.calculateFontSize(
          screenWidth: screenWidth,
          baseSize: 18,
          minSize: 14,
          maxSize: 22,
        );

        return Container(
          padding: EdgeInsets.all(isMobile ? 16 : 20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: data.color.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      data.title,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w500,
                            fontSize: titleFontSize,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: isMobile ? 8 : 12),
                  Container(
                    padding: EdgeInsets.all(isMobile ? 8 : 10),
                    decoration: BoxDecoration(
                      color: data.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
                    ),
                    child: Icon(
                      data.icon,
                      color: data.color,
                      size: iconSize,
                    ),
                  ),
                ],
              ),
              SizedBox(height: isMobile ? 12 : 16),
              Text(
                data.mainValue,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: mainValueFontSize,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: isMobile ? 2 : 4),
              Text(
                data.subValue,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                      fontSize: subValueFontSize,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: isMobile ? 2 : 4),
              Row(
                children: [
                  Icon(
                    AnalyticsUtils.getTrendIcon(data.trendValue),
                    size: trendValueFontSize + 2,
                    color: AnalyticsUtils.getTrendColor(data.trendValue),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    data.trendValue,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AnalyticsUtils.getTrendColor(data.trendValue),
                          fontWeight: FontWeight.w600,
                          fontSize: trendValueFontSize,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

