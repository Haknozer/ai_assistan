import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/analytics/providers/analytics_provider.dart';
import '../../../features/analytics/data/mock_analytics.dart';

class StatsCards extends ConsumerWidget {
  const StatsCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statCardsAsync = ref.watch(statCardsProvider);

    return statCardsAsync.when(
      data: (stats) => _buildGrid(context, stats),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(8),
        child: Text(
          'İstatistikler yüklenemedi: $e',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context, List<StatCardData> stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount;
        double childAspectRatio;
        double mainAxisSpacing;
        double crossAxisSpacing;

        if (constraints.maxWidth > 1200) {
          // Large Desktop
          crossAxisCount = 4;
          childAspectRatio = 1.4;
          mainAxisSpacing = 16;
          crossAxisSpacing = 16;
        } else if (constraints.maxWidth > 600) {
          // Small Desktop / Tablet
          crossAxisCount = 2;
          childAspectRatio = 1.3;
          mainAxisSpacing = 14;
          crossAxisSpacing = 14;
        } else {
          // Mobile
          crossAxisCount = 1;
          childAspectRatio = 2.5;
          mainAxisSpacing = 12;
          crossAxisSpacing = 0;
        }

        // Analytics ekranındaki 4 kartı home için yeniden kullan
        // Sıra: Tamamlanan Görevler, Toplantılar, E-posta, Verimlilik Skoru
        StatCardData? findCard(String title) {
          try {
            return stats.firstWhere((s) => s.title == title);
          } catch (_) {
            return null;
          }
        }

        final completedTasks = findCard('Tamamlanan Görevler');
        final meetings = findCard('Toplantılar');
        final emails = findCard('E-posta');
        final productivity = findCard('Verimlilik Skoru');

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          mainAxisSpacing: mainAxisSpacing,
          crossAxisSpacing: crossAxisSpacing,
          children: [
            _buildDualStatCard(
              context,
              completedTasks?.title ?? 'Tamamlanan Görevler',
              completedTasks?.mainValue ?? '0',
              completedTasks?.trendValue ?? '%0 Tamamlandı',
              Icons.pending_actions_outlined,
              completedTasks?.color ?? Colors.orange,
            ),
            _buildDualStatCard(
              context,
              meetings?.title ?? 'Toplantılar',
              meetings?.mainValue ?? '0',
              meetings?.trendValue ?? 'Bu ay toplantı yok',
              Icons.groups_outlined,
              meetings?.color ?? Colors.blue,
            ),
            _buildDualStatCard(
              context,
              emails?.title ?? 'E-posta',
              emails?.mainValue ?? '0',
              emails?.trendValue ?? 'Önemli e-posta yok',
              Icons.mark_email_unread_outlined,
              emails?.color ?? Colors.purple,
            ),
            _buildDualStatCard(
              context,
              productivity?.title ?? 'Verimlilik Skoru',
              productivity?.mainValue ?? '0%',
              productivity?.trendValue ?? 'Hedef verisi yok',
              Icons.trending_up_outlined,
              productivity?.color ?? Colors.green,
            ),
          ],
        );
      },
    );
  }

  Widget _buildDualStatCard(
    BuildContext context,
    String title,
    String mainValue,
    String subValue,
    IconData icon,
    Color color,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 400;

        // Responsive font scaling based on screen width
        final screenWidth = MediaQuery.of(context).size.width;
        final scaleFactor = (screenWidth / 1200).clamp(0.7, 1.2);

        // Calculate responsive font sizes
        final titleFontSize = ((13 * scaleFactor).clamp(9, 15)).toDouble();
        final mainValueFontSize = ((28 * scaleFactor).clamp(18, 36)).toDouble();
        final subValueFontSize = ((12 * scaleFactor).clamp(9, 14)).toDouble();
        final iconSize = ((18 * scaleFactor).clamp(14, 22)).toDouble();

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
              color: color.withValues(alpha: 0.2),
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
                      title,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: iconSize,
                    ),
                  ),
                ],
              ),
              SizedBox(height: isMobile ? 12 : 16),
              Text(
                mainValue,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: mainValueFontSize,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: isMobile ? 4 : 6),
              Text(
                subValue,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w500,
                      fontSize: subValueFontSize,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}
