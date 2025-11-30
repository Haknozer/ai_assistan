import 'package:ai_asisstan/core/api/api_client.dart';
import 'package:ai_asisstan/core/api/api_exceptions.dart';
import 'package:ai_asisstan/models/calendar_event.dart';
import 'package:ai_asisstan/models/calendar_account.dart';
import 'google/google_calendar_api_client.dart';
import 'outlook/outlook_calendar_api_client.dart';

/// Calendar remote data source - Google Calendar ve Outlook Calendar API çağrılarını yönetir
class CalendarRemoteDataSource {
  final GoogleCalendarApiClient _googleCalendarClient;
  final OutlookCalendarApiClient _outlookCalendarClient;

  CalendarRemoteDataSource({
    ApiClient? apiClient,
    GoogleCalendarApiClient? googleCalendarClient,
    OutlookCalendarApiClient? outlookCalendarClient,
  })  : _googleCalendarClient = googleCalendarClient ?? GoogleCalendarApiClient(apiClient: apiClient),
        _outlookCalendarClient = outlookCalendarClient ?? OutlookCalendarApiClient(apiClient: apiClient);

  /// Calendar listesini çekme
  Future<List<Map<String, dynamic>>> getCalendars({
    required String accessToken,
    required CalendarProvider provider,
  }) async {
    if (accessToken.isEmpty) {
      throw ApiException(message: 'Access token required');
    }

    switch (provider) {
      case CalendarProvider.google:
        return await _googleCalendarClient.getCalendars(
          accessToken: accessToken,
        );
      case CalendarProvider.outlook:
        return await _outlookCalendarClient.getCalendars(
          accessToken: accessToken,
        );
      case CalendarProvider.apple:
        throw ApiException(message: 'Apple Calendar desteği henüz eklenmedi');
    }
  }

  /// Event listesini çekme
  Future<List<CalendarEvent>> getEvents({
    String? calendarId,
    DateTime? timeMin,
    DateTime? timeMax,
    int? maxResults,
    required String accessToken,
    required CalendarProvider provider,
    int? userId,
  }) async {
    if (accessToken.isEmpty) {
      throw ApiException(message: 'Access token required');
    }

    switch (provider) {
      case CalendarProvider.google:
        return await _googleCalendarClient.getEvents(
          calendarId: calendarId,
          timeMin: timeMin,
          timeMax: timeMax,
          maxResults: maxResults,
          accessToken: accessToken,
          userId: userId,
        );
      case CalendarProvider.outlook:
        return await _outlookCalendarClient.getEvents(
          calendarId: calendarId,
          timeMin: timeMin,
          timeMax: timeMax,
          maxResults: maxResults,
          accessToken: accessToken,
          userId: userId,
        );
      case CalendarProvider.apple:
        throw ApiException(message: 'Apple Calendar desteği henüz eklenmedi');
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
    if (accessToken.isEmpty) {
      throw ApiException(message: 'Access token required');
    }

    switch (provider) {
      case CalendarProvider.google:
        return await _googleCalendarClient.getEventById(
          eventId: eventId,
          calendarId: calendarId,
          accessToken: accessToken,
          userId: userId,
        );
      case CalendarProvider.outlook:
        return await _outlookCalendarClient.getEventById(
          eventId: eventId,
          calendarId: calendarId,
          accessToken: accessToken,
          userId: userId,
        );
      case CalendarProvider.apple:
        throw ApiException(message: 'Apple Calendar desteği henüz eklenmedi');
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
    if (accessToken.isEmpty) {
      throw ApiException(message: 'Access token required');
    }

    switch (provider) {
      case CalendarProvider.google:
        return await _googleCalendarClient.createEvent(
          title: title,
          startTime: startTime,
          endTime: endTime,
          description: description,
          location: location,
          eventType: eventType,
          calendarId: calendarId,
          accessToken: accessToken,
          userId: userId,
        );
      case CalendarProvider.outlook:
        return await _outlookCalendarClient.createEvent(
          title: title,
          startTime: startTime,
          endTime: endTime,
          description: description,
          location: location,
          eventType: eventType,
          calendarId: calendarId,
          accessToken: accessToken,
          userId: userId,
        );
      case CalendarProvider.apple:
        throw ApiException(message: 'Apple Calendar desteği henüz eklenmedi');
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
    if (accessToken.isEmpty) {
      throw ApiException(message: 'Access token required');
    }

    switch (provider) {
      case CalendarProvider.google:
        return await _googleCalendarClient.updateEvent(
          eventId: eventId,
          title: title,
          startTime: startTime,
          endTime: endTime,
          description: description,
          location: location,
          eventType: eventType,
          calendarId: calendarId,
          accessToken: accessToken,
          userId: userId,
        );
      case CalendarProvider.outlook:
        return await _outlookCalendarClient.updateEvent(
          eventId: eventId,
          title: title,
          startTime: startTime,
          endTime: endTime,
          description: description,
          location: location,
          eventType: eventType,
          calendarId: calendarId,
          accessToken: accessToken,
          userId: userId,
        );
      case CalendarProvider.apple:
        throw ApiException(message: 'Apple Calendar desteği henüz eklenmedi');
    }
  }

  /// Event silme
  Future<void> deleteEvent({
    required String eventId,
    String? calendarId,
    required String accessToken,
    required CalendarProvider provider,
  }) async {
    if (accessToken.isEmpty) {
      throw ApiException(message: 'Access token required');
    }

    switch (provider) {
      case CalendarProvider.google:
        await _googleCalendarClient.deleteEvent(
          eventId: eventId,
          calendarId: calendarId,
          accessToken: accessToken,
        );
        break;
      case CalendarProvider.outlook:
        await _outlookCalendarClient.deleteEvent(
          eventId: eventId,
          calendarId: calendarId,
          accessToken: accessToken,
        );
        break;
      case CalendarProvider.apple:
        throw ApiException(message: 'Apple Calendar desteği henüz eklenmedi');
    }
  }
}

