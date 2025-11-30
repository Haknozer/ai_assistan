import 'package:flutter/foundation.dart';
import 'package:ai_asisstan/models/calendar_event.dart';
import 'package:ai_asisstan/models/calendar_account.dart';
import 'package:ai_asisstan/core/api/api_exceptions.dart';
import '../datasources/calendar_remote_datasource.dart';
import 'calendar_local_repository.dart';

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
      // 401 hatası - token expire olmuş
      final providerName = provider == CalendarProvider.google ? 'Google Calendar' : 'Outlook Calendar';
      throw UnauthorizedException(
        message: 'Oturum süresi dolmuş. Lütfen $providerName bağlantısını yeniden yapın.',
        originalError: e.originalError,
      );
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
    bool syncToLocal = true, // Local database'e senkronize et
  }) async {
    try {
      // API'den event'leri çek
      final events = await _remoteDataSource.getEvents(
        calendarId: calendarId,
        timeMin: timeMin,
        timeMax: timeMax,
        maxResults: maxResults,
        accessToken: accessToken,
        provider: provider,
        userId: userId,
      );

      // Local database'e kaydet (eğer syncToLocal true ise)
      if (syncToLocal && userId != null) {
        try {
          await _localRepository.saveEvents(events);
          debugPrint('✅ ${events.length} event local database\'e kaydedildi');
        } catch (e) {
          debugPrint('⚠️ Event\'ler local database\'e kaydedilemedi: $e');
          // Hata olsa bile event'leri döndür
        }
      }

      return events;
    } on UnauthorizedException catch (e) {
      // 401 hatası - token expire olmuş, local database'den döndür
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
      final providerName = provider == CalendarProvider.google ? 'Google Calendar' : 'Outlook Calendar';
      throw UnauthorizedException(
        message: 'Oturum süresi dolmuş. Lütfen $providerName bağlantısını yeniden yapın.',
        originalError: e.originalError,
      );
    } on ApiException {
      // API hatası durumunda local database'den döndür
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

    // Sonra Calendar'dan event'leri çek ve birleştir (Google veya Outlook)
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

        // External ID'ye göre birleştir (duplicate'leri önle)
        final existingExternalIds =
            allEvents.where((e) => e.externalId != null && e.externalId!.isNotEmpty).map((e) => e.externalId!).toSet();

        for (final event in remoteEvents) {
          if (event.externalId == null || !existingExternalIds.contains(event.externalId)) {
            allEvents.add(event);
          }
        }
      } catch (e) {
        debugPrint('⚠️ Calendar event\'leri getirilemedi: $e');
      }
    }

    // Tarihe göre sırala
    allEvents.sort((a, b) => a.startTime.compareTo(b.startTime));

    return allEvents;
  }

  /// Hem Google hem Outlook Calendar event'lerini birleştir
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

      // Google Calendar'dan event'leri çek
      if (googleAccessToken != null && googleAccessToken.isNotEmpty) {
        try {
          debugPrint('📅 Google Calendar event\'leri çekiliyor...');
          // Doğrudan remote data source'dan çek (getEvents kullanma, çünkü o local database'den tekrar çekiyor)
          final googleEvents = await _remoteDataSource.getEvents(
            calendarId: calendarId,
            timeMin: timeMin,
            timeMax: timeMax,
            maxResults: maxResults,
            accessToken: googleAccessToken,
            provider: CalendarProvider.google,
            userId: userId,
          );
          debugPrint('✅ Google Calendar\'dan ${googleEvents.length} event alındı');

          // Yeni event'leri local database'e kaydet (sadece yeni olanlar)
          if (userId != null && googleEvents.isNotEmpty) {
            try {
              // Mevcut local event'leri kontrol et (external ID'ye göre)
              final externalIds = googleEvents.map((e) => e.externalId).whereType<String>().toList();
              if (externalIds.isNotEmpty) {
                final existingLocalEvents = await _localRepository.getEvents(
                  userId: userId,
                  source: EventSource.google,
                  externalIdList: externalIds,
                );

                final existingExternalIds = existingLocalEvents
                    .where((e) => e.externalId != null && e.externalId!.isNotEmpty)
                    .map((e) => e.externalId!)
                    .toSet();

                // Sadece yeni event'leri kaydet
                int savedCount = 0;
                for (final event in googleEvents) {
                  if (event.externalId != null && !existingExternalIds.contains(event.externalId)) {
                    await _localRepository.saveEvent(event.copyWith(source: EventSource.google));
                    savedCount++;
                  }
                }
                if (savedCount > 0) {
                  debugPrint('✅ $savedCount Google Calendar event local database\'e kaydedildi');
                }
              }
            } catch (e) {
              debugPrint('⚠️ Google Calendar event\'leri local database\'e kaydedilemedi: $e');
            }
          }

          // External ID'ye göre birleştir (duplicate'leri önle)
          final existingExternalIds = allEvents
              .where((e) => e.externalId != null && e.externalId!.isNotEmpty)
              .map((e) => e.externalId!)
              .toSet();

          for (final event in googleEvents) {
            if (event.externalId == null || !existingExternalIds.contains(event.externalId)) {
              allEvents.add(event);
              existingExternalIds.add(event.externalId ?? '');
            }
          }
        } on UnauthorizedException catch (e) {
          // 401 hatası - token expire olmuş, sadece log'la ve devam et
          debugPrint('❌ Google Calendar - Token süresi dolmuş (401): ${e.message}');
          debugPrint('  Google Calendar event\'leri atlanıyor. Lütfen Google Calendar bağlantısını yeniden yapın.');
          // Hata olsa bile devam et, diğer calendar'lardan gelen event'leri göster
        } catch (e) {
          debugPrint('⚠️ Google Calendar event\'leri getirilemedi: $e');
          // Hata durumunda sadece log'la, local database'den tekrar çekme (zaten allEvents'te var)
        }
      }

      // Outlook Calendar'dan event'leri çek
      if (outlookAccessToken != null && outlookAccessToken.isNotEmpty) {
        try {
          debugPrint('📅 Outlook Calendar event\'leri çekiliyor...');
          // Doğrudan remote data source'dan çek (getEvents kullanma, çünkü o local database'den tekrar çekiyor)
          final outlookEvents = await _remoteDataSource.getEvents(
            calendarId: calendarId,
            timeMin: timeMin,
            timeMax: timeMax,
            maxResults: maxResults,
            accessToken: outlookAccessToken,
            provider: CalendarProvider.outlook,
            userId: userId,
          );
          debugPrint('✅ Outlook Calendar\'dan ${outlookEvents.length} event alındı');

          // Yeni event'leri local database'e kaydet (sadece yeni olanlar)
          if (userId != null && outlookEvents.isNotEmpty) {
            try {
              // Mevcut local event'leri kontrol et (external ID'ye göre)
              final externalIds = outlookEvents.map((e) => e.externalId).whereType<String>().toList();
              if (externalIds.isNotEmpty) {
                final existingLocalEvents = await _localRepository.getEvents(
                  userId: userId,
                  source: EventSource.outlook,
                  externalIdList: externalIds,
                );

                final existingExternalIds = existingLocalEvents
                    .where((e) => e.externalId != null && e.externalId!.isNotEmpty)
                    .map((e) => e.externalId!)
                    .toSet();

                // Sadece yeni event'leri kaydet
                int savedCount = 0;
                for (final event in outlookEvents) {
                  if (event.externalId != null && !existingExternalIds.contains(event.externalId)) {
                    await _localRepository.saveEvent(event.copyWith(source: EventSource.outlook));
                    savedCount++;
                  }
                }
                if (savedCount > 0) {
                  debugPrint('✅ $savedCount Outlook Calendar event local database\'e kaydedildi');
                }
              }
            } catch (e) {
              debugPrint('⚠️ Outlook Calendar event\'leri local database\'e kaydedilemedi: $e');
            }
          }

          // External ID'ye göre birleştir (duplicate'leri önle)
          final existingExternalIds = allEvents
              .where((e) => e.externalId != null && e.externalId!.isNotEmpty)
              .map((e) => e.externalId!)
              .toSet();

          for (final event in outlookEvents) {
            if (event.externalId == null || !existingExternalIds.contains(event.externalId)) {
              allEvents.add(event);
              existingExternalIds.add(event.externalId ?? '');
            }
          }
        } catch (e, stackTrace) {
          debugPrint('❌ Outlook Calendar event\'leri getirilemedi:');
          debugPrint('  Error: $e');
          debugPrint('  Stack Trace: $stackTrace');
          // Hata durumunda sadece log'la, local database'den tekrar çekme (zaten allEvents'te var)
          // Hata olsa bile devam et, diğer calendar'lardan gelen event'leri göster
        }
      }

      // Tarihe göre sırala
      allEvents.sort((a, b) => a.startTime.compareTo(b.startTime));

      debugPrint('✅ getAllCombinedEvents tamamlandı: ${allEvents.length} event');
      return allEvents;
    } catch (e, stackTrace) {
      debugPrint('❌ getAllCombinedEvents kritik hata:');
      debugPrint('  Error: $e');
      debugPrint('  Stack Trace: $stackTrace');
      // Kritik hata olsa bile boş liste döndür, provider'ın sürekli yeniden çalışmasını önle
      return [];
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
      final providerName = provider == CalendarProvider.google ? 'Google Calendar' : 'Outlook Calendar';
      throw UnauthorizedException(
        message: 'Oturum süresi dolmuş. Lütfen $providerName bağlantısını yeniden yapın.',
        originalError: e.originalError,
      );
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
      // Calendar'a event oluştur
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
        debugPrint('✅ Event local database\'e kaydedildi: ${event.title} (externalId: ${event.externalId})');
      } catch (e) {
        debugPrint('⚠️ Event local database\'e kaydedilemedi: $e');
        // Hata olsa bile event'i döndür
      }

      return event;
    } on UnauthorizedException catch (e) {
      final providerName = provider == CalendarProvider.google ? 'Google Calendar' : 'Outlook Calendar';
      throw UnauthorizedException(
        message: 'Oturum süresi dolmuş. Lütfen $providerName bağlantısını yeniden yapın.',
        originalError: e.originalError,
      );
    } on ValidationException catch (e) {
      // HTTP 400 hatası için daha detaylı mesaj
      throw ApiException(
        message: 'Event oluşturma hatası. Lütfen tüm alanların doğru olduğundan emin olun.\n\nDetay: ${e.message}',
        originalError: e.originalError,
      );
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
      final providerName = provider == CalendarProvider.google ? 'Google Calendar' : 'Outlook Calendar';
      throw UnauthorizedException(
        message: 'Oturum süresi dolmuş. Lütfen $providerName bağlantısını yeniden yapın.',
        originalError: e.originalError,
      );
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
      final providerName = provider == CalendarProvider.google ? 'Google Calendar' : 'Outlook Calendar';
      throw UnauthorizedException(
        message: 'Oturum süresi dolmuş. Lütfen $providerName bağlantısını yeniden yapın.',
        originalError: e.originalError,
      );
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
