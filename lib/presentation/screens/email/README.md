# Email Screen Modülü

E-posta yönetimi ekranı - Tüm e-postalarınızı tek bir yerden yönetin.

## 📂 Klasör Yapısı

```
email/
├── email_screen.dart          # Ana e-posta ekranı
├── data/
│   └── mock_emails.dart       # Mock e-posta verileri
└── utils/
    └── email_utils.dart       # E-posta yardımcı fonksiyonları
```

## 🎨 Widget Yapısı

### Widgets (lib/presentation/widgets/email/)
- `email_page_header.dart` - Sayfa başlığı ve istatistikler
- `search_and_filter_bar.dart` - Arama ve yeni e-posta butonu
- `email_filter_section.dart` - E-posta filtreleri (Tümü, Okunmamış, Önemli, vb.)
- `email_list.dart` - E-posta listesi
- `email_detail_panel.dart` - Seçili e-posta detayı
- `compose_email_dialog.dart` - E-posta oluşturma dialog'u

## 🔧 Utilities

### EmailUtils
- `getImportanceColor()` - Önem derecesi rengi
- `getImportanceIcon()` - Önem derecesi ikonu
- `getStatusColor()` - E-posta durumu rengi
- `getStatusIcon()` - E-posta durumu ikonu
- `formatDateTime()` - Tarih formatla
- `extractNameFromEmail()` - E-posta adresinden isim çıkar
- `formatSize()` - Dosya boyutu formatla
- `isValidEmail()` - E-posta adresi doğrula
- `getInitials()` - Baş harfleri al (avatar için)
- `formatEmailCount()` - E-posta sayısı formatla

## 📊 Özellikler

### E-posta Yönetimi
- ✅ E-posta listesi görüntüleme
- ✅ E-posta detayı görüntüleme
- ✅ E-posta arama
- ✅ E-posta filtreleme (Tümü, Okunmamış, Önemli, İş, Spam, Gönderilen, Taslak)
- ✅ E-posta okundu işaretleme
- ✅ E-posta önemli işaretleme
- ✅ E-posta silme
- ✅ Yeni e-posta oluşturma
- ✅ E-posta yanıtlama
- ✅ E-posta yönlendirme

### Responsive Tasarım
- **Desktop**: Sol menü + iki panelli görünüm (liste + detay)
- **Mobile**: Drawer menü + liste görünümü

### Dialog'lar
- **Compose Email Dialog**: Yeni e-posta oluşturma/yanıtlama
  - Alıcı validasyonu
  - Konu ve içerik girişi
  - Önem derecesi seçimi
  - Taslak kaydetme (TODO)
  - E-posta gönderme

## 🎯 Ana Fonksiyonlar

### EmailScreen
- `_filteredEmails` - Filtrelenmiş e-posta listesi
- `_selectedEmail` - Seçili e-posta
- `_markAsRead()` - E-postayı okundu işaretle
- `_markAsImportant()` - E-postayı önemli işaretle
- `_deleteEmail()` - E-postayı sil
- `_replyToEmail()` - E-postaya yanıt ver
- `_forwardEmail()` - E-postayı yönlendir
- `_showComposeEmailDialog()` - E-posta oluşturma dialog'unu göster

## 🔄 State Yönetimi

- `_selectedFilter` - Seçili filtre (Tümü, Okunmamış, vb.)
- `_selectedEmailIndex` - Seçili e-posta indeksi
- `_searchQuery` - Arama sorgusu
- `_emails` - E-posta listesi

## 📱 Responsive Davranış

### Desktop (> 900px)
- Sol menü sabit
- İki panelli layout (4:6 oranında)
- E-posta detayı sağ panelde

### Mobile (< 900px)
- Drawer menü
- Tek panel layout
- E-posta detayı ayrı ekranda (TODO)

## 🎨 Tema ve Renkler

- **Primary**: Mavi (#2196F3)
- **Success**: Yeşil - Gönderilen e-postalar
- **Warning**: Turuncu - Taslak e-postalar
- **Error**: Kırmızı - Önemli e-postalar
- **Grey**: Gri - Normal/okunmuş e-postalar

## 📝 Gelecek Geliştirmeler (TODO)

- [ ] E-posta hesap yönetimi (Google, Outlook, Apple)
- [ ] E-posta kategorileri/etiketler
- [ ] E-posta ekleri
- [ ] E-posta şablonları
- [ ] Toplu e-posta işlemleri
- [ ] E-posta arşivleme
- [ ] E-posta bildirimleri
- [ ] Mobil e-posta detay ekranı
- [ ] Taslak kaydetme işlevselliği
- [ ] Rich text editor (HTML e-posta içeriği)
- [ ] E-posta imzası
- [ ] Otomatik yanıt
- [ ] E-posta kuralları/filtreleri

## 🔗 Bağımlılıklar

- `flutter_riverpod` - State yönetimi
- `go_router` - Navigasyon
- `intl` - Tarih formatı
- `Email` model - E-posta veri modeli
- `MockEmails` - Mock e-posta verileri

## 🧪 Test Durumu

⚠️ Test dosyaları henüz oluşturulmadı.

## 📚 Kullanım Örneği

```dart
// E-posta ekranına navigasyon
context.go('/email');

// E-posta filtreleme
EmailScreen(
  initialFilter: 'Okunmamış',
);

// Yeni e-posta oluşturma
showDialog(
  context: context,
  builder: (context) => ComposeEmailDialog(
    onEmailSent: (email) {
      // E-posta gönderildi
    },
  ),
);

// E-postaya yanıt verme
showDialog(
  context: context,
  builder: (context) => ComposeEmailDialog(
    replyTo: selectedEmail,
    onEmailSent: (email) {
      // Yanıt gönderildi
    },
  ),
);
```

## 🏗️ Mimari

Bu modül Clean Architecture prensiplerine uygun olarak tasarlanmıştır:
- **Presentation**: Widgets ve Screens
- **Domain**: Models ve Business Logic
- **Data**: Mock Data ve Services (TODO)

Tüm widget'lar tek sorumluluk prensibine göre ayrılmış ve tekrar kullanılabilir olacak şekilde tasarlanmıştır.

