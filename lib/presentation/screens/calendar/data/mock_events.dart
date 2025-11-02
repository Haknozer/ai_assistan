import '../../../../models/calendar_event.dart';

/// Mock takvim etkinlikleri - Test ve geliştirme için
class MockEvents {
  static final List<CalendarEvent> events = [
    CalendarEvent(
      id: 1,
      userId: 1,
      title: 'Proje Sunumu',
      description: 'Müşteri için Q4 sunumu',
      startTime: DateTime.now().add(const Duration(hours: 2)),
      endTime: DateTime.now().add(const Duration(hours: 4)),
      location: 'Toplantı Odası A',
      eventType: EventType.meeting,
      source: EventSource.manual,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    CalendarEvent(
      id: 2,
      userId: 1,
      title: 'Tasarım Değerlendirmesi',
      description: 'Yeni arayüz tasarımını inceleme',
      startTime: DateTime.now().add(const Duration(days: 1, hours: 10)),
      endTime: DateTime.now().add(const Duration(days: 1, hours: 11)),
      location: 'Online - Google Meet',
      eventType: EventType.appointment,
      source: EventSource.google,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    CalendarEvent(
      id: 3,
      userId: 1,
      title: 'Ekip Kahvaltısı',
      description: 'Aylık ekip kahvaltısı',
      startTime: DateTime.now().add(const Duration(days: 2, hours: 9)),
      endTime: DateTime.now().add(const Duration(days: 2, hours: 10)),
      location: 'Şirket Kafeteryası',
      eventType: EventType.personal,
      source: EventSource.manual,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    CalendarEvent(
      id: 4,
      userId: 1,
      title: 'Kod Review',
      description: 'Backend API kod incelemesi',
      startTime: DateTime.now().subtract(const Duration(hours: 1)),
      endTime: DateTime.now().subtract(const Duration(minutes: 30)),
      location: 'Geliştirme Odası',
      eventType: EventType.task,
      source: EventSource.manual,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    CalendarEvent(
      id: 5,
      userId: 1,
      title: 'Yıl Sonu Toplantısı',
      description: 'Departman yıl sonu değerlendirme',
      startTime: DateTime.now().add(const Duration(days: 5, hours: 14)),
      endTime: DateTime.now().add(const Duration(days: 5, hours: 17)),
      location: 'Ana Konferans Salonu',
      eventType: EventType.meeting,
      source: EventSource.outlook,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  /// Belirli bir gün için etkinlikleri getir
  static List<CalendarEvent> getEventsForDay(
      List<CalendarEvent> allEvents, DateTime day) {
    return allEvents.where((event) {
      return event.startTime.year == day.year &&
          event.startTime.month == day.month &&
          event.startTime.day == day.day;
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  /// Belirli bir ay için etkinlikleri getir
  static List<CalendarEvent> getEventsForMonth(
      List<CalendarEvent> allEvents, DateTime month) {
    return allEvents.where((event) {
      return event.startTime.year == month.year &&
          event.startTime.month == month.month;
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  /// Bugünün etkinliklerini getir
  static List<CalendarEvent> getTodayEvents(List<CalendarEvent> allEvents) {
    return getEventsForDay(allEvents, DateTime.now());
  }

  /// Yaklaşan etkinlikleri getir (gelecek 7 gün)
  static List<CalendarEvent> getUpcomingEvents(List<CalendarEvent> allEvents) {
    final now = DateTime.now();
    final nextWeek = now.add(const Duration(days: 7));
    return allEvents.where((event) {
      return event.startTime.isAfter(now) &&
          event.startTime.isBefore(nextWeek);
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }
}

