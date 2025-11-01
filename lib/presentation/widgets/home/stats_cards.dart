import 'package:flutter/material.dart';

class StatsCards extends StatelessWidget {
  const StatsCards({super.key});

  @override
  Widget build(BuildContext context) {
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
              'Bekleyen Görevler',
              '3',
              '24 Tamamlandı',
              Icons.pending_actions_outlined,
              Colors.orange,
            ),
            _buildDualStatCard(
              context,
              'Bugünkü Toplantılar',
              '2',
              '1 Tamamlandı',
              Icons.groups_outlined,
              Colors.blue,
            ),
            _buildDualStatCard(
              context,
              'Okunmamış E-postalar',
              '8',
              '15 Okundu',
              Icons.mark_email_unread_outlined,
              Colors.purple,
            ),
            _buildDualStatCard(
              context,
              'Verimlilik Skoru',
              '85%',
              '%12 Artış',
              Icons.trending_up_outlined,
              Colors.green,
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
