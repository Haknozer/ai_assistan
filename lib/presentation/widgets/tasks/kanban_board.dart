import 'package:flutter/material.dart';
import '../../../models/task.dart';
import 'kanban_column.dart';

/// Kanban panosu widget'ı - Tüm görev sütunlarını içerir
class KanbanBoard extends StatelessWidget {
  final Map<TaskStatus, List<Task>> tasksByStatus;
  final Function(Task, TaskStatus) onTaskStatusChanged;
  final bool isDesktop;

  const KanbanBoard({
    super.key,
    required this.tasksByStatus,
    required this.onTaskStatusChanged,
    this.isDesktop = true,
  });

  @override
  Widget build(BuildContext context) {
    if (isDesktop) {
      // Desktop - Yatay kartlar
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: TaskStatus.values.map((status) {
          final tasks = tasksByStatus[status] ?? [];
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: KanbanColumn(
                status: status,
                tasks: tasks,
                onTaskMoved: onTaskStatusChanged,
              ),
            ),
          );
        }).toList(),
      );
    } else {
      // Mobil - Dikey sütunlar
      return Column(
        children: TaskStatus.values.map((status) {
          final tasks = tasksByStatus[status] ?? [];
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: KanbanColumn(
                status: status,
                tasks: tasks,
                onTaskMoved: onTaskStatusChanged,
              ),
            ),
          );
        }).toList(),
      );
    }
  }
}

