import 'package:flutter/foundation.dart';
import '../models/calendar_event.dart';
import 'task_notification_service.dart'; // Aynı ayarları kullanmak için

/// Takvim bildirimleri servisi - Sadece uygulama içi bildirimler
/// Görev bildirimleri ile aynı mantıkta çalışır
class CalendarNotificationService {
  static CalendarNotificationService? _instance;

  factory CalendarNotificationService() {
    _instance ??= CalendarNotificationService._internal();
    return _instance!;
  }

  CalendarNotificationService._internal();

  // Bildirim ID'leri için base değer (takvim bildirimleri 2000'den başlar)
  static const int _calendarNotificationIdBase = 2000;

  // Zamanlanmış bildirimler için hafıza (in-memory scheduling)
  final Map<int, ScheduledCalendarNotification> _scheduledNotifications = {};

  /// Takvim event'i için bildirim ID'si oluştur
  int _generateNotificationId(int eventId) {
    return _calendarNotificationIdBase + eventId;
  }

  /// Bildirim zamanlama ayarlarını getir (kaç dakika önce bildirim gönderilecek)
  /// Görev bildirimleri ile aynı ayarı kullanır
  Future<int> getNotificationMinutesBefore() async {
    final taskNotificationService = TaskNotificationService();
    return await taskNotificationService.getNotificationMinutesBefore();
  }

  /// Takvim event bildirimi zamanla (sadece hafızada)
  Future<void> scheduleCalendarNotification(CalendarEvent event) async {
    if (event.id == null) {
      debugPrint('⚠️ Event ID yok, bildirim zamanlanamadı');
      return;
    }

    // Geçmiş tarih kontrolü
    if (event.startTime.isBefore(DateTime.now())) {
      debugPrint('⚠️ Event tarihi geçmiş, bildirim zamanlanmadı: ${event.title}');
      return;
    }

    try {
      final minutesBefore = await getNotificationMinutesBefore();
      final notificationTime = event.startTime.subtract(Duration(minutes: minutesBefore));

      // Bildirim zamanı geçmişse, 1 dakika sonrasına zamanla (overlay hazır olsun diye)
      final now = DateTime.now();
      final scheduledTime = notificationTime.isBefore(now) ? now.add(const Duration(minutes: 1)) : notificationTime;

      final notificationId = _generateNotificationId(event.id!);

      // Bildirim içeriği
      String body = 'Başlangıç: ${event.formattedStartTime}';
      if (event.location != null && event.location!.isNotEmpty) {
        body += '\nKonum: ${event.location}';
      }
      if (event.description != null && event.description!.isNotEmpty) {
        body += '\n${event.description}';
      }

      // Hafızada sakla
      _scheduledNotifications[notificationId] = ScheduledCalendarNotification(
        event: event,
        scheduledTime: scheduledTime,
        title: '📅 ${event.title}',
        body: body,
      );

      debugPrint('✅ Takvim bildirimi zamanlandı (in-app): ${event.title}');
      debugPrint('   📅 Event tarihi: ${event.formattedStartTime}');
      debugPrint('   🔔 Bildirim zamanı: ${_formatDateTime(scheduledTime)}');
      debugPrint('   ⏱️  $minutesBefore dakika önce');
    } catch (e) {
      debugPrint('⚠️ Takvim bildirimi zamanlanırken küçük hata (göz ardı edilebilir): $e');
    }
  }

  /// Takvim bildirimini iptal et
  Future<void> cancelCalendarNotification(int eventId) async {
    try {
      final notificationId = _generateNotificationId(eventId);
      _scheduledNotifications.remove(notificationId);
      debugPrint('✅ Takvim bildirimi iptal edildi: Event ID $eventId');
    } catch (e) {
      debugPrint('❌ Takvim bildirimi iptal edilemedi: $e');
    }
  }

  /// Event güncellendiğinde bildirimi yeniden zamanla
  Future<void> rescheduleCalendarNotification(CalendarEvent event) async {
    if (event.id == null) return;

    // Önce eski bildirimi iptal et
    await cancelCalendarNotification(event.id!);

    // Yeni bildirim zamanla
    await scheduleCalendarNotification(event);
  }

  /// Tüm bekleyen event'ler için bildirimleri yeniden zamanla
  Future<void> rescheduleAllCalendarNotifications(List<CalendarEvent> events) async {
    debugPrint('🔄 Tüm takvim bildirimleri yeniden zamanlanıyor (in-app)...');

    int scheduled = 0;
    for (final event in events) {
      if (event.startTime.isAfter(DateTime.now())) {
        await scheduleCalendarNotification(event);
        scheduled++;
      }
    }

    debugPrint('✅ $scheduled takvim bildirimi zamanlandı (in-app)');
  }

  /// Zamanı gelen bildirimleri kontrol et ve döndür
  List<ScheduledCalendarNotification> checkPendingNotifications() {
    final now = DateTime.now();
    final pending = <ScheduledCalendarNotification>[];

    _scheduledNotifications.removeWhere((id, notification) {
      if (notification.scheduledTime.isBefore(now) || notification.scheduledTime.isAtSameMomentAs(now)) {
        pending.add(notification);
        return true; // Listeden kaldır
      }
      return false;
    });

    return pending;
  }

  /// Zamanlanmış bildirim sayısı
  int get scheduledCount => _scheduledNotifications.length;

  /// Tarih formatla
  String _formatDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day.$month.$year $hour:$minute';
  }
}

/// Zamanlanmış takvim bildirimi için internal model
class ScheduledCalendarNotification {
  final CalendarEvent event;
  final DateTime scheduledTime;
  final String title;
  final String body;

  ScheduledCalendarNotification({
    required this.event,
    required this.scheduledTime,
    required this.title,
    required this.body,
  });
}
