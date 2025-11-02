import 'package:flutter/material.dart';
import '../../../models/calendar_event.dart';
import '../../../core/theme/app_colors.dart';
import '../../screens/calendar/utils/calendar_utils.dart';
import '../../screens/calendar/data/mock_events.dart';
import 'day_cell.dart';

/// Takvim grid widget'ı - Ayın günlerini gösterir
class CalendarGrid extends StatelessWidget {
  final DateTime currentMonth;
  final List<CalendarEvent> events;
  final Function(DateTime) onDayTap;

  const CalendarGrid({
    super.key,
    required this.currentMonth,
    required this.events,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.getBorderColor(context).withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Başlık - Haftanın günleri
          _buildWeekdayHeader(context),
          const Divider(height: 1),

          // Takvim günleri
          Expanded(
            child: _buildCalendarDays(context),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: List.generate(7, (index) {
          return Expanded(
            child: Center(
              child: Text(
                CalendarUtils.getDayName(index + 1),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCalendarDays(BuildContext context) {
    final firstDay = CalendarUtils.getFirstDayOfMonth(currentMonth);
    final daysInMonth = CalendarUtils.getDaysInMonth(currentMonth);
    final firstWeekday = firstDay.weekday;

    // Önceki ayın son günlerini hesapla
    final previousMonth = DateTime(currentMonth.year, currentMonth.month - 1);
    final daysInPreviousMonth = CalendarUtils.getDaysInMonth(previousMonth);
    final previousMonthDays = firstWeekday - 1;

    // Toplam gösterilecek gün sayısı (6 hafta * 7 gün = 42)
    const totalCells = 42;

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.0,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        DateTime cellDate;
        bool isCurrentMonth;

        if (index < previousMonthDays) {
          // Önceki ayın günleri
          final day = daysInPreviousMonth - previousMonthDays + index + 1;
          cellDate = DateTime(previousMonth.year, previousMonth.month, day);
          isCurrentMonth = false;
        } else if (index < previousMonthDays + daysInMonth) {
          // Mevcut ayın günleri
          final day = index - previousMonthDays + 1;
          cellDate = DateTime(currentMonth.year, currentMonth.month, day);
          isCurrentMonth = true;
        } else {
          // Sonraki ayın günleri
          final day = index - previousMonthDays - daysInMonth + 1;
          final nextMonth = DateTime(currentMonth.year, currentMonth.month + 1, day);
          cellDate = nextMonth;
          isCurrentMonth = false;
        }

        final dayEvents = MockEvents.getEventsForDay(events, cellDate);
        final isToday = CalendarUtils.isToday(cellDate);
        final isPast = CalendarUtils.isPast(cellDate);

        return DayCell(
          date: cellDate,
          isCurrentMonth: isCurrentMonth,
          isToday: isToday,
          isPast: isPast,
          events: dayEvents,
          onTap: () => onDayTap(cellDate),
        );
      },
    );
  }
}
