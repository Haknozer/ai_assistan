import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Görev sayfası başlığı widget'ı
class TasksPageHeader extends StatelessWidget {
  final VoidCallback onAddTask;
  final bool isDesktop;

  const TasksPageHeader({
    super.key,
    required this.onAddTask,
    this.isDesktop = true,
  });

  @override
  Widget build(BuildContext context) {
    if (isDesktop) {
      return Row(
        children: [
          _buildHeaderContent(context),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: onAddTask,
            icon: const Icon(Icons.add_task),
            label: const Text('Görev Ekle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(child: _buildHeaderContent(context)),
          IconButton.filled(
            onPressed: onAddTask,
            icon: const Icon(Icons.add),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(40, 40),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildHeaderContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Görev Yönetimi',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        Text(
          'Görevlerinizi oluşturun, düzenleyin ve takip edin',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
        ),
      ],
    );
  }
}

