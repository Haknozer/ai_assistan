import 'package:flutter/material.dart';
import '../../../models/calendar_event.dart';
import '../../../core/theme/app_colors.dart';
import '../../screens/calendar/utils/calendar_utils.dart';

/// Takvim gün hücresi widget'ı
class DayCell extends StatelessWidget {
  final DateTime date;
  final bool isCurrentMonth;
  final bool isToday;
  final bool isPast;
  final List<CalendarEvent> events;
  final VoidCallback onTap;

  const DayCell({
    super.key,
    required this.date,
    required this.isCurrentMonth,
    required this.isToday,
    required this.isPast,
    required this.events,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: isToday
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isToday
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                )
              : null,
        ),
        padding: const EdgeInsets.all(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gün numarası
            Text(
              '${date.day}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    color: isCurrentMonth
                        ? (isPast
                            ? Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withValues(alpha: 0.5)
                            : Theme.of(context).colorScheme.onSurface)
                        : Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withValues(alpha: 0.3),
                  ),
            ),
            const SizedBox(height: 2),

            // Etkinlik göstergeleri (maksimum 3)
            ...events.take(3).map((event) => Container(
                  width: double.infinity,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 2),
                  decoration: BoxDecoration(
                    color: CalendarUtils.getEventTypeColor(event.eventType)
                        .withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                )),

            // Fazla etkinlik varsa göster
            if (events.length > 3)
              Text(
                '+${events.length - 3}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 9,
                      color: AppColors.getPrimaryTextColor(context)
                          .withValues(alpha: 0.6),
                    ),
              ),
          ],
        ),
      ),
    );
  }
}

