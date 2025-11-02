import 'package:flutter/material.dart';
import '../../../models/task.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_colors.dart';
import '../../screens/tasks/utils/task_utils.dart';

/// Görev kartı widget'ı - Sürüklenebilir görev kartı
class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onTap;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Draggable<Task>(
      data: task,
      feedback: Material(
        borderRadius: BorderRadius.circular(12),
        elevation: 8,
        child: Container(
          width: 250,
          decoration: BoxDecoration(
            color: AppColors.getCardColor(context),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: _TaskCardContent(task: task, isDragging: true),
        ),
      ),
      childWhenDragging: Container(
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.3),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: _TaskCardContent(task: task, isDragging: true),
      ),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: AppColors.getBorderColor(context).withValues(alpha: 0.3),
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: _TaskCardContent(task: task),
        ),
      ),
    );
  }
}

class _TaskCardContent extends StatelessWidget {
  final Task task;
  final bool isDragging;

  const _TaskCardContent({
    required this.task,
    this.isDragging = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sürükleme İkonu
          if (!isDragging) ...[
            Row(
              children: [
                Icon(
                  Icons.drag_indicator,
                  size: 16,
                  color: Colors.grey.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 8),
                Text(
                  'Sürükle bırak',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.withValues(alpha: 0.6),
                        fontSize: 10,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],

          // Görev Başlığı ve Öncelik
          Row(
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDragging
                            ? Colors.grey.withValues(alpha: 0.7)
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: TaskUtils.getPriorityColor(task.priority)
                      .withValues(alpha: isDragging ? 0.1 : 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  task.priority.displayName,
                  style: TextStyle(
                    color: TaskUtils.getPriorityColor(task.priority)
                        .withValues(alpha: isDragging ? 0.5 : 1),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          // Görev Açıklaması
          if (task.description != null && task.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              task.description!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDragging
                        ? Colors.grey.withValues(alpha: 0.5)
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              maxLines: isDragging ? 1 : 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // Son Tarih
          if (task.dueDate != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 14,
                  color: isDragging
                      ? Colors.grey.withValues(alpha: 0.4)
                      : (task.isOverdue ? AppTheme.errorColor : Colors.grey),
                ),
                const SizedBox(width: 4),
                Text(
                  task.formattedDueDate,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDragging
                            ? Colors.grey.withValues(alpha: 0.5)
                            : (task.isOverdue ? AppTheme.errorColor : Colors.grey),
                        fontWeight: task.isOverdue && !isDragging
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

