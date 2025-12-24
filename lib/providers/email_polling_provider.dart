import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_asisstan/services/backend_email_service.dart';
import 'package:ai_asisstan/core/utils/logger.dart';
import 'package:ai_asisstan/services/simple_notification_service.dart';
import 'package:ai_asisstan/providers/notification_provider.dart';

/// Email polling state
class EmailPollingState {
  final bool isPolling;
  final bool hasNewEmails;
  final int newEmailCount; // Son bildirimde gösterilen yeni email sayısı
  final int totalEmailCount; // Toplam email sayısı (karşılaştırma için)
  final DateTime? lastCheck;
  final DateTime? lastEmailTimestamp;

  const EmailPollingState({
    this.isPolling = false,
    this.hasNewEmails = false,
    this.newEmailCount = 0,
    this.totalEmailCount = 0,
    this.lastCheck,
    this.lastEmailTimestamp,
  });

  EmailPollingState copyWith({
    bool? isPolling,
    bool? hasNewEmails,
    int? newEmailCount,
    int? totalEmailCount,
    DateTime? lastCheck,
    DateTime? lastEmailTimestamp,
  }) {
    return EmailPollingState(
      isPolling: isPolling ?? this.isPolling,
      hasNewEmails: hasNewEmails ?? this.hasNewEmails,
      newEmailCount: newEmailCount ?? this.newEmailCount,
      totalEmailCount: totalEmailCount ?? this.totalEmailCount,
      lastCheck: lastCheck ?? this.lastCheck,
      lastEmailTimestamp: lastEmailTimestamp ?? this.lastEmailTimestamp,
    );
  }
}

/// Email polling notifier - Akıllı polling ile yeni email'leri kontrol eder
class EmailPollingNotifier extends StateNotifier<EmailPollingState> {
  final BackendEmailService _emailService;
  final Ref? _ref;
  Timer? _pollingTimer;
  
  // Polling ayarları
  static const Duration _normalInterval = Duration(seconds: 30); // Normal: 30 saniye
  static const Duration _activeInterval = Duration(seconds: 10); // Aktif kullanım: 10 saniye
  static const Duration _inactiveInterval = Duration(minutes: 2); // İnaktif: 2 dakika
  
  Duration _currentInterval = _normalInterval;
  bool _isActive = true;

  EmailPollingNotifier(this._emailService, [this._ref]) : super(const EmailPollingState()) {
    _startPolling();
  }

  /// Polling'i başlat
  void _startPolling() {
    if (_pollingTimer != null) return;
    
    AppLogger.info('📡 Email polling başlatıldı (${_currentInterval.inSeconds}s interval)', 'EmailPolling');
    
    // İlk kontrolü hemen yap
    _checkNewEmails();
    
    // Sonra periyodik kontrol
    _pollingTimer = Timer.periodic(_currentInterval, (_) {
      _checkNewEmails();
    });
    
    state = state.copyWith(isPolling: true);
  }

  /// Polling'i durdur
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    state = state.copyWith(isPolling: false);
    AppLogger.info('⏸️ Email polling durduruldu', 'EmailPolling');
  }

  /// Polling'i yeniden başlat (interval değişti)
  void _restartPolling() {
    stopPolling();
    _startPolling();
  }

  /// Kullanıcı aktif (UI'da email ekranındaysa bu çağrılır)
  void setActive() {
    if (_isActive) return;
    _isActive = true;
    _currentInterval = _activeInterval;
    AppLogger.info('🟢 Kullanıcı aktif - polling hızlandırıldı (${_currentInterval.inSeconds}s)', 'EmailPolling');
    _restartPolling();
  }

  /// Kullanıcı inaktif (başka ekranda)
  void setInactive() {
    if (!_isActive) return;
    _isActive = false;
    _currentInterval = _inactiveInterval;
    AppLogger.info('🟡 Kullanıcı inaktif - polling yavaşlatıldı (${_currentInterval.inSeconds}s)', 'EmailPolling');
    _restartPolling();
  }

  /// Manuel kontrol (kullanıcı refresh butonuna bastığında)
  Future<void> checkNow() async {
    AppLogger.info('🔄 Manuel email kontrolü başlatıldı', 'EmailPolling');
    await _checkNewEmails();
  }

  /// Yeni email'leri kontrol et
  Future<void> _checkNewEmails() async {
    try {
      final result = await _emailService.checkNewEmails(
        lastCheck: state.lastCheck,
      );
      
      final newCount = result['new_count'] as int? ?? 0;
      final totalCount = result['total_count'] as int? ?? 0;
      final lastEmailTimestampStr = result['last_email_timestamp'] as String?;
      
      DateTime? lastEmailTimestamp;
      if (lastEmailTimestampStr != null) {
        try {
          lastEmailTimestamp = DateTime.parse(lastEmailTimestampStr);
        } catch (e) {
          AppLogger.error('Timestamp parse hatası', tag: 'EmailPolling', error: e);
        }
      }
      
      // Önceki state'i al
      final oldHasNewEmails = state.hasNewEmails;
      final oldLastCheck = state.lastCheck;
      final oldTotalCount = state.totalEmailCount; // Önceki toplam sayı
      final isFirstCheck = oldLastCheck == null; // İlk kontrol mü?
      
      // Gerçek yeni email sayısını hesapla
      // Eğer ilk kontrol değilse ve önceki toplam sayı varsa, farkı al
      int actualNewCount = 0;
      if (!isFirstCheck && oldTotalCount > 0 && totalCount > oldTotalCount) {
        // Önceki toplam sayıdan yeni toplam sayıya kadar olan fark = yeni email sayısı
        actualNewCount = totalCount - oldTotalCount;
        AppLogger.debug('📊 Email sayısı: Önceki=$oldTotalCount, Şimdi=$totalCount, Yeni=$actualNewCount', 'EmailPolling');
      } else if (!isFirstCheck && newCount > 0 && oldTotalCount == 0) {
        // Eğer önceki toplam sayı kaydedilmemişse backend'den gelen new_count'u kullan
        actualNewCount = newCount;
        AppLogger.debug('📊 Backend new_count kullanılıyor: $actualNewCount', 'EmailPolling');
      } else if (isFirstCheck) {
        // İlk kontrol - bildirim gönderme
        actualNewCount = 0;
      }
      
      // State güncelle
      state = state.copyWith(
        hasNewEmails: actualNewCount > 0, // Sadece gerçekten yeni email varsa true
        newEmailCount: actualNewCount, // Yeni email sayısı
        totalEmailCount: totalCount, // Toplam sayıyı sakla (sonraki karşılaştırma için)
        lastCheck: DateTime.now(),
        lastEmailTimestamp: lastEmailTimestamp,
      );
      
      // Yeni email geldi mi kontrol et
      // Sadece gerçekten yeni email geldiğinde ve daha önce bildirim gönderilmediyse bildirim gönder
      if (!isFirstCheck && actualNewCount > 0 && !oldHasNewEmails) {
        AppLogger.info('📬 $actualNewCount yeni email bulundu! (Toplam: $totalCount)', 'EmailPolling');
        
        // Bildirim gönder (ayarları kontrol ederek)
        try {
          if (_ref != null) {
            final notificationSettings = _ref!.read(notificationSettingsProvider);
            final emailNotificationsEnabled = notificationSettings['email_notifications'] ?? false;
            
            if (emailNotificationsEnabled) {
              SimpleNotificationService.showEmailNotification(
                subject: 'Yeni E-posta',
                sender: 'Gelen Kutusu',
                emailCount: actualNewCount, // Gerçek yeni email sayısı
              );
              AppLogger.info('✅ E-posta bildirimi gönderildi ($actualNewCount yeni email)', 'EmailPolling');
            } else {
              AppLogger.info('🔕 E-posta bildirimleri kapalı, bildirim gönderilmedi', 'EmailPolling');
            }
          } else {
            // Ref yoksa direkt gönder (fallback)
            SimpleNotificationService.showEmailNotification(
              subject: 'Yeni E-posta',
              sender: 'Gelen Kutusu',
              emailCount: actualNewCount, // Gerçek yeni email sayısı
            );
          }
        } catch (e) {
          AppLogger.error('E-posta bildirimi gönderilemedi', tag: 'EmailPolling', error: e);
        }
      } else if (isFirstCheck) {
        AppLogger.info('📧 İlk email kontrolü yapıldı, bildirim gönderilmedi (toplam: $totalCount email)', 'EmailPolling');
      } else if (actualNewCount == 0) {
        AppLogger.debug('📧 Yeni email yok (toplam: $totalCount, önceki: $oldTotalCount)', 'EmailPolling');
      }
      
    } catch (e) {
      AppLogger.error('Email kontrol hatası', tag: 'EmailPolling', error: e);
      // Hata durumunda sessizce devam et (polling kesintiye uğramasın)
    }
  }

  /// Yeni email'ler okundu (UI'da görüntülendi)
  void markAsRead() {
    state = state.copyWith(
      hasNewEmails: false,
      newEmailCount: 0,
      // totalEmailCount'u sıfırlama - sonraki karşılaştırma için gerekli
    );
    AppLogger.info('✅ Yeni email\'ler okundu olarak işaretlendi', 'EmailPolling');
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}

/// Email polling provider
final emailPollingProvider = StateNotifierProvider<EmailPollingNotifier, EmailPollingState>((ref) {
  final emailService = BackendEmailService();
  return EmailPollingNotifier(emailService, ref);
});

