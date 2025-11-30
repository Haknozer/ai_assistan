import 'package:flutter/foundation.dart';
import 'package:ai_asisstan/models/calendar_event.dart';
import '../calendar_local_repository.dart';

/// Event senkronizasyon yardımcı sınıfı
class EventSyncHelper {
  /// Yeni event'leri local database'e kaydet (sadece yeni olanlar)
  static Future<void> syncNewEventsToLocal({
    required List<CalendarEvent> remoteEvents,
    required CalendarLocalRepository localRepository,
    required int userId,
    required EventSource source,
  }) async {
    if (remoteEvents.isEmpty) return;

    try {
      // Mevcut local event'leri kontrol et (external ID'ye göre)
      final externalIds = remoteEvents.map((e) => e.externalId).whereType<String>().toList();
      if (externalIds.isEmpty) return;

      final existingLocalEvents = await localRepository.getEvents(
        userId: userId,
        source: source,
        externalIdList: externalIds,
      );

      final existingExternalIds = existingLocalEvents
          .where((e) => e.externalId != null && e.externalId!.isNotEmpty)
          .map((e) => e.externalId!)
          .toSet();

      // Sadece yeni event'leri kaydet
      int savedCount = 0;
      for (final event in remoteEvents) {
        if (event.externalId != null && !existingExternalIds.contains(event.externalId)) {
          await localRepository.saveEvent(event.copyWith(source: source));
          savedCount++;
        }
      }

      if (savedCount > 0) {
        final providerName = source == EventSource.google ? 'Google Calendar' : 'Outlook Calendar';
        debugPrint('✅ $savedCount $providerName event local database\'e kaydedildi');
      }
    } catch (e) {
      final providerName = source == EventSource.google ? 'Google Calendar' : 'Outlook Calendar';
      debugPrint('⚠️ $providerName event\'leri local database\'e kaydedilemedi: $e');
    }
  }
}

