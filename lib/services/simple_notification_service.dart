import 'package:flutter/material.dart';
import '../core/router/app_router.dart';

/// Basit bildirim servisi - Overlay ile çalışır
class SimpleNotificationService {
  static final SimpleNotificationService _instance = SimpleNotificationService._();
  factory SimpleNotificationService() => _instance;
  SimpleNotificationService._();
  
  /// Bildirim göster (en basit hali)
  static void showNotification({
    required String title,
    required String message,
    Color backgroundColor = Colors.blue,
    IconData icon = Icons.notifications,
  }) {
    // rootNavigatorKey'den NavigatorState'i al
    final navigatorState = rootNavigatorKey.currentState;
    if (navigatorState == null) {
      debugPrint('❌ Navigator null - bildirim gösterilemedi');
      return;
    }
    
    // Navigator'un overlay'ini al
    final overlayState = navigatorState.overlay;
    if (overlayState == null) {
      debugPrint('❌ Overlay null - bildirim gösterilemedi');
      return;
    }
    
    debugPrint('🔔 Bildirim gösteriliyor: $title');
    
    // Overlay entry oluştur
    late OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 80,
        right: 20,
        child: Material(
          elevation: 10,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 350,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: backgroundColor.withOpacity(0.95),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    overlayEntry.remove();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
    
    // Overlay'e ekle
    overlayState.insert(overlayEntry);
    
    // 5 saniye sonra otomatik kaldır
    Future.delayed(const Duration(seconds: 5), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
    
    debugPrint('✅ Bildirim gösterildi: $title');
  }
  
  /// Görev bildirimi
  static void showTaskNotification({
    required String taskTitle,
    required String message,
  }) {
    showNotification(
      title: '⏰ Görev Hatırlatıcısı',
      message: '$taskTitle - $message',
      backgroundColor: Colors.orange,
      icon: Icons.task_alt,
    );
  }

  /// E-posta bildirimi
  static void showEmailNotification({
    required String subject,
    required String sender,
    int? emailCount,
  }) {
    // emailCount yeni gelen email sayısıdır (toplam değil)
    final message = emailCount != null && emailCount > 1
        ? '$emailCount yeni e-posta geldi'
        : emailCount != null && emailCount == 1
            ? '1 yeni e-posta geldi'
            : '$sender\'dan yeni e-posta';
    
    showNotification(
      title: '📧 Yeni E-posta',
      message: message,
      backgroundColor: Colors.blue,
      icon: Icons.email,
    );
  }

  /// Takvim bildirimi
  static void showCalendarNotification({
    required String eventTitle,
    required String message,
  }) {
    showNotification(
      title: '📅 Yaklaşan Toplantı',
      message: '$eventTitle - $message',
      backgroundColor: Colors.purple,
      icon: Icons.event,
    );
  }
}

