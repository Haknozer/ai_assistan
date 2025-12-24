import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification.dart' as app_notification;
import '../providers/user_setting_provider.dart';
import '../providers/user_provider.dart';
import '../models/user_setting.dart';
import '../presentation/widgets/common/app_notification_overlay.dart';
import '../core/router/app_router.dart';
import '../main.dart' show getOverlayContext;
import '../services/simple_notification_service.dart';

// Windows bildirim servisi kaldırıldı - uygulama içi bildirimler kullanılıyor

/// Global overlay context'i al
BuildContext? _getOverlayContext() {
  try {
    return getOverlayContext();
  } catch (e) {
    // Fallback: rootNavigatorKey'den al
    return rootNavigatorKey.currentContext;
  }
}

/// Bildirim ayarları provider
final notificationSettingsProvider = StateNotifierProvider<NotificationSettingsNotifier, Map<String, bool>>((ref) {
  final userSettings = ref.watch(currentUserSettingsNotifierProvider);
  final user = ref.watch(currentUserProvider);

  return NotificationSettingsNotifier(
    ref.read(userSettingNotifierProvider.notifier),
    user?.id,
    userSettings.value,
  );
});

/// Bildirim ayarları notifier
class NotificationSettingsNotifier extends StateNotifier<Map<String, bool>> {
  final UserSettingNotifier _userSettingNotifier;
  final int? _userId;
  final List<UserSetting>? _settings;

  NotificationSettingsNotifier(
    this._userSettingNotifier,
    this._userId,
    this._settings,
  ) : super(_loadNotificationSettings(_settings)) {
    // Ayarlar değiştiğinde güncelle
    if (_settings != null) {
      state = _loadNotificationSettings(_settings);
    }
  }

  /// Bildirim ayarlarını yükle
  static Map<String, bool> _loadNotificationSettings(List<UserSetting>? settings) {
    if (settings == null) {
      return {
        'task_reminders': true,
        'calendar_reminders': true,
        'email_notifications': false,
      };
    }

    return {
      'task_reminders': _getSettingValue(settings, 'task_reminders', true),
      'calendar_reminders': _getSettingValue(settings, 'calendar_reminders', true),
      'email_notifications': _getSettingValue(settings, 'email_notifications', false),
    };
  }

  /// Ayar değerini al
  static bool _getSettingValue(List<UserSetting> settings, String key, bool defaultValue) {
    try {
      final setting = settings.firstWhere(
        (s) => s.settingKey == key,
        orElse: () => UserSetting(
          userId: 0,
          settingKey: key,
          settingValue: defaultValue.toString(),
          category: SettingCategory.notifications,
          updatedAt: DateTime.now(),
        ),
      );
      return setting.getBoolValue();
    } catch (e) {
      return defaultValue;
    }
  }

  /// Bildirim ayarını güncelle
  Future<void> updateNotificationSetting(String key, bool value) async {
    if (_userId == null) {
      debugPrint('⚠️ Kullanıcı ID yok, bildirim ayarı güncellenemedi');
      return;
    }

    // State'i güncelle
    state = {...state, key: value};

    // Veritabanına kaydet
    await _userSettingNotifier.updateBoolSetting(
      _userId!,
      key,
      value,
      category: SettingCategory.notifications,
    );

    debugPrint('✅ Bildirim ayarı güncellendi: $key = $value');
  }

  /// Bildirim ayarını kontrol et
  bool isNotificationEnabled(String key) {
    try {
      // mounted kontrolü (StateNotifier için)
      if (!mounted) {
        debugPrint('⚠️ NotificationSettingsNotifier disposed, varsayılan değer döndürülüyor');
        // Dispose edildiyse varsayılan değerleri kullan
        switch (key) {
          case 'task_reminders':
            return true;
          case 'calendar_reminders':
            return true;
          case 'email_notifications':
            return false;
          default:
            return true;
        }
      }
      // State'ten değeri al, yoksa varsayılan değerleri kullan
      if (!state.containsKey(key)) {
        // Varsayılan değerler
        switch (key) {
          case 'task_reminders':
            return true;
          case 'calendar_reminders':
            return true;
          case 'email_notifications':
            return false;
          default:
            return true;
        }
      }
      // State'ten değeri al, yoksa varsayılan değerleri kullan
      if (!state.containsKey(key)) {
        // Varsayılan değerler
        switch (key) {
          case 'task_reminders':
            return true;
          case 'calendar_reminders':
            return true;
          case 'email_notifications':
            return false;
          default:
            return true;
        }
      }
      return state[key] ?? false;
    } catch (e) {
      debugPrint('⚠️ isNotificationEnabled hatası: $e');
      // Hata durumunda varsayılan değerleri kullan
      switch (key) {
        case 'task_reminders':
          return true;
        case 'calendar_reminders':
          return true;
        case 'email_notifications':
          return false;
        default:
          return true;
      }
    }
  }
}

/// Bildirim gönderme provider
final notificationSenderProvider = Provider<NotificationSender>((ref) {
  return NotificationSender(
    ref.read(notificationSettingsProvider.notifier),
  );
});

/// Bildirim gönderme sınıfı (Uygulama içi)
class NotificationSender {
  final NotificationSettingsNotifier _settingsNotifier;

  NotificationSender(this._settingsNotifier);

  /// Bildirim gönder (uygulama içi overlay)
  void sendNotification({
    required String title,
    required String body,
    required app_notification.NotificationType type,
    IconData? icon,
    Color? backgroundColor,
    VoidCallback? onTap,
  }) {
    // Bildirim türüne göre ayar kontrolü (try-catch ile korunmuş)
    try {
      String settingKey;
      switch (type) {
        case app_notification.NotificationType.task:
          settingKey = 'task_reminders';
          break;
        case app_notification.NotificationType.calendar:
          settingKey = 'calendar_reminders';
          break;
        case app_notification.NotificationType.email:
          settingKey = 'email_notifications';
          break;
        case app_notification.NotificationType.system:
          // AI öngörü bildirimi kaldırıldı
          return;
      }

      // Bildirim açık mı kontrol et
      if (!_settingsNotifier.isNotificationEnabled(settingKey)) {
        debugPrint('🔕 Bildirim kapalı: $settingKey');
        return;
      }
    } catch (e) {
      // Notifier dispose olduysa bile bildirimi göster
      debugPrint('⚠️ Ayar kontrolü hatası, bildirim gösteriliyor: $e');
    }

    // Context al (global overlay context)
    BuildContext? context = _getOverlayContext();
    if (context == null) {
      debugPrint('⚠️ Context bulunamadı, bildirim gösterilemedi: $title');
      return;
    }

    // Uygulama içi bildirim göster (try-catch ile korunmuş)
    try {
      AppNotificationOverlay.show(
        context: context,
        title: title,
        message: body,
        icon: icon ?? Icons.notifications,
        backgroundColor: backgroundColor,
        onTap: onTap,
      );

      debugPrint('✅ Uygulama içi bildirim gösterildi: $title');
    } catch (e) {
      // Overlay hatası - 2 saniye sonra tekrar dene
      debugPrint('⚠️ Bildirim gösterilemedi, 2 saniye sonra tekrar denenecek: $title');

      Future.delayed(const Duration(seconds: 2), () {
        final retryContext = _getOverlayContext();
        if (retryContext != null && retryContext.mounted) {
          try {
            AppNotificationOverlay.show(
              context: retryContext,
              title: title,
              message: body,
              icon: icon ?? Icons.notifications,
              backgroundColor: backgroundColor,
              onTap: onTap,
            );
            debugPrint('✅ Bildirim gösterildi (retry başarılı): $title');
          } catch (retryError) {
            debugPrint('❌ Bildirim gösterilemedi (retry başarısız): $title');
          }
        }
      });
    }
  }

  /// Görev bildirimi gönder
  void sendTaskNotification({
    required int taskId,
    required String taskTitle,
    required String message,
    VoidCallback? onTap,
  }) {
    // Ayar kontrolü (try-catch ile korunmuş)
    try {
      if (!_settingsNotifier.isNotificationEnabled('task_reminders')) {
        debugPrint('🔕 Görev bildirimi kapalı');
        return;
      }
    } catch (e) {
      // Notifier dispose olduysa bile bildirimi göster
      debugPrint('⚠️ Ayar kontrolü hatası, bildirim gösteriliyor: $e');
    }

    // Basit servis kullan - Statik method ile direkt göster
    try {
      SimpleNotificationService.showTaskNotification(
        taskTitle: taskTitle,
        message: message,
      );
      debugPrint('✅ Görev bildirimi: $taskTitle');
    } catch (e) {
      debugPrint('❌ Görev bildirimi hatası: $taskTitle - $e');
    }
  }

  /// Takvim bildirimi gönder
  void sendCalendarNotification({
    required int eventId,
    required String eventTitle,
    required int minutesBefore,
    VoidCallback? onTap,
  }) {
    // Ayar kontrolü (try-catch ile korunmuş)
    try {
      if (!_settingsNotifier.isNotificationEnabled('calendar_reminders')) {
        debugPrint('🔕 Takvim bildirimi kapalı');
        return;
      }
    } catch (e) {
      // Notifier dispose olduysa bile bildirimi göster
      debugPrint('⚠️ Ayar kontrolü hatası, bildirim gösteriliyor: $e');
    }

    // Basit servis kullan - Statik method ile direkt göster
    try {
      final message = minutesBefore > 0 ? '$minutesBefore dakika sonra başlayacak' : 'Şimdi başlıyor';

      SimpleNotificationService.showCalendarNotification(
        eventTitle: eventTitle,
        message: message,
      );
      debugPrint('✅ Takvim bildirimi: $eventTitle');
    } catch (e) {
      debugPrint('❌ Takvim bildirimi hatası: $eventTitle - $e');
    }
  }

  /// Email bildirimi gönder
  void sendEmailNotification({
    required int emailId,
    required String subject,
    required String sender,
    VoidCallback? onTap,
  }) {
    BuildContext? context = _getOverlayContext();
    if (context == null) {
      debugPrint('⚠️ Context null, email bildirimi gösterilemedi: $subject');
      return;
    }

    // Ayar kontrolü (try-catch ile korunmuş)
    try {
      if (!_settingsNotifier.isNotificationEnabled('email_notifications')) {
        debugPrint('🔕 E-posta bildirimi kapalı');
        return;
      }
    } catch (e) {
      // Notifier dispose olduysa bile bildirimi göster
      debugPrint('⚠️ Ayar kontrolü hatası, bildirim gösteriliyor: $e');
    }

    // Overlay gösterme işlemini try-catch ile koru
    try {
      AppNotificationOverlay.showEmailNotification(
        context: context,
        subject: subject,
        sender: sender,
        onTap: onTap,
      );

      debugPrint('✅ E-posta bildirimi: $subject');
    } catch (e) {
      // Overlay hatası - 2 saniye sonra tekrar dene
      debugPrint('⚠️ Email bildirimi gösterilemedi, 2 saniye sonra tekrar denenecek: $subject');

      Future.delayed(const Duration(seconds: 2), () {
        final retryContext = _getOverlayContext();
        if (retryContext != null && retryContext.mounted) {
          try {
            AppNotificationOverlay.showEmailNotification(
              context: retryContext,
              subject: subject,
              sender: sender,
              onTap: onTap,
            );
            debugPrint('✅ Email bildirimi gösterildi (retry başarılı): $subject');
          } catch (retryError) {
            debugPrint('❌ Email bildirimi gösterilemedi (retry başarısız): $subject');
          }
        }
      });
    }
  }

  /// AI öngörü bildirimi gönder
  void sendAIInsightNotification({
    required String title,
    required String message,
    VoidCallback? onTap,
  }) {
    BuildContext? context = _getOverlayContext();
    if (context == null) {
      debugPrint('⚠️ Context null, AI bildirimi gösterilemedi: $title');
      return;
    }

    // Ayar kontrolü (try-catch ile korunmuş)
    try {
      if (!_settingsNotifier.isNotificationEnabled('ai_insights')) {
        debugPrint('🔕 AI bildirimi kapalı');
        return;
      }
    } catch (e) {
      // Notifier dispose olduysa bile bildirimi göster
      debugPrint('⚠️ Ayar kontrolü hatası, bildirim gösteriliyor: $e');
    }

    // Overlay gösterme işlemini try-catch ile koru
    try {
      AppNotificationOverlay.showAIInsight(
        context: context,
        title: title,
        message: message,
        onTap: onTap,
      );

      debugPrint('✅ AI bildirimi: $title');
    } catch (e) {
      // Overlay hatası - 2 saniye sonra tekrar dene
      debugPrint('⚠️ AI bildirimi gösterilemedi, 2 saniye sonra tekrar denenecek: $title');

      Future.delayed(const Duration(seconds: 2), () {
        final retryContext = _getOverlayContext();
        if (retryContext != null && retryContext.mounted) {
          try {
            AppNotificationOverlay.showAIInsight(
              context: retryContext,
              title: title,
              message: message,
              onTap: onTap,
            );
            debugPrint('✅ AI bildirimi gösterildi (retry başarılı): $title');
          } catch (retryError) {
            debugPrint('❌ AI bildirimi gösterilemedi (retry başarısız): $title');
          }
        }
      });
    }
  }
}
