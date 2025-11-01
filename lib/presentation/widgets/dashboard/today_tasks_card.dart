import 'package:flutter/material.dart';

class TodayTasksCard extends StatelessWidget {
  final double height;

  const TodayTasksCard({
    super.key,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    // Örnek görev verileri
    final tasks = [
      {
        'title': 'Proje sunumu hazırlama',
        'priority': 'Yüksek',
        'description': 'Sprint sonu sunumu için slaytlar ve demo hazırlanması gerekiyor',
        'deadline': '2024-11-02',
        'color': Colors.red,
      },
      {
        'title': 'Müşteri toplantısı',
        'priority': 'Orta',
        'description': 'Yeni özellik taleplerinin görüşüleceği Zoom toplantısı',
        'deadline': '2024-11-01',
        'color': Colors.blue,
      },
      {
        'title': 'Kod incelemesi',
        'priority': 'Yüksek',
        'description': 'Yeni özellik branch\'inin kod review süreci',
        'deadline': '2024-11-01',
        'color': Colors.purple,
      },
      {
        'title': 'Rapor tamamlama',
        'priority': 'Düşük',
        'description': 'Aylık performans ve ilerleme raporunun hazırlanması',
        'deadline': '2024-11-05',
        'color': Colors.green,
      },
      {
        'title': 'E-posta yanıtları',
        'priority': 'Orta',
        'description': 'Müşteri ve ekip gelen kutusunun kontrol edilip yanıtlanması',
        'deadline': '2024-11-01',
        'color': Colors.orange,
      },
    ];

    return Container(
      height: height,
      padding: const EdgeInsets.all(20),
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
          color: Colors.orange.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sadece başlık
          Text(
            'Bugünkü Görevler',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 20),
          // Scrollable task list
          Expanded(
            child: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return _TaskItem(
                  title: task['title'] as String,
                  priority: task['priority'] as String,
                  description: task['description'] as String,
                  deadline: task['deadline'] as String,
                  color: task['color'] as Color,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskItem extends StatelessWidget {
  final String title;
  final String priority;
  final String description;
  final String deadline;
  final Color color;

  const _TaskItem({
    required this.title,
    required this.priority,
    required this.description,
    required this.deadline,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Format deadline
    final deadlineDate = DateTime.parse(deadline);
    final formattedDeadline = '${deadlineDate.day}/${deadlineDate.month}/${deadlineDate.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Üst satır: Daire, Başlık, Öncelik
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Yuvarlak renkli daire
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              // Başlık
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              // Öncelik badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: color.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  priority,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Özet
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 8),
          // Son tarih
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  'Son Tarih: $formattedDeadline',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
