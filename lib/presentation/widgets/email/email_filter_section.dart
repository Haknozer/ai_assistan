import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// E-posta filtreleme bölümü
class EmailFilterSection extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterChanged;

  const EmailFilterSection({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  final List<String> filters = const [
    'Tümü',
    'Okunmamış',
    'Önemli',
    'İş',
    'Spam',
    'Gönderilen',
    'Taslak',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = selectedFilter == filter;

          return GestureDetector(
            onTap: () => onFilterChanged(filter),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? Theme.of(context).colorScheme.primary : AppColors.getBorderColor(context),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Filtre ikonu
                  Icon(
                    _getFilterIcon(filter),
                    size: 16,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 6),
                  // Filtre metni
                  Text(
                    filter,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getFilterIcon(String filter) {
    switch (filter) {
      case 'Tümü':
        return Icons.email_outlined;
      case 'Okunmamış':
        return Icons.mark_email_unread_outlined;
      case 'Önemli':
        return Icons.star_border_outlined;
      case 'İş':
        return Icons.work_outline;
      case 'Spam':
        return Icons.report_outlined;
      case 'Gönderilen':
        return Icons.send_outlined;
      case 'Taslak':
        return Icons.edit_outlined;
      default:
        return Icons.email_outlined;
    }
  }
}
