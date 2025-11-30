import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/calendar_repository.dart';
import 'package:ai_asisstan/models/calendar_event.dart';
import 'package:ai_asisstan/models/calendar_account.dart';

/// Calendar repository provider
final calendarRepositoryProvider = Provider<CalendarRepository>((ref) {
  return CalendarRepository();
});

/// Calendar listesi provider
final calendarsProvider = FutureProvider.family<List<Map<String, dynamic>>, Map<String, dynamic>>((ref, params) async {
  final repository = ref.watch(calendarRepositoryProvider);
  return repository.getCalendars(
    accessToken: params['accessToken'] as String,
    provider: params['provider'] as CalendarProvider,
  );
});

/// Event listesi parametreleri
class EventListParams {
  final String? calendarId;
  final DateTime? timeMin;
  final DateTime? timeMax;
  final int? maxResults;
  final String? accessToken;
  final CalendarProvider? provider;
  final int? userId;

  EventListParams({
    this.calendarId,
    this.timeMin,
    this.timeMax,
    this.maxResults,
    this.accessToken,
    this.provider,
    this.userId,
  });

  EventListParams copyWith({
    String? calendarId,
    DateTime? timeMin,
    DateTime? timeMax,
    int? maxResults,
    String? accessToken,
    CalendarProvider? provider,
    int? userId,
  }) {
    return EventListParams(
      calendarId: calendarId ?? this.calendarId,
      timeMin: timeMin ?? this.timeMin,
      timeMax: timeMax ?? this.timeMax,
      maxResults: maxResults ?? this.maxResults,
      accessToken: accessToken ?? this.accessToken,
      provider: provider ?? this.provider,
      userId: userId ?? this.userId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventListParams &&
        other.calendarId == calendarId &&
        other.timeMin == timeMin &&
        other.timeMax == timeMax &&
        other.maxResults == maxResults &&
        other.accessToken == accessToken &&
        other.provider == provider &&
        other.userId == userId;
  }

  @override
  int get hashCode {
    return Object.hash(calendarId, timeMin, timeMax, maxResults, accessToken, provider, userId);
  }
}

/// Event listesi provider
final eventsProvider = FutureProvider.family<List<CalendarEvent>, EventListParams>((ref, params) async {
  final repository = ref.watch(calendarRepositoryProvider);
  if (params.provider == null || params.accessToken == null) {
    return [];
  }
  return repository.getEvents(
    calendarId: params.calendarId,
    timeMin: params.timeMin,
    timeMax: params.timeMax,
    maxResults: params.maxResults,
    accessToken: params.accessToken!,
    provider: params.provider!,
    userId: params.userId,
  );
});

/// Event detay provider
final eventByIdProvider = FutureProvider.family<CalendarEvent?, Map<String, dynamic>>((ref, params) async {
  final repository = ref.watch(calendarRepositoryProvider);
  return repository.getEventById(
    eventId: params['eventId'] as String,
    calendarId: params['calendarId'] as String?,
    accessToken: params['accessToken'] as String,
    provider: params['provider'] as CalendarProvider,
    userId: params['userId'] as int?,
  );
});

/// Event işlemleri için provider (stateful)
class CalendarNotifier extends StateNotifier<AsyncValue<List<CalendarEvent>>> {
  final CalendarRepository _repository;
  final EventListParams _params;

  CalendarNotifier(this._repository, this._params) : super(const AsyncValue.loading()) {
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    state = const AsyncValue.loading();
    try {
      // Local ve Calendar event'lerini birleştir
      final events = await _repository.getCombinedEvents(
        calendarId: _params.calendarId,
        timeMin: _params.timeMin,
        timeMax: _params.timeMax,
        maxResults: _params.maxResults,
        accessToken: _params.accessToken,
        provider: _params.provider,
        userId: _params.userId,
      );
      state = AsyncValue.data(events);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Event listesini yenile
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      // Local ve Calendar event'lerini birleştir
      final events = await _repository.getCombinedEvents(
        calendarId: _params.calendarId,
        timeMin: _params.timeMin,
        timeMax: _params.timeMax,
        maxResults: _params.maxResults,
        accessToken: _params.accessToken,
        provider: _params.provider,
        userId: _params.userId,
      );
      state = AsyncValue.data(events);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Event oluştur
  Future<CalendarEvent> createEvent({
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    String? description,
    String? location,
    EventType? eventType,
  }) async {
    if (_params.provider == null || _params.accessToken == null) {
      throw Exception('Provider ve access token gerekli');
    }
    try {
      final event = await _repository.createEvent(
        title: title,
        startTime: startTime,
        endTime: endTime,
        description: description,
        location: location,
        eventType: eventType,
        calendarId: _params.calendarId,
        accessToken: _params.accessToken!,
        provider: _params.provider!,
        userId: _params.userId ?? 0,
      );

      // Optimistic update - yeni event'i listeye ekle
      final currentEvents = state.value ?? [];
      state = AsyncValue.data([...currentEvents, event]);

      return event;
    } catch (e) {
      debugPrint('createEvent hatası: ${e.toString()}');
      rethrow;
    }
  }

  /// Event güncelle
  Future<CalendarEvent> updateEvent({
    required String eventId,
    String? title,
    DateTime? startTime,
    DateTime? endTime,
    String? description,
    String? location,
    EventType? eventType,
  }) async {
    if (_params.provider == null || _params.accessToken == null) {
      throw Exception('Provider ve access token gerekli');
    }
    try {
      final event = await _repository.updateEvent(
        eventId: eventId,
        title: title,
        startTime: startTime,
        endTime: endTime,
        description: description,
        location: location,
        eventType: eventType,
        calendarId: _params.calendarId,
        accessToken: _params.accessToken!,
        provider: _params.provider!,
        userId: _params.userId ?? 0,
      );

      // Optimistic update - event'i güncelle
      final currentEvents = state.value ?? [];
      final updatedEvents = currentEvents.map((e) {
        if (e.externalId == eventId) {
          return event;
        }
        return e;
      }).toList();
      state = AsyncValue.data(updatedEvents);

      return event;
    } catch (e) {
      debugPrint('updateEvent hatası: ${e.toString()}');
      rethrow;
    }
  }

  /// Event sil
  Future<void> deleteEvent(String eventId) async {
    if (_params.provider == null || _params.accessToken == null) {
      throw Exception('Provider ve access token gerekli');
    }
    try {
      // Optimistic update - event'i listeden çıkar
      final currentEvents = state.value ?? [];
      final updatedEvents = currentEvents.where((e) => e.externalId != eventId).toList();
      state = AsyncValue.data(updatedEvents);

      await _repository.deleteEvent(
        eventId: eventId,
        calendarId: _params.calendarId,
        accessToken: _params.accessToken!,
        provider: _params.provider!,
      );
    } catch (e) {
      debugPrint('deleteEvent hatası: ${e.toString()}');
      // Hata durumunda listeyi yeniden yükle
      await refresh();
      rethrow;
    }
  }
}

/// CalendarNotifier provider
final calendarNotifierProvider = StateNotifierProvider.family<CalendarNotifier, AsyncValue<List<CalendarEvent>>, EventListParams>((ref, params) {
  final repository = ref.watch(calendarRepositoryProvider);
  return CalendarNotifier(repository, params);
});

