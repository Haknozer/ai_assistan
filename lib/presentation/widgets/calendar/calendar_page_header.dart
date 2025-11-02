import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Takvim sayfası başlığı widget'ı
class CalendarPageHeader extends StatelessWidget {
  final VoidCallback onAddEvent;
  final bool isDesktop;

  const CalendarPageHeader({
    super.key,
    required this.onAddEvent,
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
            onPressed: onAddEvent,
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Etkinlik Ekle'),
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
            onPressed: onAddEvent,
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
          'Takvim',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        Text(
          'Etkinliklerinizi planlayın ve yönetin',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

