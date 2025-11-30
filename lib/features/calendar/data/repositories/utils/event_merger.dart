import 'package:ai_asisstan/models/calendar_event.dart';

/// Event birleştirme yardımcı sınıfı
class EventMerger {
  /// Event'leri external ID'ye göre birleştir (duplicate'leri önle)
  static List<CalendarEvent> mergeEvents(
    List<CalendarEvent> existingEvents,
    List<CalendarEvent> newEvents,
  ) {
    final existingExternalIds = existingEvents
        .where((e) => e.externalId != null && e.externalId!.isNotEmpty)
        .map((e) => e.externalId!)
        .toSet();

    final merged = List<CalendarEvent>.from(existingEvents);

    for (final event in newEvents) {
      if (event.externalId == null || !existingExternalIds.contains(event.externalId)) {
        merged.add(event);
        if (event.externalId != null) {
          existingExternalIds.add(event.externalId!);
        }
      }
    }

    // Tarihe göre sırala
    merged.sort((a, b) => a.startTime.compareTo(b.startTime));

    return merged;
  }

  /// Event'leri tarihe göre sırala
  static List<CalendarEvent> sortByDate(List<CalendarEvent> events) {
    final sorted = List<CalendarEvent>.from(events);
    sorted.sort((a, b) => a.startTime.compareTo(b.startTime));
    return sorted;
  }
}

