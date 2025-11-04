/// Integrations data - Detaylı entegrasyon verileri
class IntegrationsData {
  /// Tüm entegrasyon kategorileri
  static Map<String, List<Map<String, dynamic>>> get allIntegrations => {
        'E-posta Entegrasyonları': [
          {'name': 'Gmail', 'icon': 'assets/icons/gmail.png', 'connected': false},
          {'name': 'Outlook', 'icon': 'assets/icons/outlook.png', 'connected': false},
          {'name': 'Yahoo Mail', 'icon': 'assets/icons/yahoo.png', 'connected': false},
        ],
        'Takvim Entegrasyonları': [
          {'name': 'Google Calendar', 'icon': 'assets/icons/google_calendar.png', 'connected': true},
          {'name': 'Outlook Calendar', 'icon': 'assets/icons/outlook_calendar.png', 'connected': false},
        ],
        'Proje Yönetimi': [
          {'name': 'Trello', 'icon': 'assets/icons/trello.png', 'connected': false},
          {'name': 'Asana', 'icon': 'assets/icons/asana.png', 'connected': false},
          {'name': 'Jira', 'icon': 'assets/icons/jira.png', 'connected': false},
        ],
        'Depolama': [
          {'name': 'Google Drive', 'icon': 'assets/icons/google_drive.png', 'connected': false},
          {'name': 'Dropbox', 'icon': 'assets/icons/dropbox.png', 'connected': false},
          {'name': 'OneDrive', 'icon': 'assets/icons/onedrive.png', 'connected': false},
        ],
      };
}

