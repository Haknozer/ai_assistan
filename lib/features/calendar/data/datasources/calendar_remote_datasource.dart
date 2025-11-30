import 'package:ai_asisstan/core/api/api_client.dart';
import 'package:ai_asisstan/core/api/api_exceptions.dart';
import 'package:ai_asisstan/models/calendar_event.dart';
import 'google/google_calendar_api_client.dart';

/// Calendar remote data source - Google Calendar API çağrılarını yönetir
class CalendarRemoteDataSource {
  final GoogleCalendarApiClient _googleCalendarClient;

  CalendarRemoteDataSource({
    ApiClient? apiClient,
    GoogleCalendarApiClient? googleCalendarClient,
  }) : _googleCalendarClient = googleCalendarClient ?? GoogleCalendarApiClient(apiClient: apiClient);

  /// Calendar listesini çekme
  Future<List<Map<String, dynamic>>> getCalendars({
    required String accessToken,
  }) async {
    if (accessToken.isEmpty) {
      throw ApiException(message: 'Access token required');
    }

    return await _googleCalendarClient.getCalendars(
      accessToken: accessToken,
    );
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
    if (accessToken.isEmpty) {
      throw ApiException(message: 'Access token required');
    }

    return await _googleCalendarClient.getEvents(
      calendarId: calendarId,
      timeMin: timeMin,
      timeMax: timeMax,
      maxResults: maxResults,
      accessToken: accessToken,
      userId: userId,
    );
  }

  /// Tek event detayını çekme
  Future<CalendarEvent?> getEventById({
    required String eventId,
    String? calendarId,
    required String accessToken,
    int? userId,
  }) async {
    if (accessToken.isEmpty) {
      throw ApiException(message: 'Access token required');
    }

    return await _googleCalendarClient.getEventById(
      eventId: eventId,
      calendarId: calendarId,
      accessToken: accessToken,
      userId: userId,
    );
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
    if (accessToken.isEmpty) {
      throw ApiException(message: 'Access token required');
    }

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
    if (accessToken.isEmpty) {
      throw ApiException(message: 'Access token required');
    }

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
  }

  /// Event silme
  Future<void> deleteEvent({
    required String eventId,
    String? calendarId,
    required String accessToken,
  }) async {
    if (accessToken.isEmpty) {
      throw ApiException(message: 'Access token required');
    }

    await _googleCalendarClient.deleteEvent(
      eventId: eventId,
      calendarId: calendarId,
      accessToken: accessToken,
    );
  }
}

