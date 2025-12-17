import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/analytics/providers/analytics_provider.dart';
import '../../../features/analytics/data/mock_analytics.dart';

/// Haftalık Özet Card'ı - gerçek analytics verisine bağlı
class WeeklySummaryCard extends ConsumerWidget {
  const WeeklySummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statCardsAsync = ref.watch(statCardsProvider);

    return Container(
      padding: const EdgeInsets.all(24),
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
          Row(
            children: [
              Icon(
                Icons.summarize,
                size: 24,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                'Haftalık Özet',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Bu haftaki performansınızın genel görünümü',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
          ),
          const SizedBox(height: 24),

          // Özet İçeriği
          statCardsAsync.when(
            data: (stats) => _buildSummaryContent(context, stats),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                'Haftalık özet yüklenemedi: $e',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryContent(BuildContext context, List<StatCardData> stats) {
    // Stat kartlarını başlığa göre bul
    StatCardData? findCard(String title) {
      try {
        return stats.firstWhere((s) => s.title == title);
      } catch (_) {
        return null;
      }
    }

    final tasksCard = findCard('Tamamlanan Görevler');
    final meetingsCard = findCard('Toplantılar');
    final emailCard = findCard('E-posta');
    final productivityCard = findCard('Verimlilik Skoru');

    // Güvenlik için fallback açıklamalar
    final completedTasksText = tasksCard != null
        ? '${tasksCard.mainValue} görev tamamlandı, ${tasksCard.trendValue.toLowerCase()}.'
        : 'Bu hafta görev istatistiği bulunamadı.';

    final meetingsText = meetingsCard != null
        ? '${meetingsCard.mainValue}, ${meetingsCard.trendValue.toLowerCase()}.'
        : 'Toplantı istatistiği bulunamadı.';

    final emailText = emailCard != null
        ? '${emailCard.mainValue} e-posta işlendi, ${emailCard.trendValue.toLowerCase()}.'
        : 'E-posta istatistiği bulunamadı.';

    final productivityText = productivityCard != null
        ? 'Bu haftaki verimlilik skoru ${productivityCard.mainValue}, '
            '${productivityCard.trendValue.toLowerCase()}.'
        : 'Verimlilik skoru hesaplanamadı.';

    return Column(
      children: [
        // Başarı Durumu / Verimlilik
        _buildSuccessRow(
          context,
          '🎯',
          'Haftalık Hedefler',
          productivityText,
          Colors.green,
        ),
        const SizedBox(height: 16),

        // Görev Durumu
        _buildSuccessRow(
          context,
          '✓',
          'Tamamlanan Görevler',
          completedTasksText,
          Colors.blue,
        ),
        const SizedBox(height: 16),

        // Toplantı Durumu
        _buildSuccessRow(
          context,
          '📅',
          'Toplantılar',
          meetingsText,
          Colors.orange,
        ),
        const SizedBox(height: 16),

        // E-posta Durumu
        _buildSuccessRow(
          context,
          '✉️',
          'E-posta İletişimi',
          emailText,
          Colors.purple,
        ),
        const SizedBox(height: 24),

        // Notlar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Bu özet, görevleriniz, toplantılarınız ve e-postalarınızdan hesaplanan gerçek verimlilik skoruna göre oluşturuldu.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                        height: 1.4,
                      ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessRow(
    BuildContext context,
    String emoji,
    String title,
    String description,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }
}
