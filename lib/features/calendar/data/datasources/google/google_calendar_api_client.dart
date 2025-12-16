import 'package:flutter/foundation.dart';
import 'package:ai_asisstan/core/api/api_client.dart';
import 'package:ai_asisstan/core/api/api_endpoints.dart';
import 'package:ai_asisstan/core/api/api_exceptions.dart';
import 'package:ai_asisstan/models/calendar_event.dart';
import 'package:ai_asisstan/core/utils/html_stripper.dart';

/// Google Calendar API client - Google Calendar API çağrılarını yönetir
class GoogleCalendarApiClient {
  final ApiClient _apiClient;

  GoogleCalendarApiClient({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Calendar listesini çekme
  Future<List<Map<String, dynamic>>> getCalendars({
    required String accessToken,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.calendars,
        accessToken: accessToken,
      );

      final calendarsList = response['items'] as List<dynamic>? ?? [];
      return calendarsList.map((item) => item as Map<String, dynamic>).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to fetch calendars from Google Calendar API: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Event listesini çekme
  Future<List<CalendarEvent>> getEvents({
    String? calendarId,
    DateTime? timeMin,
    DateTime? timeMax,
    int? maxResults,
    required String accessToken,
    int? userId,
  }) async {
    try {
      final endpoint = calendarId != null && calendarId != 'primary'
          ? ApiEndpoints.eventsByCalendar(calendarId)
          : ApiEndpoints.events;

      final queryParams = <String, dynamic>{};
      
      if (timeMin != null) {
        queryParams['timeMin'] = timeMin.toUtc().toIso8601String();
      } else {
        // Varsayılan olarak bugünden başla
        queryParams['timeMin'] = DateTime.now().toUtc().toIso8601String();
      }
      
      if (timeMax != null) {
        queryParams['timeMax'] = timeMax.toUtc().toIso8601String();
      }
      
      if (maxResults != null) {
        queryParams['maxResults'] = maxResults;
      }

      // Order by start time
      queryParams['orderBy'] = 'startTime';
      queryParams['singleEvents'] = true;

      final response = await _apiClient.get(
        endpoint,
        queryParameters: queryParams,
        accessToken: accessToken,
      );

      final eventsList = response['items'] as List<dynamic>? ?? [];
      
      return eventsList.map((item) {
        try {
          return _parseGoogleCalendarEvent(item as Map<String, dynamic>, userId: userId);
        } catch (e) {
          debugPrint('Event parse hatası: ${e.toString()}');
          return null;
        }
      }).whereType<CalendarEvent>().toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to fetch events from Google Calendar API: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Tek event detayını çekme
  Future<CalendarEvent?> getEventById({
    required String eventId,
    String? calendarId,
    required String accessToken,
    int? userId,
  }) async {
    try {
      final calId = calendarId ?? 'primary';
      final response = await _apiClient.get(
        ApiEndpoints.eventById(calId, eventId),
        accessToken: accessToken,
      );

      return _parseGoogleCalendarEvent(response, userId: userId);
    } on NotFoundException {
      debugPrint('getEventById: Event bulunamadı (eventId: $eventId)');
      return null;
    } catch (e) {
      debugPrint('getEventById hatası (eventId: $eventId): ${e.toString()}');
      return null;
    }
  }

  /// Event oluşturma
  Future<CalendarEvent> createEvent({
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    String? description,
    String? location,
    EventType? eventType,
    String? calendarId,
    required String accessToken,
    required int userId,
  }) async {
    try {
      final calId = calendarId ?? 'primary';
      
      // Google Calendar API için event data oluştur
      // Null değerleri dahil etme
      final eventData = <String, dynamic>{
        'summary': title,
        'start': {
          'dateTime': startTime.toUtc().toIso8601String(),
          'timeZone': 'UTC',
        },
        'end': {
          'dateTime': endTime.toUtc().toIso8601String(),
          'timeZone': 'UTC',
        },
      };

      // Opsiyonel alanları ekle (null değilse)
      if (description != null && description.isNotEmpty) {
        eventData['description'] = description;
      }
      if (location != null && location.isNotEmpty) {
        eventData['location'] = location;
      }
      
      // Event type'a göre colorId ekle (Google Calendar renkleri için)
      // colorId: "11" = meeting, "5" = social, "9" = task, "10" = appointment
      if (eventType != null) {
        switch (eventType) {
          case EventType.meeting:
            eventData['colorId'] = '11'; // Meeting (Mavi)
            debugPrint('📅 Google Calendar - colorId 11 (meeting) eklendi');
            break;
          case EventType.personal:
            eventData['colorId'] = '5'; // Social (Mor)
            debugPrint('📅 Google Calendar - colorId 5 (social) eklendi');
            break;
          case EventType.task:
            eventData['colorId'] = '9'; // Task (Turuncu)
            debugPrint('📅 Google Calendar - colorId 9 (task) eklendi');
            break;
          case EventType.appointment:
            eventData['colorId'] = '10'; // Appointment (Yeşil)
            debugPrint('📅 Google Calendar - colorId 10 (appointment) eklendi');
            break;
          default:
            // Diğer durumlar için colorId ekleme
            break;
        }
      }

      // Debug: Request body'yi logla
      debugPrint('📤 Google Calendar API - Event oluşturma isteği:');
      debugPrint('  URL: ${ApiEndpoints.createEvent(calId)}');
      debugPrint('  Body: ${eventData.toString()}');
      debugPrint('  Start Time: ${startTime.toUtc().toIso8601String()}');
      debugPrint('  End Time: ${endTime.toUtc().toIso8601String()}');

      final response = await _apiClient.post(
        ApiEndpoints.createEvent(calId),
        body: eventData,
        accessToken: accessToken,
      );

      debugPrint('✅ Google Calendar API - Event başarıyla oluşturuldu');

      // Parse edilen event'e eventType'ı manuel olarak set et
      // (API response'unda colorId olmayabilir veya farklı olabilir)
      final parsedEvent = _parseGoogleCalendarEvent(response, userId: userId);
      if (eventType != null) {
        return parsedEvent.copyWith(eventType: eventType);
      }
      return parsedEvent;
    } on ValidationException catch (e) {
      // HTTP 400 hatası için detaylı log
      debugPrint('❌ Google Calendar API - Validation hatası (400):');
      debugPrint('  Message: ${e.message}');
      debugPrint('  Errors: ${e.errors}');
      debugPrint('  Original Error: ${e.originalError}');
      rethrow;
    } on ApiException catch (e) {
      debugPrint('❌ Google Calendar API - API hatası: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('❌ Google Calendar API - Beklenmeyen hata: ${e.toString()}');
      throw ApiException(
        message: 'Failed to create event in Google Calendar API: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Event güncelleme
  Future<CalendarEvent> updateEvent({
    required String eventId,
    String? title,
    DateTime? startTime,
    DateTime? endTime,
    String? description,
    String? location,
    EventType? eventType,
    String? calendarId,
    required String accessToken,
    required int userId,
  }) async {
    try {
      final calId = calendarId ?? 'primary';
      
      final eventData = <String, dynamic>{};
      
      if (title != null) {
        eventData['summary'] = title;
      }
      if (description != null) {
        eventData['description'] = description;
      }
      if (location != null) {
        eventData['location'] = location;
      }
      if (startTime != null) {
        eventData['start'] = {
          'dateTime': startTime.toUtc().toIso8601String(),
          'timeZone': 'UTC',
        };
      }
      if (endTime != null) {
        eventData['end'] = {
          'dateTime': endTime.toUtc().toIso8601String(),
          'timeZone': 'UTC',
        };
      }

      final response = await _apiClient.put(
        ApiEndpoints.updateEvent(calId, eventId),
        body: eventData,
        accessToken: accessToken,
      );

      return _parseGoogleCalendarEvent(response, userId: userId);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to update event in Google Calendar API: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Event silme
  Future<void> deleteEvent({
    required String eventId,
    String? calendarId,
    required String accessToken,
  }) async {
    try {
      final calId = calendarId ?? 'primary';
      
      await _apiClient.delete(
        ApiEndpoints.deleteEvent(calId, eventId),
        accessToken: accessToken,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to delete event from Google Calendar API: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Google Calendar event'ini CalendarEvent modeline çevir
  CalendarEvent _parseGoogleCalendarEvent(
    Map<String, dynamic> eventData, {
    int? userId,
  }) {
    final id = eventData['id'] as String?;
    final summary = eventData['summary'] as String? ?? 'Etkinlik';
    final rawDescription = eventData['description'] as String?;
    
    // Description'ı temizle - HTML içeriyorsa plain text'e çevir
    String? description;
    if (rawDescription != null && rawDescription.isNotEmpty) {
      // HTML içeriyorsa (HTML tag'leri varsa) temizle
      description = HtmlStripper.cleanIfNeeded(rawDescription);
      if (HtmlStripper.containsHtmlTags(rawDescription)) {
        debugPrint('Google Calendar - HTML içerik temizlendi: ${description.length} karakter');
      }
    }
    
    final location = eventData['location'] as String?;
    
    // Start time
    final startData = eventData['start'] as Map<String, dynamic>?;
    DateTime startTime;
    if (startData?['dateTime'] != null) {
      startTime = DateTime.parse(startData!['dateTime'] as String).toLocal();
    } else if (startData?['date'] != null) {
      // All-day event
      final dateStr = startData!['date'] as String;
      startTime = DateTime.parse(dateStr);
    } else {
      startTime = DateTime.now();
    }
    
    // End time
    final endData = eventData['end'] as Map<String, dynamic>?;
    DateTime endTime;
    if (endData?['dateTime'] != null) {
      endTime = DateTime.parse(endData!['dateTime'] as String).toLocal();
    } else if (endData?['date'] != null) {
      // All-day event
      final dateStr = endData!['date'] as String;
      endTime = DateTime.parse(dateStr).add(const Duration(days: 1));
    } else {
      endTime = startTime.add(const Duration(hours: 1));
    }
    
    // Created and updated times
    final createdStr = eventData['created'] as String?;
    final updatedStr = eventData['updated'] as String?;
    final createdAt = createdStr != null ? DateTime.parse(createdStr) : DateTime.now();
    final updatedAt = updatedStr != null ? DateTime.parse(updatedStr) : DateTime.now();
    
    // Event type - Önce colorId'den çıkar (n8n'den gelen event'lerde kategori bilgisi burada)
    // colorId: "11" = meeting, "5" = social, "9" = task, "10" = appointment
    EventType eventType = EventType.personal;
    final colorId = eventData['colorId'] as String?;
    if (colorId != null && colorId.isNotEmpty) {
      switch (colorId) {
        case '11': // Meeting
          eventType = EventType.meeting;
          debugPrint('📅 Google Calendar - colorId 11 (meeting) bulundu');
          break;
        case '5': // Social
          eventType = EventType.personal; // Social -> Personal
          debugPrint('📅 Google Calendar - colorId 5 (social) bulundu');
          break;
        case '9': // Task
          eventType = EventType.task;
          debugPrint('📅 Google Calendar - colorId 9 (task) bulundu');
          break;
        case '10': // Appointment
          eventType = EventType.appointment;
          debugPrint('📅 Google Calendar - colorId 10 (appointment) bulundu');
          break;
        default:
          // colorId varsa ama tanınmıyorsa, description'dan çıkar
          if (description != null) {
            final descLower = description.toLowerCase();
            if (descLower.contains('toplantı') || descLower.contains('meeting')) {
              eventType = EventType.meeting;
            } else if (descLower.contains('randevu') || descLower.contains('appointment')) {
              eventType = EventType.appointment;
            } else if (descLower.contains('görev') || descLower.contains('task')) {
              eventType = EventType.task;
            }
          }
      }
    } else {
      // colorId yoksa, description'dan çıkar (fallback)
      if (description != null) {
        final descLower = description.toLowerCase();
        if (descLower.contains('toplantı') || descLower.contains('meeting')) {
          eventType = EventType.meeting;
        } else if (descLower.contains('randevu') || descLower.contains('appointment')) {
          eventType = EventType.appointment;
        } else if (descLower.contains('görev') || descLower.contains('task')) {
          eventType = EventType.task;
        }
      }
    }

    final calendarEvent = CalendarEvent(
      id: null, // Local ID (Google Calendar ID externalId'de saklanacak)
      userId: userId ?? 0,
      title: summary,
      description: description,
      startTime: startTime,
      endTime: endTime,
      location: location,
      eventType: eventType,
      source: EventSource.google,
      externalId: id, // Google Calendar event ID
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
    
    debugPrint('📅 Google Calendar Event - Title: $summary, EventType: ${eventType.name}');
    
    return calendarEvent;
  }

}

