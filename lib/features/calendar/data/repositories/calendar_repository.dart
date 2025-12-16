import 'package:flutter/foundation.dart';
import 'package:ai_asisstan/models/calendar_event.dart';
import 'package:ai_asisstan/models/calendar_account.dart';
import 'package:ai_asisstan/core/api/api_exceptions.dart';
import '../../../../services/task_auto_creation_service.dart';
import '../datasources/calendar_remote_datasource.dart';
import 'calendar_local_repository.dart';
import 'utils/event_merger.dart';
import 'utils/event_sync_helper.dart';
import 'utils/error_handler.dart';

/// Calendar verilerini API'den çeken ve local database'e kaydeden repository
class CalendarRepository {
  final CalendarRemoteDataSource _remoteDataSource;
  final CalendarLocalRepository _localRepository;

  CalendarRepository({
    CalendarRemoteDataSource? remoteDataSource,
    CalendarLocalRepository? localRepository,
  })  : _remoteDataSource = remoteDataSource ?? CalendarRemoteDataSource(),
        _localRepository = localRepository ?? CalendarLocalRepository();

  /// Calendar listesini API'den getir
  Future<List<Map<String, dynamic>>> getCalendars({
    required String accessToken,
    required CalendarProvider provider,
  }) async {
    try {
      return await _remoteDataSource.getCalendars(
        accessToken: accessToken,
        provider: provider,
      );
    } on UnauthorizedException catch (e) {
      throw CalendarErrorHandler.handleUnauthorized(e, provider);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to fetch calendars: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Event listesini API'den getir ve local database'e kaydet
  Future<List<CalendarEvent>> getEvents({
    String? calendarId,
    DateTime? timeMin,
    DateTime? timeMax,
    int? maxResults,
    required String accessToken,
    required CalendarProvider provider,
    int? userId,
    bool syncToLocal = true,
  }) async {
    try {
      final events = await _remoteDataSource.getEvents(
        calendarId: calendarId,
        timeMin: timeMin,
        timeMax: timeMax,
        maxResults: maxResults,
        accessToken: accessToken,
        provider: provider,
        userId: userId,
      );

      if (syncToLocal && userId != null) {
        try {
          await _localRepository.saveEvents(events);
          debugPrint('✅ ${events.length} event local database\'e kaydedildi');
        } catch (e) {
          debugPrint('⚠️ Event\'ler local database\'e kaydedilemedi: $e');
        }
      }

      return events;
    } on UnauthorizedException catch (e) {
      if (userId != null) {
        try {
          debugPrint('⚠️ API hatası, local database\'den event\'ler getiriliyor');
          return await _localRepository.getEvents(
            userId: userId,
            timeMin: timeMin,
            timeMax: timeMax,
          );
        } catch (localError) {
          debugPrint('⚠️ Local database\'den event getirilemedi: $localError');
        }
      }
      throw CalendarErrorHandler.handleUnauthorized(e, provider);
    } on ApiException {
      if (userId != null) {
        try {
          debugPrint('⚠️ API hatası, local database\'den event\'ler getiriliyor');
          return await _localRepository.getEvents(
            userId: userId,
            timeMin: timeMin,
            timeMax: timeMax,
          );
        } catch (localError) {
          debugPrint('⚠️ Local database\'den event getirilemedi: $localError');
        }
      }
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to fetch events: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Local database'den event'leri getir
  Future<List<CalendarEvent>> getLocalEvents({
    int? userId,
    DateTime? timeMin,
    DateTime? timeMax,
  }) async {
    return await _localRepository.getEvents(
      userId: userId,
      timeMin: timeMin,
      timeMax: timeMax,
    );
  }

  /// Local ve Calendar event'lerini birleştir (Google veya Outlook)
  Future<List<CalendarEvent>> getCombinedEvents({
    String? calendarId,
    DateTime? timeMin,
    DateTime? timeMax,
    int? maxResults,
    String? accessToken,
    CalendarProvider? provider,
    int? userId,
  }) async {
    final allEvents = <CalendarEvent>[];

    // Önce local database'den event'leri al
    if (userId != null) {
      try {
        final localEvents = await _localRepository.getEvents(
          userId: userId,
          timeMin: timeMin,
          timeMax: timeMax,
        );
        allEvents.addAll(localEvents);
      } catch (e) {
        debugPrint('⚠️ Local event\'ler getirilemedi: $e');
      }
    }

    // Sonra Calendar'dan event'leri çek ve birleştir
    if (accessToken != null && accessToken.isNotEmpty && provider != null) {
      try {
        final remoteEvents = await getEvents(
          calendarId: calendarId,
          timeMin: timeMin,
          timeMax: timeMax,
          maxResults: maxResults,
          accessToken: accessToken,
          provider: provider,
          userId: userId,
          syncToLocal: true,
        );

        return EventMerger.mergeEvents(allEvents, remoteEvents);
      } catch (e) {
        debugPrint('⚠️ Calendar event\'leri getirilemedi: $e');
      }
    }

    return EventMerger.sortByDate(allEvents);
  }

  /// Hem Google hem Outlook Calendar event'lerini birleştir
  /// NOT: Local database sadece cache olarak kullanılır, merge işlemi sadece API'lerden gelen event'ler arasında yapılır
  Future<List<CalendarEvent>> getAllCombinedEvents({
    String? calendarId,
    DateTime? timeMin,
    DateTime? timeMax,
    int? maxResults,
    String? googleAccessToken,
    String? outlookAccessToken,
    int? userId,
  }) async {
    try {
      final allEvents = <CalendarEvent>[];

      // ÖNEMLİ: Local database'den event'leri çekme - sadece API'lerden çekip merge edeceğiz
      // Bu sayede duplicate'ler önlenir ve sadece gerçek API'lerden gelen event'ler gösterilir
      
      // Google Calendar'dan event'leri çek
      if (googleAccessToken != null && googleAccessToken.isNotEmpty) {
        await _fetchAndMergeGoogleEvents(
          allEvents: allEvents,
          calendarId: calendarId,
          timeMin: timeMin,
          timeMax: timeMax,
          maxResults: maxResults,
          accessToken: googleAccessToken,
          userId: userId,
        );
      }

      // Outlook Calendar'dan event'leri çek
      if (outlookAccessToken != null && outlookAccessToken.isNotEmpty) {
        await _fetchAndMergeOutlookEvents(
          allEvents: allEvents,
          calendarId: calendarId,
          timeMin: timeMin,
          timeMax: timeMax,
          maxResults: maxResults,
          accessToken: outlookAccessToken,
          userId: userId,
        );
      }

      // Eğer hiç API'den event gelmediyse, local database'den çek (fallback)
      if (allEvents.isEmpty && userId != null) {
        try {
          debugPrint('⚠️ API\'lerden event gelmedi, local database\'den çekiliyor...');
          final localEvents = await _localRepository.getEvents(
            userId: userId,
            timeMin: timeMin,
            timeMax: timeMax,
          );
          // Local database'den gelen event'leri de merge et (duplicate kontrolü ile)
          final mergedLocalEvents = EventMerger.mergeEvents([], localEvents);
          allEvents.addAll(mergedLocalEvents);
          debugPrint('✅ Local database\'den ${mergedLocalEvents.length} event alındı (duplicate\'ler temizlendi)');
        } catch (e) {
          debugPrint('⚠️ Local event\'ler getirilemedi: $e');
        }
      }

      debugPrint('✅ getAllCombinedEvents tamamlandı: ${allEvents.length} event (Google: ${googleAccessToken != null && googleAccessToken.isNotEmpty ? "var" : "yok"}, Outlook: ${outlookAccessToken != null && outlookAccessToken.isNotEmpty ? "var" : "yok"})');
      
      // Calendar event'lerinden task oluştur (eventType = task olan event'ler)
      if (userId != null && allEvents.isNotEmpty) {
        try {
          final taskService = TaskAutoCreationService();
          final createdTasks = await taskService.createTasksFromCalendarEvents(
            userId: userId,
            events: allEvents,
          );
          if (createdTasks.isNotEmpty) {
            debugPrint('✅ ${createdTasks.length} task calendar event\'lerinden oluşturuldu');
          }
        } catch (e) {
          debugPrint('⚠️ Calendar event\'lerinden task oluşturulurken hata: $e');
        }
      }
      
      return EventMerger.sortByDate(allEvents);
    } catch (e, stackTrace) {
      debugPrint('❌ getAllCombinedEvents kritik hata:');
      debugPrint('  Error: $e');
      debugPrint('  Stack Trace: $stackTrace');
      return [];
    }
  }

  /// Google Calendar event'lerini çek ve birleştir
  Future<void> _fetchAndMergeGoogleEvents({
    required List<CalendarEvent> allEvents,
    String? calendarId,
    DateTime? timeMin,
    DateTime? timeMax,
    int? maxResults,
    required String accessToken,
    int? userId,
  }) async {
    try {
      debugPrint('📅 Google Calendar event\'leri çekiliyor...');
      final googleEvents = await _remoteDataSource.getEvents(
        calendarId: calendarId,
        timeMin: timeMin,
        timeMax: timeMax,
        maxResults: maxResults,
        accessToken: accessToken,
        provider: CalendarProvider.google,
        userId: userId,
      );
      debugPrint('✅ Google Calendar\'dan ${googleEvents.length} event alındı');

      // Yeni event'leri local database'e kaydet
      if (userId != null && googleEvents.isNotEmpty) {
        await EventSyncHelper.syncNewEventsToLocal(
          remoteEvents: googleEvents,
          localRepository: _localRepository,
          userId: userId,
          source: EventSource.google,
        );
      }

      // Event'leri birleştir (duplicate kontrolü ile)
      final merged = EventMerger.mergeEvents(allEvents, googleEvents);
      allEvents.clear();
      allEvents.addAll(merged);
    } on UnauthorizedException catch (e) {
      debugPrint('❌ Google Calendar - Token süresi dolmuş (401): ${e.message}');
      debugPrint('  Google Calendar event\'leri atlanıyor. Lütfen Google Calendar bağlantısını yeniden yapın.');
    } catch (e) {
      debugPrint('⚠️ Google Calendar event\'leri getirilemedi: $e');
    }
  }

  /// Outlook Calendar event'lerini çek ve birleştir
  Future<void> _fetchAndMergeOutlookEvents({
    required List<CalendarEvent> allEvents,
    String? calendarId,
    DateTime? timeMin,
    DateTime? timeMax,
    int? maxResults,
    required String accessToken,
    int? userId,
  }) async {
    try {
      debugPrint('📅 Outlook Calendar event\'leri çekiliyor...');
      final outlookEvents = await _remoteDataSource.getEvents(
        calendarId: calendarId,
        timeMin: timeMin,
        timeMax: timeMax,
        maxResults: maxResults,
        accessToken: accessToken,
        provider: CalendarProvider.outlook,
        userId: userId,
      );
      debugPrint('✅ Outlook Calendar\'dan ${outlookEvents.length} event alındı');

      // Yeni event'leri local database'e kaydet
      if (userId != null && outlookEvents.isNotEmpty) {
        await EventSyncHelper.syncNewEventsToLocal(
          remoteEvents: outlookEvents,
          localRepository: _localRepository,
          userId: userId,
          source: EventSource.outlook,
        );
      }

      // Event'leri birleştir
      final merged = EventMerger.mergeEvents(allEvents, outlookEvents);
      allEvents.clear();
      allEvents.addAll(merged);
    } catch (e, stackTrace) {
      debugPrint('❌ Outlook Calendar event\'leri getirilemedi:');
      debugPrint('  Error: $e');
      debugPrint('  Stack Trace: $stackTrace');
    }
  }

  /// Tek event detayını çekme
  Future<CalendarEvent?> getEventById({
    required String eventId,
    String? calendarId,
    required String accessToken,
    required CalendarProvider provider,
    int? userId,
  }) async {
    try {
      return await _remoteDataSource.getEventById(
        eventId: eventId,
        calendarId: calendarId,
        accessToken: accessToken,
        provider: provider,
        userId: userId,
      );
    } on UnauthorizedException catch (e) {
      throw CalendarErrorHandler.handleUnauthorized(e, provider);
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint('getEventById hatası: ${e.toString()}');
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
    required CalendarProvider provider,
    required int userId,
  }) async {
    try {
      final event = await _remoteDataSource.createEvent(
        title: title,
        startTime: startTime,
        endTime: endTime,
        description: description,
        location: location,
        eventType: eventType,
        calendarId: calendarId,
        accessToken: accessToken,
        provider: provider,
        userId: userId,
      );

      // Local database'e kaydet
      try {
        await _localRepository.saveEvent(event);
        debugPrint('✅ Event local database\'e kaydedildi: ${event.title} (externalId: ${event.externalId}, eventType: ${event.eventType.name})');
      } catch (e) {
        debugPrint('⚠️ Event local database\'e kaydedilemedi: $e');
      }

      return event;
    } on UnauthorizedException catch (e) {
      throw CalendarErrorHandler.handleUnauthorized(e, provider);
    } on ValidationException catch (e) {
      throw CalendarErrorHandler.handleValidation(e);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to create event: ${e.toString()}',
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
    required CalendarProvider provider,
    required int userId,
  }) async {
    try {
      return await _remoteDataSource.updateEvent(
        eventId: eventId,
        title: title,
        startTime: startTime,
        endTime: endTime,
        description: description,
        location: location,
        eventType: eventType,
        calendarId: calendarId,
        accessToken: accessToken,
        provider: provider,
        userId: userId,
      );
    } on UnauthorizedException catch (e) {
      throw CalendarErrorHandler.handleUnauthorized(e, provider);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to update event: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Event silme
  Future<void> deleteEvent({
    required String eventId,
    String? calendarId,
    required String accessToken,
    required CalendarProvider provider,
  }) async {
    try {
      await _remoteDataSource.deleteEvent(
        eventId: eventId,
        calendarId: calendarId,
        accessToken: accessToken,
        provider: provider,
      );
    } on UnauthorizedException catch (e) {
      throw CalendarErrorHandler.handleUnauthorized(e, provider);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to delete event: ${e.toString()}',
        originalError: e,
      );
    }
  }
}
