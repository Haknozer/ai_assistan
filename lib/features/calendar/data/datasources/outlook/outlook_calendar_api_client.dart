import 'package:flutter/foundation.dart';
import 'package:ai_asisstan/core/api/api_client.dart';
import 'package:ai_asisstan/core/api/api_endpoints.dart';
import 'package:ai_asisstan/core/api/api_exceptions.dart';
import 'package:ai_asisstan/models/calendar_event.dart';

/// Outlook Calendar API client - Microsoft Graph API Calendar çağrılarını yönetir
class OutlookCalendarApiClient {
  final ApiClient _apiClient;

  OutlookCalendarApiClient({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Calendar listesini çekme
  Future<List<Map<String, dynamic>>> getCalendars({
    required String accessToken,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.graphCalendars,
        accessToken: accessToken,
      );

      final calendarsList = response['value'] as List<dynamic>? ?? [];
      return calendarsList.map((item) => item as Map<String, dynamic>).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to fetch calendars from Outlook Calendar API: ${e.toString()}',
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
      // Primary calendar için özel endpoint kullan (calendar ID gerektirmez)
      final endpoint = (calendarId == null || calendarId == 'primary')
          ? ApiEndpoints.graphPrimaryCalendarEvents
          : ApiEndpoints.graphCalendarEvents(calendarId);

      debugPrint('📅 Outlook Calendar API - Event listesi çekiliyor:');
      debugPrint('  Endpoint: $endpoint');
      debugPrint('  Calendar ID: $calendarId');

      final queryParams = <String, dynamic>{
        '\$orderby': 'start/dateTime asc',
        '\$select': 'id,subject,body,bodyPreview,start,end,location,createdDateTime,lastModifiedDateTime,isAllDay,organizer,attendees',
      };

      if (timeMin != null) {
        queryParams['\$filter'] = "start/dateTime ge '${timeMin.toUtc().toIso8601String()}'";
      }
      if (timeMax != null) {
        final filter = queryParams['\$filter'] as String?;
        if (filter != null) {
          queryParams['\$filter'] = "$filter and start/dateTime le '${timeMax.toUtc().toIso8601String()}'";
        } else {
          queryParams['\$filter'] = "start/dateTime le '${timeMax.toUtc().toIso8601String()}'";
        }
      }
      if (maxResults != null) {
        queryParams['\$top'] = maxResults;
      }

      debugPrint('  Query Params: $queryParams');

      final response = await _apiClient.get(
        endpoint,
        queryParameters: queryParams,
        accessToken: accessToken,
      );

      debugPrint('✅ Outlook Calendar API - Event listesi başarıyla alındı');

      final eventsList = response['value'] as List<dynamic>? ?? [];
      if (eventsList.isEmpty) {
        return [];
      }

      final events = <CalendarEvent>[];
      for (final eventItem in eventsList) {
        try {
          final event = _parseOutlookCalendarEvent(
            eventItem as Map<String, dynamic>,
            userId: userId,
          );
          if (event != null) {
            events.add(event);
          }
        } catch (e) {
          debugPrint('Outlook event parse hatası: $e');
          continue;
        }
      }

      debugPrint('✅ Outlook Calendar API - ${events.length} event parse edildi');
      return events;
    } on ApiException catch (e) {
      debugPrint('❌ Outlook Calendar API - API hatası: ${e.message}');
      debugPrint('  Status: ${e.statusCode}');
      debugPrint('  Original Error: ${e.originalError}');
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('❌ Outlook Calendar API - Beklenmeyen hata: ${e.toString()}');
      debugPrint('  Stack Trace: $stackTrace');
      throw ApiException(
        message: 'Failed to fetch events from Outlook Calendar API: ${e.toString()}',
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
      if (accessToken.isEmpty) {
        debugPrint('getEventById: Access token boş!');
        return null;
      }

      // Primary calendar için özel endpoint kullan
      final endpoint = (calendarId == null || calendarId == 'primary')
          ? '${ApiEndpoints.graphPrimaryCalendarEventById}/$eventId'
          : ApiEndpoints.graphCalendarEventById(calendarId, eventId);

      final response = await _apiClient.get(
        endpoint,
        accessToken: accessToken,
      );

      return _parseOutlookCalendarEvent(
        response,
        userId: userId,
      );
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
      // Primary calendar için özel endpoint kullan
      String endpoint;
      if (calendarId == null || calendarId == 'primary') {
        endpoint = ApiEndpoints.graphPrimaryCalendarCreateEvent;
      } else {
        endpoint = ApiEndpoints.graphCalendarCreateEvent(calendarId);
      }
      
      // Microsoft Graph API için event data oluştur
      final eventData = <String, dynamic>{
        'subject': title,
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
        eventData['body'] = {
          'contentType': 'text',
          'content': description,
        };
      }
      if (location != null && location.isNotEmpty) {
        eventData['location'] = {
          'displayName': location,
        };
      }

      // Debug: Request body'yi logla
      debugPrint('📤 Outlook Calendar API - Event oluşturma isteği:');
      debugPrint('  URL: $endpoint');
      debugPrint('  Body: ${eventData.toString()}');
      debugPrint('  Start Time: ${startTime.toUtc().toIso8601String()}');
      debugPrint('  End Time: ${endTime.toUtc().toIso8601String()}');

      final response = await _apiClient.post(
        endpoint,
        body: eventData,
        accessToken: accessToken,
      );

      debugPrint('✅ Outlook Calendar API - Event başarıyla oluşturuldu');

      final parsedEvent = _parseOutlookCalendarEvent(response, userId: userId);
      if (parsedEvent == null) {
        throw ApiException(
          message: 'Event oluşturuldu ancak parse edilemedi',
        );
      }
      return parsedEvent;
    } on ValidationException catch (e) {
      // HTTP 400 hatası için detaylı log
      debugPrint('❌ Outlook Calendar API - Validation hatası (400):');
      debugPrint('  Message: ${e.message}');
      debugPrint('  Errors: ${e.errors}');
      debugPrint('  Original Error: ${e.originalError}');
      rethrow;
    } on ApiException catch (e) {
      debugPrint('❌ Outlook Calendar API - API hatası: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('❌ Outlook Calendar API - Beklenmeyen hata: ${e.toString()}');
      throw ApiException(
        message: 'Failed to create event in Outlook Calendar API: ${e.toString()}',
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
      // Primary calendar için özel endpoint kullan
      String endpoint;
      if (calendarId == null || calendarId == 'primary') {
        endpoint = '${ApiEndpoints.graphPrimaryCalendarEventById}/$eventId';
      } else {
        endpoint = ApiEndpoints.graphCalendarUpdateEvent(calendarId, eventId);
      }
      
      final eventData = <String, dynamic>{};
      
      if (title != null) {
        eventData['subject'] = title;
      }
      if (description != null) {
        eventData['body'] = {
          'contentType': 'text',
          'content': description,
        };
      }
      if (location != null) {
        eventData['location'] = {
          'displayName': location,
        };
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

      final response = await _apiClient.patch(
        endpoint,
        body: eventData,
        accessToken: accessToken,
      );

      final parsedEvent = _parseOutlookCalendarEvent(response, userId: userId);
      if (parsedEvent == null) {
        throw ApiException(
          message: 'Event güncellendi ancak parse edilemedi',
        );
      }
      return parsedEvent;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to update event in Outlook Calendar API: ${e.toString()}',
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
      // Primary calendar için özel endpoint kullan
      String endpoint;
      if (calendarId == null || calendarId == 'primary') {
        endpoint = '${ApiEndpoints.graphPrimaryCalendarEventById}/$eventId';
      } else {
        endpoint = ApiEndpoints.graphCalendarDeleteEvent(calendarId, eventId);
      }
      
      await _apiClient.delete(
        endpoint,
        accessToken: accessToken,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to delete event from Outlook Calendar API: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Outlook Calendar event'ini CalendarEvent modeline çevir
  CalendarEvent? _parseOutlookCalendarEvent(
    Map<String, dynamic> eventData, {
    int? userId,
  }) {
    try {
      final id = eventData['id'] as String?;
      final subject = eventData['subject'] as String? ?? 'Etkinlik';
      final body = eventData['body'] as Map<String, dynamic>?;
      final description = body?['content'] as String?;
      final location = eventData['location'] as Map<String, dynamic>?;
      final locationName = location?['displayName'] as String?;
      
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
      final createdStr = eventData['createdDateTime'] as String?;
      final updatedStr = eventData['lastModifiedDateTime'] as String?;
      final createdAt = createdStr != null ? DateTime.parse(createdStr) : DateTime.now();
      final updatedAt = updatedStr != null ? DateTime.parse(updatedStr) : DateTime.now();
      
      // Event type (Outlook Calendar'da direkt yok, description'dan çıkarabiliriz veya varsayılan)
      EventType eventType = EventType.personal;
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

      return CalendarEvent(
        id: null, // Local ID (Outlook Calendar ID externalId'de saklanacak)
        userId: userId ?? 0,
        title: subject,
        description: description,
        startTime: startTime,
        endTime: endTime,
        location: locationName,
        eventType: eventType,
        source: EventSource.outlook,
        externalId: id, // Outlook Calendar event ID
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
    } catch (e) {
      debugPrint('Outlook event parse hatası: $e');
      return null;
    }
  }
}

