/// Settings data - Entegrasyon ve bildirim verileri
class SettingsData {
  /// Entegrasyon kategorileri ve servisleri
  static Map<String, List<Map<String, dynamic>>> get integrations => {
        'E-posta Entegrasyonları': [
          {'name': 'Gmail', 'connected': false},
          {'name': 'Outlook', 'connected': false},
          {'name': 'Yahoo Mail', 'connected': false},
        ],
        'Takvim Entegrasyonları': [
          {'name': 'Google Calendar', 'connected': false},
          {'name': 'Outlook Calendar', 'connected': false},
        ],
        'İletişim': [
          {'name': 'WhatsApp', 'connected': false},
          {'name': 'Telegram', 'connected': false},
          {'name': 'Slack', 'connected': false},
        ],
      };

  /// Bildirim kategorileri
  static Map<String, String> get notificationCategories => {
        'Görev Bildirimi': 'Görev hatırlatıcıları ve son tarih uyarıları',
        'Toplantı Bildirimi': 'Yaklaşan toplantılar için hatırlatmalar',
        'E-posta Bildirimi': 'Önemli e-postalar için anında bildirim',
      };

  /// Bildirim başlangıç durumları
  static Map<String, bool> get defaultNotificationStates => {
        'Görev hatırlatıcıları ve son tarih uyarıları': true,
        'Yaklaşan toplantılar için hatırlatmalar': true,
        'Önemli e-postalar için anında bildirim': false,
      };

  /// Ayar kategorileri
  static List<String> get categories => [
        'Entegrasyonlar',
        'Bildirimler',
        'Görünüm',
        'Gizlilik',
      ];
}
