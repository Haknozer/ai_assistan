import 'package:ai_asisstan/models/email.dart';

/// Mock e-posta verileri - Test ve geliştirme için
class MockEmails {
  static final List<Email> emails = [
    Email(
      id: 1,
      userId: 1,
      accountId: 1,
      subject: 'Proje Güncellemesi - Önemli',
      fromEmail: 'ahmet.yilmaz@work.com',
      fromName: 'Ahmet Yılmaz',
      toEmails: ['ben@work.com'],
      plainText: '''Merhaba,

Projenin son durumu hakkında bilgi almak istiyorum. Özellikle yeni özellikler ve timeline konusunda görüşmek isterdim.

Yeni özellikler için belirlediğimiz roadmap'e göre ilerleme kaydettik. Ancak bazı teknik zorluklar nedeniyle timeline'da küçük kaymalar olabilir.

Detaylı bilgi için toplantı ayarlayabilir miyiz?

Teşekkürler,
Ahmet''',
      status: EmailStatus.unread,
      importance: EmailImportance.important,
      isRead: false,
      receivedDate: DateTime.now().subtract(const Duration(minutes: 10)),
      attachments: [
        EmailAttachment(
          emailId: 1,
          filename: 'proje_raporu.pdf',
          contentType: 'application/pdf',
          sizeBytes: 1024 * 500, // 500 KB
          createdAt: DateTime.now(),
        ),
        EmailAttachment(
          emailId: 1,
          filename: 'timeline.xlsx',
          contentType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          sizeBytes: 1024 * 200, // 200 KB
          createdAt: DateTime.now(),
        ),
      ],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Email(
      id: 2,
      userId: 1,
      accountId: 1,
      subject: 'Bug Raporu - Acil',
      fromEmail: 'mehmet.demir@techcorp.com',
      fromName: 'Mehmet Demir',
      toEmails: ['ben@work.com'],
      plainText: '''Merhaba,

Kullanıcı arayüzünde kritik bir sorun tespit ettim, inceleyebilir misin?

Login ekranında kullanıcı adı ve şifre alanları arasındaki geçiş düzgün çalışmıyor. Tab tuşu ile geçiş yapıldığında focus kaybolduğu durumlar oluyor.

Ayrıca hata mesajları bazı durumlarda ekranın dışına taşıyor.

Bu konuyu öncelikli olarak ele alabilir miyiz? Kullanıcılar şikayet etmeye başladı.

Saygılarımla,
Mehmet''',
      status: EmailStatus.unread,
      importance: EmailImportance.important,
      isRead: false,
      receivedDate: DateTime.now().subtract(const Duration(minutes: 25)),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Email(
      id: 3,
      userId: 1,
      accountId: 2,
      subject: 'Yeni iş teklifi: Senior Flutter Developer',
      fromEmail: 'notifications@linkedin.com',
      fromName: 'LinkedIn',
      toEmails: ['ben@personal.com'],
      plainText: '''Merhaba,

Profilinizle eşleşen yeni bir iş ilanı mevcut:

Senior Flutter Developer
TechCorp İstanbul
Full-time, Remote seçeneği

Başvuru için: https://linkedin.com/jobs/view/12345

İyi şanslar!''',
      status: EmailStatus.read,
      importance: EmailImportance.normal,
      isRead: true,
      receivedDate: DateTime.now().subtract(const Duration(hours: 1)),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Email(
      id: 4,
      userId: 1,
      accountId: 2,
      subject: 'Tebrikler! 1.000.000\$ kazandınız!',
      fromEmail: 'winner@fake-lottery.com',
      fromName: 'Spam Bot',
      toEmails: ['ben@personal.com'],
      plainText: '''Tebrikler!!!

1.000.000\$ ikramiye kazandınız. Bu fırsatı kaçırmayın.

Hemen tıklayın: http://fake-lottery.com/claim-prize

Bu e-posta otomatik olarak gönderilmiştir.''',
      status: EmailStatus.received,
      importance: EmailImportance.normal,
      isRead: false,
      isSpam: true,
      receivedDate: DateTime.now().subtract(const Duration(hours: 2)),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Email(
      id: 5,
      userId: 1,
      accountId: 1,
      subject: 'Toplantı Daveti - Sprint Planning',
      fromEmail: 'ayse.kaya@work.com',
      fromName: 'Ayşe Kaya',
      toEmails: ['ben@work.com'],
      plainText: '''Merhaba Ekip,

Yarın saat 14:00'te sprint planlama toplantısı var.

Lütfen hazırlıklarınızı tamamlayın ve toplantıya katılın. Sprint review sonuçlarını ve yeni dönem için planları görüşeceğiz.

Toplantı Odası: A-201
Süre: 2 saat
Ajanda:
- Sprint review
- Retrospective
- Yeni sprint planning

Görüşmek üzere!
Ayşe''',
      status: EmailStatus.read,
      importance: EmailImportance.normal,
      isRead: true,
      receivedDate: DateTime.now().subtract(const Duration(hours: 3)),
      attachments: [
        EmailAttachment(
          emailId: 5,
          filename: 'sprint_review.pdf',
          contentType: 'application/pdf',
          sizeBytes: 1024 * 300, // 300 KB
          createdAt: DateTime.now(),
        ),
      ],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Email(
      id: 6,
      userId: 1,
      accountId: 2,
      subject: 'Güvenlik uyarısı',
      fromEmail: 'security-noreply@accounts.google.com',
      fromName: 'Google',
      toEmails: ['ben@personal.com'],
      plainText: '''Google Hesap Güvenlik Uyarısı

Yeni bir cihazdan hesabınıza erişim denendi:
- Cihaz: Windows PC
- Konum: İstanbul, Türkiye
- Tarayıcı: Chrome
- Zaman: 01/11/2025 08:30

Bu siz değilseniz, lütfen şifrenizi değiştirin ve güvenlik ayarlarınızı kontrol edin.

Hesap güvenliği: https://myaccount.google.com/security''',
      status: EmailStatus.unread,
      importance: EmailImportance.important,
      isRead: false,
      receivedDate: DateTime.now().subtract(const Duration(hours: 4)),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Email(
      id: 7,
      userId: 1,
      accountId: 1,
      subject: 'Gönderildi: Taslak Rapor',
      fromEmail: 'ben@work.com',
      fromName: 'Ben',
      toEmails: ['manager@work.com'],
      plainText: '''Merhaba,

Hazırlamış olduğum aylık raporu ekte gönderiyorum. Kontrol edip geri bildirimde bulunursanız sevinirim.

Özellikle performans metrikleri bölümünü dikkatlice incelemeniz rica olunur.

Saygılarımla, Ben''',
      status: EmailStatus.sent,
      importance: EmailImportance.normal,
      isRead: true,
      sentDate: DateTime.now().subtract(const Duration(hours: 5)),
      attachments: [
        EmailAttachment(
          emailId: 7,
          filename: 'aylik_rapor.pdf',
          contentType: 'application/pdf',
          sizeBytes: 1024 * 800, // 800 KB
          createdAt: DateTime.now(),
        ),
      ],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Email(
      id: 8,
      userId: 1,
      accountId: 1,
      subject: 'Taslak: Proje Teklifi',
      fromEmail: 'ben@work.com',
      fromName: 'Ben',
      toEmails: [],
      plainText: '''Müşteri Proje Teklifi (TASLAK)

Proje Adı: Mobil Uygulama Geliştirme
Müşteri: ABC Corp
Bütçe: -
Timeline: -

NOT: Bu bir taslaktır, gönderilmemiştir.''',
      status: EmailStatus.draft,
      importance: EmailImportance.normal,
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      updatedAt: DateTime.now(),
    ),
    Email(
      id: 9,
      userId: 1,
      accountId: 2,
      subject: 'Hafta sonu planı',
      fromEmail: 'fatma.oz@personal.com',
      fromName: 'Fatma Öz',
      toEmails: ['ben@personal.com'],
      plainText: '''Merhaba!

Bu hafta sonu kahve içmeye ne dersin? Uzun zaman oldu görüşmeyeli.

Cumartesi veya pazar günü uygun musun?

Kafalar:
- Kadıköy: Kahve Dünyası
- Beşiktaş: Minoa
- Karaköy: Kronotrop

Seçtiğim yerlerden birine gelmek istersen haber ver.

Sevgiler,
Fatma''',
      status: EmailStatus.read,
      importance: EmailImportance.normal,
      isRead: true,
      receivedDate: DateTime.now().subtract(const Duration(days: 1)),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Email(
      id: 10,
      userId: 1,
      accountId: 2,
      subject: 'Hesap ekstresi - Ekim 2025',
      fromEmail: 'info@bank.com',
      fromName: 'Banka',
      toEmails: ['ben@personal.com'],
      plainText: '''Değerli Müşterimiz,

Ekim 2025 hesap ekstreniz hazır.

Detaylar için internet bankacılığını kullanabilir veya mobil uygulamamızı indirebilirsiniz.

Banka Mobil Uygulaması
- Hızlı ve güvenli
- 7/24 erişim
- Detaylı işlemler

İyi günler dileriz.''',
      status: EmailStatus.read,
      importance: EmailImportance.normal,
      isRead: true,
      receivedDate: DateTime.now().subtract(const Duration(days: 2)),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  /// Okunmamış e-posta sayısı
  static int get unreadCount => emails.where((email) => email.isUnread).length;

  /// Önemli e-posta sayısı
  static int get importantCount => emails.where((email) => email.importance == EmailImportance.important).length;

  /// İş e-postaları sayısı
  static int get workEmailsCount => emails.where((email) => email.accountId == 1).length;

  /// Spam e-posta sayısı
  static int get spamCount => emails.where((email) => email.isSpam).length;
}
