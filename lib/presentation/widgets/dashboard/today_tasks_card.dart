import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/task.dart';
import '../../../features/tasks/providers/tasks_provider.dart';

class TodayTasksCard extends ConsumerWidget {
  final double height;

  const TodayTasksCard({
    super.key,
    required this.height,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksNotifierProvider);

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
          // Başlık
          Text(
            'Bugünkü Görevler',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 20),

          // Scrollable task list (gerçek veriden)
          Expanded(
            child: tasksAsync.when(
              data: (tasks) {
                final todayTasks = _filterTodayTasks(tasks);

                if (todayTasks.isEmpty) {
                  return Center(
                    child: Text(
                      'Bugün için görev bulunmuyor.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: todayTasks.length,
                  itemBuilder: (context, index) {
                    final task = todayTasks[index];
                    return _TaskItem(task: task);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text(
                  'Görevler yüklenemedi: $e',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Bugüne ait (dueDate'i bugün olan veya dueDate boşsa bugün oluşturulmuş),
  /// ve tamamlanmamış (pending / inProgress) görevleri filtreler.
  List<Task> _filterTodayTasks(List<Task> tasks) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));

    return tasks.where((task) {
      if (task.status == TaskStatus.completed || task.status == TaskStatus.cancelled) {
        return false;
      }

      DateTime basis;
      if (task.dueDate != null) {
        basis = task.dueDate!;
      } else {
        basis = task.createdAt;
      }

      return basis.isAfter(todayStart.subtract(const Duration(milliseconds: 1))) &&
          basis.isBefore(todayEnd.add(const Duration(milliseconds: 1)));
    }).toList()
      ..sort((a, b) {
        // Önce dueDate'e göre, sonra önceliğe göre sırala
        final aDue = a.dueDate ?? a.createdAt;
        final bDue = b.dueDate ?? b.createdAt;
        final cmp = aDue.compareTo(bDue);
        if (cmp != 0) return cmp;
        return b.priority.index.compareTo(a.priority.index); // urgent > high > ...
      });
  }
}

class _TaskItem extends StatelessWidget {
  final Task task;

  const _TaskItem({
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    final color = _priorityColor(task.priority);

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
                  task.title,
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
                  task.priority.displayName,
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
              task.description?.trim().isNotEmpty == true
                  ? task.description!
                  : 'Açıklama eklenmemiş.',
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
                  task.dueDate != null
                      ? 'Son Tarih: ${task.formattedDueDate}'
                      : 'Son tarih belirlenmemiş',
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

  Color _priorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.urgent:
        return Colors.red;
      case TaskPriority.high:
        return Colors.orange;
      case TaskPriority.medium:
        return Colors.blue;
      case TaskPriority.low:
        return Colors.green;
    }
  }
}
