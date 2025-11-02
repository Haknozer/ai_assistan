import 'package:flutter/material.dart';
import '../models/message_model.dart';

/// Mock mesaj verileri - Test ve geliştirme için
class MockMessages {
  static final List<MessageModel> messages = [
    const MessageModel(
      platform: 'Email',
      sender: 'Ahmet Yılmaz',
      subject: 'Proje Güncellemesi',
      preview:
          'Merhaba, projenin son durumu hakkında bilgi almak istiyorum. Özellikle yeni özellikler ve timeline konusunda görüşmek isterdim.',
      content:
          'Merhaba,\n\nProjenin son durumu hakkında bilgi almak istiyorum. Özellikle yeni özellikler ve timeline konusunda görüşmek isterdim.\n\nYeni özellikler için belirlediğimiz roadmap\'e göre ilerleme kaydettik. Ancak bazı teknik zorluklar nedeniyle timeline\'da küçük kaymalar olabilir.\n\nDetaylı bilgi için toplantı ayarlayabilir miyiz?\n\nTeşekkürler,\nAhmet',
      time: '10 dk önce',
      date: '1 Kasım 2025, 09:30',
      isUnread: true,
      icon: Icons.email,
      color: Colors.red,
    ),
    const MessageModel(
      platform: 'Slack',
      sender: 'Mehmet Demir',
      subject: 'Bug Raporu',
      preview:
          'Kullanıcı arayüzünde bir sorun tespit ettim, inceleyebilir misin? Login ekranında bir problem var gibi görünüyor.',
      content:
          'Kullanıcı arayüzünde bir sorun tespit ettim, inceleyebilir misin?\n\nLogin ekranında kullanıcı adı ve şifre alanları arasındaki geçiş düzgün çalışmıyor. Tab tuşu ile geçiş yapıldığında focus kaybolduğu durumlar oluyor.\n\nAyrıca hata mesajları bazı durumlarda ekranın dışına taşıyor.\n\nBu konuyu öncelikli olarak ele alabilir miyiz?',
      time: '25 dk önce',
      date: '1 Kasım 2025, 09:05',
      isUnread: true,
      icon: Icons.chat_bubble,
      color: Colors.purple,
    ),
    const MessageModel(
      platform: 'Teams',
      sender: 'Ayşe Kaya',
      subject: 'Toplantı Daveti',
      preview:
          'Yarın saat 14:00\'te sprint planlama toplantısı var. Lütfen hazırlıklarını tamamla ve toplantıya katıl.',
      content:
          'Yarın saat 14:00\'te sprint planlama toplantısı var.\n\nLütfen hazırlıklarını tamamla ve toplantıya katıl. Sprint review sonuçlarını ve yeni dönem için planları görüşeceğiz.\n\nToplantı Odası: A-201\nSüre: 2 saat\n\nGörüşmek üzere!',
      time: '1 saat önce',
      date: '1 Kasım 2025, 08:30',
      isUnread: false,
      icon: Icons.groups,
      color: Colors.blue,
    ),
    const MessageModel(
      platform: 'WhatsApp',
      sender: 'Fatma Öz',
      subject: 'Müşteri Geri Bildirimi',
      preview:
          'Müşteriden yeni bir geri bildirim geldi, inceleyelim mi? Pozitif görünüyor ama birkaç iyileştirme önerisi var.',
      content:
          'Müşteriden yeni bir geri bildirim geldi, inceleyelim mi?\n\nGenel olarak pozitif görünüyor ama birkaç iyileştirme önerisi var:\n\n1. Kullanıcı arayüzü daha sezgisel olmalı\n2. Raporlama özellikleri genişletilmeli\n3. Mobil uygulama performansı iyileştirilmeli\n\nDetaylı raporu ekte bulabilirsin.',
      time: '2 saat önce',
      date: '1 Kasım 2025, 07:45',
      isUnread: true,
      icon: Icons.message,
      color: Colors.green,
    ),
    const MessageModel(
      platform: 'Email',
      sender: 'Can Öztürk',
      subject: 'Yeni Özellik Talebi',
      preview:
          'Kullanıcılarımızdan gelen talepleri değerlendirdim. Öncelikli olarak dark mode ve bildirim sistemi üzerinde çalışmalıyız.',
      content:
          'Kullanıcılarımızdan gelen talepleri değerlendirdim.\n\nÖncelikli olarak dark mode ve bildirim sistemi üzerinde çalışmalıyız. Kullanıcı geri bildirimleri bu iki özelliğin en çok talep edilenler olduğunu gösteriyor.\n\nBir değerlendirme toplantısı yapalım mı?',
      time: '3 saat önce',
      date: '1 Kasım 2025, 06:20',
      isUnread: false,
      icon: Icons.email,
      color: Colors.red,
    ),
    const MessageModel(
      platform: 'Slack',
      sender: 'Design Team',
      subject: 'UI/UX İncelemeleri',
      preview:
          'Yeni tasarımlar hazır, review için bekliyor. Figma linkini ekledim, bir göz atabilir misin?',
      content:
          'Yeni tasarımlar hazır, review için bekliyor.\n\nFigma linkini ekledim, bir göz atabilir misin?\n\nhttps://figma.com/...\n\nGeri bildirimlerini en kısa sürede alabilirsek çok seviniriz.',
      time: '4 saat önce',
      date: '1 Kasım 2025, 05:15',
      isUnread: false,
      icon: Icons.chat_bubble,
      color: Colors.purple,
    ),
    const MessageModel(
      platform: 'Teams',
      sender: 'Proje Yöneticisi',
      subject: 'Sprint Raporu',
      preview:
          'Bu haftaki sprint sonuçları oldukça başarılı. Tüm hedeflerimizi tamamladık ve birkaç bonus özellik de ekledik.',
      content:
          'Bu haftaki sprint sonuçları oldukça başarılı.\n\nTüm hedeflerimizi tamamladık ve birkaç bonus özellik de ekledik. Takımın performansı harika!\n\nDetaylı rapor için dashboard\'u kontrol edebilirsiniz.',
      time: '5 saat önce',
      date: '1 Kasım 2025, 04:00',
      isUnread: true,
      icon: Icons.groups,
      color: Colors.blue,
    ),
    const MessageModel(
      platform: 'WhatsApp',
      sender: 'Müşteri Temsilcisi',
      subject: 'Destek Talebi',
      preview:
          'Yeni bir müşterimiz var ve ürün demosu talep ediyor. Bu hafta uygun bir gününüz var mı?',
      content:
          'Yeni bir müşterimiz var ve ürün demosu talep ediyor.\n\nBu hafta uygun bir gününüz var mı? Müşteri teknoloji sektöründen ve projemize çok ilgili.\n\nZamanınızı ayırabilirseniz harika olur!',
      time: '6 saat önce',
      date: '1 Kasım 2025, 03:30',
      isUnread: true,
      icon: Icons.message,
      color: Colors.green,
    ),
    const MessageModel(
      platform: 'Email',
      sender: 'Ali Yıldız',
      subject: 'Haftalık Rapor',
      preview: 'Bu haftaki performans raporunu ekteki dosyada bulabilirsiniz.',
      content:
          'Bu haftaki performans raporunu ekteki dosyada bulabilirsiniz.\n\nGenel olarak hedeflerimize ulaştık. Birkaç küçük gecikme dışında her şey yolunda.\n\nSorularınız varsa lütfen bana ulaşın.',
      time: '7 saat önce',
      date: '1 Kasım 2025, 02:15',
      isUnread: false,
      icon: Icons.email,
      color: Colors.red,
    ),
    const MessageModel(
      platform: 'Slack',
      sender: 'Backend Team',
      subject: 'API Güncellemesi',
      preview: 'Yeni API endpoint hazır, dokümantasyonu gönderiyorum.',
      content:
          'Yeni API endpoint hazır, dokümantasyonu gönderiyorum.\n\n/api/v2/users - Kullanıcı yönetimi için yeni endpoint\n/api/v2/reports - Raporlama için yeni endpoint\n\nDokümantasyon linki README dosyasında.',
      time: '8 saat önce',
      date: '1 Kasım 2025, 01:00',
      isUnread: false,
      icon: Icons.chat_bubble,
      color: Colors.purple,
    ),
    const MessageModel(
      platform: 'Teams',
      sender: 'Zeynep Kara',
      subject: 'Proje Değerlendirmesi',
      preview:
          'Projenin genel durumu hakkında değerlendirme yapmamız gerekiyor.',
      content:
          'Projenin genel durumu hakkında değerlendirme yapmamız gerekiyor.\n\nBu hafta içinde bir toplantı ayarlayalım mı?\n\nProje hedeflerini ve zaman çizelgesini gözden geçirmemiz önemli.',
      time: '9 saat önce',
      date: '31 Ekim 2025, 23:45',
      isUnread: false,
      icon: Icons.groups,
      color: Colors.blue,
    ),
  ];

  /// Okunmamış mesaj sayısı
  static int get unreadCount =>
      messages.where((message) => message.isUnread).length;
}

