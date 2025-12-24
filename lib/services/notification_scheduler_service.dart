import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../models/calendar_event.dart';
import '../repositories/task_repository.dart';
import '../features/calendar/data/repositories/calendar_local_repository.dart';
import '../providers/notification_provider.dart';
import '../core/utils/logger.dart';
import 'task_notification_service.dart';
import 'calendar_notification_service.dart';

/// Bildirim zamanlayıcı servisi - Periyodik olarak görev ve takvim bildirimlerini kontrol eder
class NotificationSchedulerService {
  static final NotificationSchedulerService _instance = NotificationSchedulerService._internal();
  factory NotificationSchedulerService() => _instance;
  NotificationSchedulerService._internal();

  Timer? _checkTimer;
  bool _isRunning = false;

  // Public getter for _isRunning (for external access)
  bool get isRunning => _isRunning;

  // Bildirim gönderilmiş görev/event ID'lerini takip et (duplicate önlemek için)
  final Set<String> _notifiedTaskIds = {};
  final Set<String> _notifiedEventIds = {};

  /// Bildirim kontrolünü başlat
  void start({required NotificationSender notificationSender, required int userId}) {
    if (_isRunning) {
      debugPrint('⚠️ Bildirim scheduler zaten çalışıyor');
      return;
    }

    _isRunning = true;
    debugPrint('✅ Bildirim scheduler başlatıldı (her 1 dakikada kontrol)');

    // İlk kontrolü hemen yap
    _checkNotifications(notificationSender, userId);

    // Her 1 dakikada bir kontrol et
    _checkTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkNotifications(notificationSender, userId);
    });
  }

  /// Bildirim kontrolünü durdur
  void stop() {
    _checkTimer?.cancel();
    _checkTimer = null;
    _isRunning = false;
    debugPrint('🛑 Bildirim scheduler durduruldu');
  }

  /// Bildirimleri kontrol et ve gönder
  Future<void> _checkNotifications(NotificationSender notificationSender, int userId) async {
    try {
      await _checkTaskNotifications(notificationSender, userId);
      await _checkCalendarNotifications(notificationSender, userId);
    } catch (e) {
      AppLogger.error('Bildirim kontrolü hatası', tag: 'NotificationScheduler', error: e);
    }
  }

  /// Görev bildirimlerini kontrol et
  Future<void> _checkTaskNotifications(NotificationSender notificationSender, int userId) async {
    try {
      // 1. TaskNotificationService'den zamanlanmış bildirimleri kontrol et
      final taskNotificationService = TaskNotificationService();
      final pendingNotifications = taskNotificationService.checkPendingNotifications();

      // Zamanı gelen bildirimleri göster
      for (final notification in pendingNotifications) {
        try {
          notificationSender.sendTaskNotification(
            taskId: notification.task.id ?? 0,
            taskTitle: notification.task.title,
            message: notification.body,
          );
          AppLogger.info('⏰ Zamanlanmış görev bildirimi: ${notification.task.title}', 'NotificationScheduler');
        } catch (e) {
          AppLogger.error('Bildirim gönderme hatası: ${notification.task.title}',
              tag: 'NotificationScheduler', error: e);
        }
      }

      // 2. Database'den görevleri kontrol et (yedek mekanizma)
      final taskRepository = TaskRepository();
      final tasks = await taskRepository.getTasksByUserId(userId);

      final now = DateTime.now();

      // Kullanıcının ayarladığı bildirim zamanını al (örn: 5 dakika önce)
      final notificationMinutesBefore = await taskNotificationService.getNotificationMinutesBefore();
      debugPrint('📋 Görev bildirimi kontrolü: $notificationMinutesBefore dakika öncesi kontrolü');

      for (final task in tasks) {
        // Sadece tamamlanmamış görevler için kontrol et
        if (task.status == TaskStatus.completed) continue;
        if (task.dueDate == null) continue;

        final taskKey = 'task_${task.id}';

        // Bu görev için zaten bildirim gönderilmiş mi?
        if (_notifiedTaskIds.contains(taskKey)) continue;

        final dueDate = task.dueDate!;
        final difference = dueDate.difference(now);

        // Kullanıcının ayarına göre bildirim zamanını hesapla
        // Örn: Görev 10:00'da bitecek, ayar 5 dakika ise -> 09:55'te bildirim gönder
        // 1 dakikalık tolerans (çünkü her 1 dakikada kontrol ediyoruz)
        if (difference.inMinutes >= (notificationMinutesBefore - 1) &&
            difference.inMinutes <= (notificationMinutesBefore + 1)) {
          try {
            notificationSender.sendTaskNotification(
              taskId: task.id ?? 0,
              taskTitle: task.title,
              message: 'Son tarih $notificationMinutesBefore dakika sonra!',
            );
            _notifiedTaskIds.add(taskKey);
            AppLogger.info('📋 Görev bildirimi gönderildi: ${task.title} ($notificationMinutesBefore dk önce)',
                'NotificationScheduler');
          } catch (e) {
            AppLogger.error('Görev bildirimi hatası: ${task.title}', tag: 'NotificationScheduler', error: e);
          }
        }
      }
    } catch (e) {
      AppLogger.error('Görev bildirim kontrolü hatası', tag: 'NotificationScheduler', error: e);
    }
  }

  /// Takvim bildirimlerini kontrol et
  Future<void> _checkCalendarNotifications(NotificationSender notificationSender, int userId) async {
    try {
      // 1. CalendarNotificationService'den zamanlanmış bildirimleri kontrol et
      final calendarNotificationService = CalendarNotificationService();
      final pendingNotifications = calendarNotificationService.checkPendingNotifications();

      // Zamanı gelen bildirimleri göster
      for (final notification in pendingNotifications) {
        try {
          notificationSender.sendCalendarNotification(
            eventId: notification.event.id ?? 0,
            eventTitle: notification.event.title,
            minutesBefore: 0, // Zaten zamanı geldi
          );
          AppLogger.info('⏰ Zamanlanmış takvim bildirimi: ${notification.event.title}', 'NotificationScheduler');
        } catch (e) {
          AppLogger.error('Bildirim gönderme hatası: ${notification.event.title}',
              tag: 'NotificationScheduler', error: e);
        }
      }

      // 2. Database'den event'leri kontrol et (yedek mekanizma)
      final calendarLocalRepository = CalendarLocalRepository();
      final now = DateTime.now();
      final timeMax = now.add(const Duration(days: 7)); // Gelecek 7 gün içindeki event'ler

      final events = await calendarLocalRepository.getEvents(
        userId: userId,
        timeMin: now,
        timeMax: timeMax,
      );

      // Kullanıcının ayarladığı bildirim zamanını al (örn: 5 dakika önce)
      final notificationMinutesBefore = await calendarNotificationService.getNotificationMinutesBefore();
      debugPrint('📅 Takvim bildirimi kontrolü: $notificationMinutesBefore dakika öncesi kontrolü');

      for (final event in events) {
        // Geçmiş event'leri atla
        if (event.startTime.isBefore(now)) continue;

        final eventKey = 'event_${event.id}';

        // Bu event için zaten bildirim gönderilmiş mi?
        if (_notifiedEventIds.contains(eventKey)) continue;

        final startTime = event.startTime;
        final difference = startTime.difference(now);

        // Kullanıcının ayarına göre bildirim zamanını hesapla
        // Örn: Event 10:00'da başlayacak, ayar 5 dakika ise -> 09:55'te bildirim gönder
        // 1 dakikalık tolerans (çünkü her 1 dakikada kontrol ediyoruz)
        if (difference.inMinutes >= (notificationMinutesBefore - 1) &&
            difference.inMinutes <= (notificationMinutesBefore + 1)) {
          try {
            notificationSender.sendCalendarNotification(
              eventId: event.id ?? 0,
              eventTitle: event.title,
              minutesBefore: notificationMinutesBefore,
            );
            _notifiedEventIds.add(eventKey);
            AppLogger.info('📅 Takvim bildirimi gönderildi: ${event.title} ($notificationMinutesBefore dk önce)',
                'NotificationScheduler');
          } catch (e) {
            AppLogger.error('Takvim bildirimi hatası: ${event.title}', tag: 'NotificationScheduler', error: e);
          }
        }
      }
    } catch (e) {
      AppLogger.error('Takvim bildirim kontrolü hatası', tag: 'NotificationScheduler', error: e);
    }
  }

  /// Görev bildirimi gönder (görev oluşturulduğunda/güncellendiğinde)
  /// Not: Bu metod artık direkt bildirim göstermiyor, sadece zamanlamayı logluyor
  Future<void> scheduleTaskNotification({
    required NotificationSender notificationSender,
    required Task task,
  }) async {
    if (task.dueDate == null) return;
    if (task.status == TaskStatus.completed) return;

    final now = DateTime.now();
    final dueDate = task.dueDate!;
    final difference = dueDate.difference(now);

    // Bildirimler periyodik kontrol ile gösterilecek (her 1 dakikada)
    // Hemen bildirim gösterme - overlay hazır olmayabilir
    if (difference.inMinutes <= 0) {
      debugPrint('📋 Görev zamanlandı (son tarih geçti): ${task.title}');
      debugPrint('   ⏰ Bir sonraki kontrol döngüsünde bildirim gösterilecek');
    } else {
      debugPrint('📋 Görev zamanlandı: ${task.title} için ${dueDate.toString()}');
      debugPrint('   ⏰ Zamanlanmış bildirimler periyodik kontrol ile gösterilecek');
    }
  }

  /// Takvim bildirimi gönder (event oluşturulduğunda)
  Future<void> scheduleCalendarNotification({
    required NotificationSender notificationSender,
    required CalendarEvent event,
    int minutesBefore = 15,
  }) async {
    final now = DateTime.now();
    final startTime = event.startTime;
    final notificationTime = startTime.subtract(Duration(minutes: minutesBefore));

    // Bildirim zamanı geçti mi veya şimdi mi kontrol et
    if (notificationTime.isBefore(now.add(const Duration(minutes: 1)))) {
      notificationSender.sendCalendarNotification(
        eventId: event.id ?? 0,
        eventTitle: event.title,
        minutesBefore: minutesBefore,
      );
      debugPrint('📅 Toplantı bildirimi: ${event.title}');
    } else {
      debugPrint('📅 Toplantı zamanlandı: ${event.title} için ${notificationTime.toString()}');
    }
  }

  /// Bildirim cache'ini temizle (görev/event silindiğinde veya güncellendiğinde)
  void clearNotificationCache({int? taskId, int? eventId}) {
    if (taskId != null) {
      _notifiedTaskIds.remove('task_$taskId');
    }
    if (eventId != null) {
      _notifiedEventIds.remove('event_$eventId');
    }
  }
}
