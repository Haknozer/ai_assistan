import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_colors.dart';
import '../../screens/calendar/utils/calendar_utils.dart';

/// Ay ve yıl seçimi widget'ı
class MonthSelector extends StatelessWidget {
  final DateTime currentMonth;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onTodayTap;

  const MonthSelector({
    super.key,
    required this.currentMonth,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onTodayTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.getBorderColor(context).withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Önceki Ay Butonu
          IconButton(
            onPressed: onPreviousMonth,
            icon: const Icon(Icons.chevron_left),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              foregroundColor: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 16),

          // Ay ve Yıl
          Expanded(
            child: Text(
              '${CalendarUtils.getMonthName(currentMonth.month)} ${currentMonth.year}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(width: 16),

          // Sonraki Ay Butonu
          IconButton(
            onPressed: onNextMonth,
            icon: const Icon(Icons.chevron_right),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              foregroundColor: AppTheme.primaryColor,
            ),
          ),

          const SizedBox(width: 16),

          // Bugün Butonu
          TextButton.icon(
            onPressed: onTodayTap,
            icon: const Icon(Icons.today, size: 18),
            label: const Text('Bugün'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }
}

