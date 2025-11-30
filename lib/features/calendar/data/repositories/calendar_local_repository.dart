import 'package:ai_asisstan/models/calendar_event.dart';
import 'package:ai_asisstan/core/database/database_service.dart';

/// Calendar event'lerini local database'de yöneten repository
class CalendarLocalRepository {
  final DatabaseService _databaseService;

  CalendarLocalRepository({
    DatabaseService? databaseService,
  }) : _databaseService = databaseService ?? DatabaseService.instance;

  /// Tüm event'leri getir (local database'den)
  Future<List<CalendarEvent>> getEvents({
    int? userId,
    DateTime? timeMin,
    DateTime? timeMax,
    EventSource? source,
    List<String>? externalIdList,
  }) async {
    final db = await _databaseService.database;

    var query = 'SELECT * FROM calendar_events WHERE 1=1';
    final whereArgs = <dynamic>[];

    if (userId != null) {
      query += ' AND user_id = ?';
      whereArgs.add(userId);
    }

    if (timeMin != null) {
      query += ' AND start_time >= ?';
      whereArgs.add(timeMin.toIso8601String());
    }

    if (timeMax != null) {
      query += ' AND end_time <= ?';
      whereArgs.add(timeMax.toIso8601String());
    }

    if (source != null) {
      query += ' AND source = ?';
      whereArgs.add(source.name);
    }

    if (externalIdList != null && externalIdList.isNotEmpty) {
      query += ' AND external_id IN (${externalIdList.map((_) => '?').join(',')})';
      whereArgs.addAll(externalIdList);
    }

    query += ' ORDER BY start_time ASC';

    final maps = await db.rawQuery(query, whereArgs);
    return maps.map((map) => CalendarEvent.fromDatabase(map)).toList();
  }

  /// Event'i local database'e kaydet
  Future<CalendarEvent> saveEvent(CalendarEvent event) async {
    final db = await _databaseService.database;

    // External ID ile kontrol et (Google Calendar event'i zaten var mı?)
    if (event.externalId != null && event.externalId!.isNotEmpty) {
      final existing = await db.query(
        'calendar_events',
        where: 'external_id = ? AND user_id = ?',
        whereArgs: [event.externalId, event.userId],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        // Güncelle
        final data = event.toDatabase();
        await db.update(
          'calendar_events',
          data,
          where: 'id = ?',
          whereArgs: [existing.first['id']],
        );
        return event.copyWith(id: existing.first['id'] as int);
      }
    }

    // Yeni event ekle
    final data = event.toDatabase();
    final id = await db.insert('calendar_events', data);
    return event.copyWith(id: id);
  }

  /// Birden fazla event'i kaydet
  Future<List<CalendarEvent>> saveEvents(List<CalendarEvent> events) async {
    final savedEvents = <CalendarEvent>[];
    for (final event in events) {
      final saved = await saveEvent(event);
      savedEvents.add(saved);
    }
    return savedEvents;
  }

  /// Event'i sil
  Future<void> deleteEvent(int eventId) async {
    final db = await _databaseService.database;
    await db.delete(
      'calendar_events',
      where: 'id = ?',
      whereArgs: [eventId],
    );
  }

  /// External ID ile event'i sil (Google Calendar event'i silindiğinde)
  Future<void> deleteEventByExternalId(String externalId, int userId) async {
    final db = await _databaseService.database;
    await db.delete(
      'calendar_events',
      where: 'external_id = ? AND user_id = ?',
      whereArgs: [externalId, userId],
    );
  }

  /// Kullanıcının tüm event'lerini sil
  Future<void> deleteAllEvents(int userId) async {
    final db = await _databaseService.database;
    await db.delete(
      'calendar_events',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  /// Belirli bir source'dan event'leri sil (örn: Google Calendar'dan gelenler)
  Future<void> deleteEventsBySource(EventSource source, int userId) async {
    final db = await _databaseService.database;
    await db.delete(
      'calendar_events',
      where: 'source = ? AND user_id = ?',
      whereArgs: [source.name, userId],
    );
  }
}

