import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:go_router/go_router.dart';
import '../models/notification.dart' as app_notification;
import '../core/router/app_router.dart';

/// Bildirim servisi - Local notification'ları yönetir
class NotificationService {
  static NotificationService? _instance;

  factory NotificationService() {
    _instance ??= NotificationService._internal();
    return _instance!;
  }

  NotificationService._internal();

  FlutterLocalNotificationsPlugin? _notificationsPlugin;
  FlutterLocalNotificationsPlugin get _notifications {
    _notificationsPlugin ??= FlutterLocalNotificationsPlugin();
    return _notificationsPlugin!;
  }

  bool _isInitialized = false;

  /// Bildirim servisini başlat
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Timezone verilerini yükle
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));

      // Android ayarları
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS ayarları
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Windows ayarları
      const windowsSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Initialization settings
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
        macOS: windowsSettings, // Windows için macOS ayarları kullanılıyor
      );

      // İzinleri kontrol et ve iste
      await _requestPermissions();

      // Bildirimleri başlat
      final initialized = await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      if (initialized == true) {
        _isInitialized = true;
        debugPrint('✅ Bildirim servisi başlatıldı');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Bildirim servisi başlatılamadı: $e');
      return false;
    }
  }

  /// Bildirim izinlerini iste
  Future<void> _requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Android 13+ için bildirim izni
      final status = await Permission.notification.request();
      if (status.isDenied) {
        debugPrint('⚠️ Bildirim izni reddedildi');
      }
    }
  }

  /// Bildirim tıklandığında çağrılır
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('📱 Bildirim tıklandı: ${response.payload}');

    if (response.payload == null || response.payload!.isEmpty) {
      debugPrint('⚠️ Bildirim payload boş, yönlendirme yapılamıyor');
      return;
    }

    try {
      // Payload'ı parse et (JSON formatında bekleniyor: {"type": "task", "id": 123})
      final payloadMap = jsonDecode(response.payload!) as Map<String, dynamic>;
      final type = payloadMap['type'] as String?;
      final id = payloadMap['id'] as int?;

      if (type == null) {
        debugPrint('⚠️ Bildirim payload\'ında type bulunamadı');
        return;
      }

      // Navigator context'i al
      final context = rootNavigatorKey.currentContext;
      if (context == null) {
        debugPrint('⚠️ Navigator context bulunamadı, yönlendirme yapılamıyor');
        return;
      }

      // Bildirim tipine göre yönlendir
      switch (type.toLowerCase()) {
        case 'task':
          debugPrint('📋 Görev sayfasına yönlendiriliyor (ID: $id)');
          context.go('/tasks');
          break;
        case 'calendar':
          debugPrint('📅 Takvim sayfasına yönlendiriliyor (ID: $id)');
          context.go('/calendar');
          break;
        case 'email':
          debugPrint('📧 E-posta sayfasına yönlendiriliyor (ID: $id)');
          context.go('/email');
          break;
        case 'system':
        default:
          debugPrint('🏠 Ana sayfaya yönlendiriliyor');
          context.go('/home');
          break;
      }
    } catch (e) {
      debugPrint('❌ Bildirim payload parse hatası: $e');
      debugPrint('   Payload: ${response.payload}');
      // Hata durumunda ana sayfaya yönlendir
      final context = rootNavigatorKey.currentContext;
      if (context != null) {
        context.go('/home');
      }
    }
  }

  /// Bildirim gönder (hemen)
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    app_notification.NotificationType? type,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Bildirim türüne göre ikon ve kanal ayarla
      final androidDetails = _getAndroidNotificationDetails(type);
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        id,
        title,
        body,
        details,
        payload: payload,
      );

      debugPrint('✅ Bildirim gönderildi: $title');
    } catch (e) {
      debugPrint('❌ Bildirim gönderilemedi: $e');
    }
  }

  /// Zamanlanmış bildirim gönder
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    app_notification.NotificationType? type,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final androidDetails = _getAndroidNotificationDetails(type);
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Zamanlanmış bildirim
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        details,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );

      debugPrint('✅ Zamanlanmış bildirim oluşturuldu: $title - $scheduledDate');
    } catch (e) {
      debugPrint('❌ Zamanlanmış bildirim oluşturulamadı: $e');
    }
  }

  /// Tekrarlayan bildirim gönder (günlük, haftalık, vb.)
  Future<void> scheduleRepeatingNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required tz.TZDateTime? repeatInterval,
    String? payload,
    app_notification.NotificationType? type,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final androidDetails = _getAndroidNotificationDetails(type);
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: repeatInterval != null ? DateTimeComponents.time : null,
      );

      debugPrint('✅ Tekrarlayan bildirim oluşturuldu: $title');
    } catch (e) {
      debugPrint('❌ Tekrarlayan bildirim oluşturulamadı: $e');
    }
  }

  /// Bildirim türüne göre Android notification details
  AndroidNotificationDetails _getAndroidNotificationDetails(
    app_notification.NotificationType? type,
  ) {
    String channelId = 'default';
    String channelName = 'Genel Bildirimler';
    String channelDescription = 'Genel uygulama bildirimleri';
    Importance importance = Importance.defaultImportance;
    Priority priority = Priority.defaultPriority;

    switch (type) {
      case app_notification.NotificationType.task:
        channelId = 'task_notifications';
        channelName = 'Görev Bildirimleri';
        channelDescription = 'Görev hatırlatıcıları ve son tarih uyarıları';
        importance = Importance.high;
        priority = Priority.high;
        break;
      case app_notification.NotificationType.calendar:
        channelId = 'calendar_notifications';
        channelName = 'Takvim Bildirimleri';
        channelDescription = 'Yaklaşan toplantılar için hatırlatmalar';
        importance = Importance.high;
        priority = Priority.high;
        break;
      case app_notification.NotificationType.email:
        channelId = 'email_notifications';
        channelName = 'E-posta Bildirimleri';
        channelDescription = 'Önemli e-postalar için anında bildirim';
        importance = Importance.high;
        priority = Priority.high;
        break;
      case app_notification.NotificationType.system:
      default:
        channelId = 'system_notifications';
        channelName = 'Sistem Bildirimleri';
        channelDescription = 'Sistem ve AI öngörü bildirimleri';
        importance = Importance.defaultImportance;
        priority = Priority.defaultPriority;
        break;
    }

    return AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: importance,
      priority: priority,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );
  }

  /// Bildirimi iptal et
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
    debugPrint('🗑️ Bildirim iptal edildi: $id');
  }

  /// Tüm bildirimleri iptal et
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    debugPrint('🗑️ Tüm bildirimler iptal edildi');
  }

  /// Bekleyen bildirimleri listele
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// Bildirim izni kontrolü
  Future<bool> hasPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.notification.status;
      return status.isGranted;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      // iOS için izin kontrolü
      final result = await _notifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return result ?? false;
    }

    // Windows için - initialize edilmişse izin var sayılır
    return _isInitialized;
  }

  /// Bildirim izni iste
  Future<bool> requestPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.notification.request();
      return status.isGranted;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      // iOS için izin iste
      final result = await _notifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return result ?? false;
    }

    // Windows için - initialize et ve test bildirimi gönder
    if (!_isInitialized) {
      await initialize();
    }

    // Test bildirimi gönder (Windows otomatik izin isteyecek)
    try {
      await showNotification(
        id: 0,
        title: 'AI Asistan Bildirimleri',
        body: 'Bildirim sistemi hazır! ✅',
      );
      debugPrint('✅ Windows test bildirimi gönderildi');
      return true;
    } catch (e) {
      debugPrint('❌ Windows bildirim hatası: $e');
      return false;
    }
  }
}
