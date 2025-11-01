import 'package:flutter/material.dart';

class TaskCompletionCard extends StatelessWidget {
  const TaskCompletionCard({super.key});

  @override
  Widget build(BuildContext context) {
    // Örnek veriler - gerçek veriler API'den gelecek
    const completedTasks = 12;
    const totalTasks = 20;
    const completionRate = (completedTasks / totalTasks);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık Bölümü
          _CardHeader(),

          SizedBox(height: 20),

          // Progress Bar Bölümü
          _ProgressSection(
            completionRate: completionRate,
          ),

          SizedBox(height: 16),

          // Özet Bölümü
          _TaskSummary(
            completedTasks: completedTasks,
            totalTasks: totalTasks,
          ),
        ],
      ),
    );
  }
}

// Kart Başlığı Widget'ı
class _CardHeader extends StatelessWidget {
  const _CardHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Görev Tamamlama Oranı',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Bu haftaki ilerlemeniz',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
        ),
      ],
    );
  }
}

// Progress Bar Bölümü Widget'ı
class _ProgressSection extends StatelessWidget {
  final double completionRate;

  const _ProgressSection({
    required this.completionRate,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        value: completionRate,
        minHeight: 12,
        backgroundColor: Colors.grey.shade200,
        valueColor: AlwaysStoppedAnimation<Color>(
          Colors.green.shade600,
        ),
      ),
    );
  }
}

// Görev Özeti Widget'ı
class _TaskSummary extends StatelessWidget {
  final int completedTasks;
  final int totalTasks;

  const _TaskSummary({
    required this.completedTasks,
    required this.totalTasks,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.green.shade600,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Tamamlanan',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
            ),
          ],
        ),
        Text(
          '$completedTasks / $totalTasks Görev',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
        ),
      ],
    );
  }
}
