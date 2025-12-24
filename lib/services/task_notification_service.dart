import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';

/// Görev bildirimleri servisi - Sadece uygulama içi bildirimler
/// Not: Windows native bildirimleri devre dışı, sadece in-app overlay kullanılacak
class TaskNotificationService {
  static TaskNotificationService? _instance;

  factory TaskNotificationService() {
    _instance ??= TaskNotificationService._internal();
    return _instance!;
  }

  TaskNotificationService._internal();

  // Bildirim ID'leri için base değer (görev bildirimleri 1000'den başlar)
  static const int _taskNotificationIdBase = 1000;

  // Varsayılan bildirim süresi (görev zamanından kaç dakika önce)
  static const int _defaultNotificationMinutesBefore = 5;

  // Zamanlanmış bildirimler için hafıza (in-memory scheduling)
  final Map<int, ScheduledNotification> _scheduledNotifications = {};

  /// Görev için bildirim ID'si oluştur
  int _generateNotificationId(int taskId) {
    return _taskNotificationIdBase + taskId;
  }

  /// Bildirim zamanlama ayarlarını getir (kaç dakika önce bildirim gönderilecek)
  Future<int> getNotificationMinutesBefore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('task_notification_minutes_before') ?? _defaultNotificationMinutesBefore;
    } catch (e) {
      debugPrint('❌ Bildirim ayarları alınamadı: $e');
      return _defaultNotificationMinutesBefore;
    }
  }

  /// Bildirim zamanlama ayarını kaydet
  Future<void> setNotificationMinutesBefore(int minutes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('task_notification_minutes_before', minutes);
      debugPrint('✅ Bildirim zamanı ayarlandı: $minutes dakika önce');
    } catch (e) {
      debugPrint('❌ Bildirim ayarı kaydedilemedi: $e');
    }
  }

  /// Görev bildirimi zamanla (sadece hafızada)
  Future<void> scheduleTaskNotification(Task task) async {
    if (task.id == null || task.dueDate == null) {
      debugPrint('⚠️ Görev ID veya bitiş tarihi yok, bildirim zamanlanamadı');
      return;
    }

    // Geçmiş tarih kontrolü
    if (task.dueDate!.isBefore(DateTime.now())) {
      debugPrint('⚠️ Görev tarihi geçmiş, bildirim zamanlanmadı: ${task.title}');
      return;
    }

    // Tamamlanmış görevler için bildirim zamanlanmaz
    if (task.status == TaskStatus.completed || task.status == TaskStatus.cancelled) {
      debugPrint('⚠️ Görev tamamlanmış/iptal edilmiş, bildirim zamanlanmadı: ${task.title}');
      return;
    }

    try {
      final minutesBefore = await getNotificationMinutesBefore();
      final notificationTime = task.dueDate!.subtract(Duration(minutes: minutesBefore));

      // Bildirim zamanı geçmişse, 1 dakika sonrasına zamanla (overlay hazır olsun diye)
      final now = DateTime.now();
      final scheduledTime = notificationTime.isBefore(now) ? now.add(const Duration(minutes: 1)) : notificationTime;

      final notificationId = _generateNotificationId(task.id!);

      // Bildirim içeriği
      String body = 'Son tarih: ${task.formattedDueDate}';
      if (task.description != null && task.description!.isNotEmpty) {
        body += '\n${task.description}';
      }
      body += '\nÖncelik: ${task.priority.displayName}';

      // Hafızada sakla
      _scheduledNotifications[notificationId] = ScheduledNotification(
        task: task,
        scheduledTime: scheduledTime,
        title: '⏰ ${task.title}',
        body: body,
      );

      debugPrint('✅ Görev bildirimi zamanlandı (in-app): ${task.title}');
      debugPrint('   📅 Görev tarihi: ${task.formattedDueDate}');
      debugPrint('   🔔 Bildirim zamanı: ${_formatDateTime(scheduledTime)}');
      debugPrint('   ⏱️  $minutesBefore dakika önce');
    } catch (e) {
      // Hata oluşsa bile bildirim zamanlandı (hafızada), sadece log'la
      debugPrint('⚠️ Görev bildirimi zamanlanırken küçük hata (göz ardı edilebilir): $e');
    }
  }

  /// Görev bildirimini iptal et
  Future<void> cancelTaskNotification(int taskId) async {
    try {
      final notificationId = _generateNotificationId(taskId);
      _scheduledNotifications.remove(notificationId);
      debugPrint('✅ Görev bildirimi iptal edildi: Task ID $taskId');
    } catch (e) {
      debugPrint('❌ Görev bildirimi iptal edilemedi: $e');
    }
  }

  /// Görev güncellendiğinde bildirimi yeniden zamanla
  Future<void> rescheduleTaskNotification(Task task) async {
    if (task.id == null) return;

    // Önce eski bildirimi iptal et
    await cancelTaskNotification(task.id!);

    // Yeni bildirim zamanla
    await scheduleTaskNotification(task);
  }

  /// Tüm bekleyen görevler için bildirimleri yeniden zamanla
  Future<void> rescheduleAllTaskNotifications(List<Task> tasks) async {
    debugPrint('🔄 Tüm görev bildirimleri yeniden zamanlanıyor (in-app)...');

    int scheduled = 0;
    for (final task in tasks) {
      if (task.dueDate != null &&
          task.status != TaskStatus.completed &&
          task.status != TaskStatus.cancelled &&
          task.dueDate!.isAfter(DateTime.now())) {
        await scheduleTaskNotification(task);
        scheduled++;
      }
    }

    debugPrint('✅ $scheduled görev bildirimi zamanlandı (in-app)');
  }

  /// Zamanı gelen bildirimleri kontrol et ve döndür
  List<ScheduledNotification> checkPendingNotifications() {
    final now = DateTime.now();
    final pending = <ScheduledNotification>[];

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

  /// Önceliğe göre farklı zamanlarda bildirim gönder
  Future<void> scheduleTaskNotificationByPriority(Task task) async {
    if (task.id == null || task.dueDate == null) return;

    // Önceliğe göre bildirim zamanlarını ayarla
    int minutesBefore;
    switch (task.priority) {
      case TaskPriority.urgent:
        minutesBefore = 30; // Acil görevler 30 dk önce
        break;
      case TaskPriority.high:
        minutesBefore = 60; // Yüksek öncelik 1 saat önce
        break;
      case TaskPriority.medium:
        minutesBefore = 120; // Orta öncelik 2 saat önce
        break;
      case TaskPriority.low:
        minutesBefore = 240; // Düşük öncelik 4 saat önce
        break;
    }

    final notificationTime = task.dueDate!.subtract(Duration(minutes: minutesBefore));

    // Bildirim zamanı geçmişse, 1 dakika sonrasına zamanla
    final now = DateTime.now();
    final scheduledTime = notificationTime.isBefore(now) ? now.add(const Duration(minutes: 1)) : notificationTime;

    try {
      final notificationId = _generateNotificationId(task.id!);

      String body = '${task.priority.displayName} öncelikli görev\n';
      body += 'Son tarih: ${task.formattedDueDate}';
      if (task.description != null && task.description!.isNotEmpty) {
        body += '\n${task.description}';
      }

      // Hafızada sakla
      _scheduledNotifications[notificationId] = ScheduledNotification(
        task: task,
        scheduledTime: scheduledTime,
        title: '${_getPriorityEmoji(task.priority)} ${task.title}',
        body: body,
      );

      debugPrint('✅ Öncelikli görev bildirimi zamanlandı (in-app): ${task.title}');
      debugPrint('   🎯 Öncelik: ${task.priority.displayName}');
      debugPrint('   🔔 $minutesBefore dakika önce bildirim');
    } catch (e) {
      debugPrint('❌ Öncelikli görev bildirimi zamanlanamadı: $e');
    }
  }

  /// Öncelik emojisi
  String _getPriorityEmoji(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.urgent:
        return '🚨';
      case TaskPriority.high:
        return '🔴';
      case TaskPriority.medium:
        return '🟡';
      case TaskPriority.low:
        return '🟢';
    }
  }
}

/// Zamanlanmış bildirim için internal model
class ScheduledNotification {
  final Task task;
  final DateTime scheduledTime;
  final String title;
  final String body;

  ScheduledNotification({
    required this.task,
    required this.scheduledTime,
    required this.title,
    required this.body,
  });
}
