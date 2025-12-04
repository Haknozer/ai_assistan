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
      return 'Merhaba! Size nasıl yardımcı olabilirim? Görevleriniz, toplantılarınız veya e-postalarınız hakkında bilgi almak ister misiniz?';
    } else if (lowerMessage.contains('teşekkür') || lowerMessage.contains('sağ ol')) {
      return 'Rica ederim! Başka bir konuda yardımcı olabilir miyim?';
    } else {
      return 'Anladım. Size daha iyi yardımcı olabilmem için görevler, toplantılar veya e-postalar hakkında soru sorabilirsiniz.';
    }
  }

  /// Hoş geldiniz başlığı
  static const String welcomeTitle = 'AI Asistanınıza Hoş Geldiniz';

  /// Hoş geldiniz alt başlığı
  static const String welcomeSubtitle = 'Görevleriniz, toplantılarınız ve e-postalarınız hakkında sorular sorabilirsiniz.';

  /// Input placeholder
  static const String inputPlaceholder = 'Mesaj yazın...';
}

