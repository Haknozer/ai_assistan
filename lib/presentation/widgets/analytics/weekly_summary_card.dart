import 'package:flutter/material.dart';

/// Haftalık Özet Card'ı
class WeeklySummaryCard extends StatelessWidget {
  const WeeklySummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
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
          _buildSummaryContent(context),
        ],
      ),
    );
  }

  Widget _buildSummaryContent(BuildContext context) {
    return Column(
      children: [
        // Başarı Durumu
        _buildSuccessRow(
          context,
          '🎯',
          'Haftalık Hedefler',
          'Toplam 8 hedeften 6\'sı tamamlandı',
          Colors.green,
        ),
        const SizedBox(height: 16),

        // Görev Durumu
        _buildSuccessRow(
          context,
          '✓',
          'Tamamlanan Görevler',
          '27 görev tamamlandı, %85 başarı oranı',
          Colors.blue,
        ),
        const SizedBox(height: 16),

        // Toplantı Durumu
        _buildSuccessRow(
          context,
          '📅',
          'Toplantılar',
          '5 toplantı tamamlandı, 2\'si ertelendi',
          Colors.orange,
        ),
        const SizedBox(height: 16),

        // E-posta Durumu
        _buildSuccessRow(
          context,
          '✉️',
          'E-posta İletişimi',
          '42 önemli e-posta işlendi',
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
                  'Bu hafta en yüksek verimlilik Salı günü ölçüldü. Önümüzdeki hafta daha fazla odaklanılarak hedeflerin tamamının tamamlanması hedefleniyor.',
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
          child: Text(
            _getStatusText(title),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  String _getStatusText(String title) {
    switch (title) {
      case 'Haftalık Hedefler':
        return '%75';
      case 'Tamamlanan Görevler':
        return 'Başarılı';
      case 'Toplantılar':
        return '%71';
      case 'E-posta İletişimi':
        return 'Tamamlandı';
      default:
        return '';
    }
  }
}