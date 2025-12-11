import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/tasks/tasks_feature.dart';
import 'task_card.dart';

/// Kanban sütunu widget'ı - Görevlerin sürüklenip bırakılabileceği sütun
class KanbanColumn extends StatefulWidget {
  final TaskStatus status;
  final List<Task> tasks;
  final Function(Task, TaskStatus) onTaskMoved;

  const KanbanColumn({
    super.key,
    required this.status,
    required this.tasks,
    required this.onTaskMoved,
  });

  @override
  State<KanbanColumn> createState() => _KanbanColumnState();
}

class _KanbanColumnState extends State<KanbanColumn> {
  @override
  Widget build(BuildContext context) {
    return DragTarget<Task>(
      onWillAcceptWithDetails: (details) {
        return details.data.status != widget.status;
      },
      onAcceptWithDetails: (details) {
        widget.onTaskMoved(details.data, widget.status);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.getCardColor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHovering
                  ? TaskUtils.getStatusColor(widget.status).withValues(alpha: 0.5)
                  : AppColors.getBorderColor(context).withValues(alpha: 0.5),
              width: isHovering ? 2 : 1,
            ),
            boxShadow: isHovering
                ? [
                    BoxShadow(
                      color: TaskUtils.getStatusColor(widget.status).withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Column Header
              _buildColumnHeader(isHovering),

              // Tasks List
              Expanded(
                child: widget.tasks.isEmpty
                    ? _buildEmptyColumn(isHovering)
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: widget.tasks.length,
                        itemBuilder: (context, index) {
                          final task = widget.tasks[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: TaskCard(task: task),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildColumnHeader(bool isHovering) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHovering
            ? TaskUtils.getStatusColor(widget.status).withValues(alpha: 0.15)
            : TaskUtils.getStatusColor(widget.status).withValues(alpha: 0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Icon(
            TaskUtils.getStatusIcon(widget.status),
            color: TaskUtils.getStatusColor(widget.status),
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            widget.status.displayName,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: TaskUtils.getStatusColor(widget.status),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: TaskUtils.getStatusColor(widget.status).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${widget.tasks.length}',
              style: TextStyle(
                color: TaskUtils.getStatusColor(widget.status),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          if (isHovering) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_downward,
              color: TaskUtils.getStatusColor(widget.status),
              size: 16,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyColumn(bool isHovering) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            TaskUtils.getStatusIcon(widget.status),
            size: isHovering ? 56 : 48,
            color: isHovering
                ? TaskUtils.getStatusColor(widget.status).withValues(alpha: 0.7)
                : Colors.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 8),
          Text(
            isHovering ? 'Görevi buraya bırakın' : 'Bu kategoride görev bulunmuyor',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isHovering ? TaskUtils.getStatusColor(widget.status).withValues(alpha: 0.8) : Colors.grey,
                  fontWeight: isHovering ? FontWeight.w600 : FontWeight.normal,
                ),
          ),
          if (isHovering) ...[
            const SizedBox(height: 4),
            Icon(
              Icons.arrow_downward,
              size: 20,
              color: TaskUtils.getStatusColor(widget.status).withValues(alpha: 0.7),
            ),
          ],
        ],
      ),
    );
  }
}
