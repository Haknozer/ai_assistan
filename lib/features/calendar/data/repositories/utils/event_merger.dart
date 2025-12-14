import 'package:ai_asisstan/models/calendar_event.dart';
import 'package:ai_asisstan/core/utils/html_stripper.dart';
import 'package:flutter/foundation.dart';

/// Event birleştirme yardımcı sınıfı
class EventMerger {
  /// Event'leri birleştir (duplicate'leri önle)
  /// Önce external ID'ye göre, sonra title + startTime'a göre kontrol eder
  static List<CalendarEvent> mergeEvents(
    List<CalendarEvent> existingEvents,
    List<CalendarEvent> newEvents,
  ) {
    final existingExternalIds = existingEvents
        .where((e) => e.externalId != null && e.externalId!.isNotEmpty)
        .map((e) => e.externalId!)
        .toSet();

    // Title + startTime kombinasyonları (duplicate kontrolü için)
    final existingEventKeys = existingEvents.map((e) => _getEventKey(e)).toSet();
    // Detay + startTime kombinasyonları (başlık + saat aynı değilse kontrol için)
    final existingDetailKeys = existingEvents.map((e) => _getEventDetailKey(e)).toSet();

    final merged = List<CalendarEvent>.from(existingEvents);
    int duplicateCount = 0;

    for (final event in newEvents) {
      // Önce external ID kontrolü
      if (event.externalId != null && existingExternalIds.contains(event.externalId)) {
        duplicateCount++;
        continue; // Duplicate, atla
      }

      // External ID yoksa veya farklıysa, önce title + startTime kontrolü yap
      final eventKey = _getEventKey(event);
      if (existingEventKeys.contains(eventKey)) {
        // Aynı başlık ve zaman - muhtemelen duplicate (farklı provider'dan)
        duplicateCount++;
        continue;
      }

      // Başlık + saat aynı değilse, detay + saat kontrolü yap
      final eventDetailKey = _getEventDetailKey(event);
      if (existingDetailKeys.contains(eventDetailKey)) {
        // Aynı detay ve zaman - muhtemelen duplicate (farklı provider'dan)
        duplicateCount++;
        continue;
      }

      // Yeni event, ekle
      merged.add(event);
      if (event.externalId != null) {
        existingExternalIds.add(event.externalId!);
      }
      existingEventKeys.add(eventKey);
      existingDetailKeys.add(eventDetailKey);
    }

    if (duplicateCount > 0) {
      debugPrint('🔄 EventMerger: $duplicateCount duplicate event atlandı');
    }

    // Tarihe göre sırala
    merged.sort((a, b) => a.startTime.compareTo(b.startTime));

    return merged;
  }

  /// Event için unique key oluştur (title + startTime veya description + startTime)
  /// Timezone farklarını hesaba katarak ±1 saat tolerans ver
  static String _getEventKey(CalendarEvent event) {
    // Başlığı normalize et (küçük harf, boşlukları temizle)
    final normalizedTitle = event.title.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
    
    // Start time'ı saat bazında normalize et (dakika ve saniyeyi yok say)
    // Bu sayede timezone farklarından kaynaklanan küçük farkları görmezden geliriz
    final normalizedTime = DateTime(
      event.startTime.year,
      event.startTime.month,
      event.startTime.day,
      event.startTime.hour,
    );
    
    return '$normalizedTitle|${normalizedTime.toIso8601String()}';
  }

  /// Event için detay + saat key'i oluştur (başlık + saat aynı değilse kullanılır)
  static String _getEventDetailKey(CalendarEvent event) {
    // Detayı önce HTML'den temizle (eğer HTML içeriyorsa), sonra normalize et
    String? cleanedDescription = event.description;
    if (cleanedDescription != null && cleanedDescription.isNotEmpty) {
      cleanedDescription = HtmlStripper.cleanIfNeeded(cleanedDescription);
    }
    
    // Detayı normalize et (küçük harf, boşlukları temizle)
    final normalizedDescription = (cleanedDescription ?? '').toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
    
    // Eğer detay boşsa, başlığı kullan
    final keyContent = normalizedDescription.isEmpty ? event.title.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ') : normalizedDescription;
    
    // Start time'ı saat bazında normalize et
    final normalizedTime = DateTime(
      event.startTime.year,
      event.startTime.month,
      event.startTime.day,
      event.startTime.hour,
    );
    
    return '$keyContent|${normalizedTime.toIso8601String()}';
  }

  /// Event'leri tarihe göre sırala
  static List<CalendarEvent> sortByDate(List<CalendarEvent> events) {
    final sorted = List<CalendarEvent>.from(events);
    sorted.sort((a, b) => a.startTime.compareTo(b.startTime));
    return sorted;
  }
}

