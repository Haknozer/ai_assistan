import 'package:flutter/material.dart';
import '../../../models/calendar_event.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/html_stripper.dart';
import '../../screens/calendar/utils/calendar_utils.dart';

/// Etkinlik kartı widget'ı
class EventCard extends StatelessWidget {
  final CalendarEvent event;
  final List<CalendarEvent> allEvents; // Tüm event listesi (duplicate kontrolü için)
  final VoidCallback? onTap;

  const EventCard({
    super.key,
    required this.event,
    required this.allEvents,
    this.onTap,
  });

  /// Aynı event'in başka source'lu versiyonu var mı kontrol et
  List<EventSource> _getEventSources() {
    final sources = <EventSource>{event.source};
    
    // Tüm event listesinde aynı event'in başka source'lu versiyonu var mı kontrol et
    for (final otherEvent in allEvents) {
      if (otherEvent.id == event.id) continue; // Aynı event
      
      // Başlık + saat aynı mı?
      final sameTitleAndTime = otherEvent.title.toLowerCase().trim() == event.title.toLowerCase().trim() &&
          otherEvent.startTime.year == event.startTime.year &&
          otherEvent.startTime.month == event.startTime.month &&
          otherEvent.startTime.day == event.startTime.day &&
          otherEvent.startTime.hour == event.startTime.hour;
      
      // Veya detay + saat aynı mı?
      final sameDescriptionAndTime = (otherEvent.description ?? '').isNotEmpty &&
          (event.description ?? '').isNotEmpty &&
          otherEvent.description?.toLowerCase().trim() == event.description?.toLowerCase().trim() &&
          otherEvent.startTime.year == event.startTime.year &&
          otherEvent.startTime.month == event.startTime.month &&
          otherEvent.startTime.day == event.startTime.day &&
          otherEvent.startTime.hour == event.startTime.hour;
      
      if (sameTitleAndTime || sameDescriptionAndTime) {
        sources.add(otherEvent.source);
      }
    }
    
    return sources.toList();
  }

  @override
  Widget build(BuildContext context) {
    final eventColor = CalendarUtils.getEventTypeColor(event.eventType);
    final sources = _getEventSources();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: eventColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                eventColor.withValues(alpha: 0.1),
                AppColors.getCardColor(context),
              ],
              stops: const [0.0, 0.1],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Başlık ve tip ikonu
              Row(
                children: [
                  Icon(
                    CalendarUtils.getEventTypeIcon(event.eventType),
                    color: eventColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Kaynak ikonları (hem Google hem Outlook varsa ikisini de göster)
                  ...sources.map((source) {
                    final sourceColor = CalendarUtils.getEventSourceColor(source);
                    return Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Icon(
                        CalendarUtils.getEventSourceIcon(source),
                        color: sourceColor,
                        size: 16,
                      ),
                    );
                  }),
                ],
              ),

              const SizedBox(height: 8),

              // Zaman
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${CalendarUtils.formatTime(event.startTime)} - ${CalendarUtils.formatTime(event.endTime)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '(${CalendarUtils.calculateDuration(event.startTime, event.endTime)})',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withValues(alpha: 0.7),
                        ),
                  ),
                ],
              ),

              // Lokasyon
              if (event.location != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event.location!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              // Açıklama
              if (event.description != null &&
                  event.description!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  HtmlStripper.cleanIfNeeded(event.description!),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withValues(alpha: 0.8),
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

