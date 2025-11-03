/// AI yanıtları ve öneriler - Mock data
class AIResponses {
  /// Önerilmiş sorular
  static const List<String> suggestions = [
    'Bugünkü görevlerim neler?',
    'Yaklaşan toplantılarım',
    'E-postalarımı özetle',
    'Haftalık özet al',
  ];

  /// Kullanıcı mesajına göre AI yanıtı üret
  static String generateResponse(String userMessage) {
    final lowerMessage = userMessage.toLowerCase();

    if (lowerMessage.contains('görev')) {
      return 'Bugün tamamlamanız gereken 5 görev bulunuyor. En önemlisi "Proje sunumu hazırlama" görevi. Detayları görmek ister misiniz?';
    } else if (lowerMessage.contains('toplantı')) {
      return 'Bu hafta 3 toplantınız var. Bugün saat 14:00\'ta "Takım Değerlendirmesi" toplantısı bulunuyor. Hatırlatıcı ayarlamak ister misiniz?';
    } else if (lowerMessage.contains('e-posta')) {
      return 'Son 24 saatte 15 yeni e-postanız var. Bunlardan 5\'i önemli olarak işaretlenmiş. Önemli e-postaları listelemek ister misiniz?';
    } else if (lowerMessage.contains('özet')) {
      return '''Bu haftaki performansınız:

✅ 12 görev tamamlandı
📅 5 toplantı yapıldı
✉️ 25 e-posta işlendi
🎯 %85 başarı oranı

Harika gidiyorsunuz!''';
    } else if (lowerMessage.contains('merhaba') || lowerMessage.contains('selam')) {
      return 'Merhaba! Size nasıl yardımcı olabilirim? Görevlerinizi yönetebilir, takvim planlaması yapabilir veya e-postalarınızı özetleyebilirim.';
    } else if (lowerMessage.contains('teşekkür')) {
      return 'Rica ederim! Başka bir konuda yardımcı olabilirsem söyleyin. 😊';
    } else {
      return 'Anladım! Bu konuda size nasıl yardımcı olabilirim? Görevlerinizi kontrol edebilir, takviminizi düzenleyebilir veya e-postalarınızı özetleyebilirim.';
    }
  }

  /// Hoş geldiniz mesajı
  static const String welcomeTitle = 'AI Asistanınıza Hoş Geldiniz!';
  static const String welcomeSubtitle =
      'Görevleriniz, takviminiz ve daha fazlası için size yardımcı olabilirim.';

  /// Placeholder mesajlar
  static const String inputPlaceholder = 'Mesajınızı yazın...';
  static const String emptyStateMessage = 'Henüz mesaj yok. Bir şeyler sorun!';
}

