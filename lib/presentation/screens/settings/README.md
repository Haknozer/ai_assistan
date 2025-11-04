# Settings & Integrations Screens Modülü

Ayarlar ve Entegrasyonlar ekranları - Kullanıcı tercihlerini yönetme.

## 📂 Klasör Yapısı

```
settings/
├── settings_screen.dart           # Ana ayarlar ekranı (322 satır - 967'den!)
├── integrations_screen.dart       # Entegrasyonlar ekranı (212 satır - 393'ten!)
├── data/
│   ├── settings_data.dart         # Ayarlar mock data
│   └── integrations_data.dart     # Detaylı entegrasyon data
├── utils/
│   └── settings_utils.dart        # Yardımcı fonksiyonlar
└── README.md                      # Bu dosya
```

## 🎨 Widget Yapısı

### Widgets (lib/presentation/widgets/settings/)
- `settings_page_header.dart` - Sayfa başlığı (mevcut)
- `settings_category_buttons.dart` - Kategori butonları (4 kategori)
- `integration_card.dart` - Entegrasyon kategorisi kartı
- `integration_item.dart` - Tek bir entegrasyon item
- `integrations_category_card.dart` - Genişletilebilir entegrasyon kartı
- `integrations_item_detailed.dart` - Detaylı entegrasyon item (icon placeholder)
- `notifications_card.dart` - Bildirimler kartı
- `notification_category_item.dart` - Tek bir bildirim item
- `appearance_card.dart` - Görünüm ayarları kartı (tema)
- `privacy_card.dart` - Gizlilik ve güvenlik kartı

## 🔧 Models & Data

### SettingsData
```dart
- integrations: Map<String, List<Map>> // Basit entegrasyonlar
- notificationCategories: Map<String, String> // Bildirim kategorileri
- defaultNotificationStates: Map<String, bool> // Başlangıç durumları
- categories: List<String> // 4 kategori
```

### IntegrationsData
```dart
- allIntegrations: Map<String, List<Map>> // Detaylı entegrasyonlar
  - E-posta (Gmail, Outlook, Yahoo)
  - Takvim (Google, Outlook)
  - Proje Yönetimi (Trello, Asana, Jira)
  - Depolama (Google Drive, Dropbox, OneDrive)
```

### SettingsUtils
```dart
- getCategoryDescription() // Kategori açıklaması
- getCategoryIcon() // Kategori ikonu
```

## 📊 Özellikler

### Settings Screen

#### 4 Ana Kategori
1. **Entegrasyonlar**
   - E-posta Entegrasyonları (3 servis)
   - Takvim Entegrasyonları (2 servis)
   - İletişim (3 servis)
   
2. **Bildirimler**
   - Görev Bildirimi
   - Toplantı Bildirimi
   - E-posta Bildirimi
   - AI Öngörü Bildirimi
   
3. **Görünüm**
   - Karanlık Mod (switch)
   
4. **Gizlilik**
   - AES-256 Şifreleme (etkin)
   - Bulut Senkronizasyonu (ayarlar)

#### UI/UX
- ✅ Kategori butonları (4 adet)
- ✅ Tıklayınca genişleyen bölümler
- ✅ Scroll to top animasyonu
- ✅ Bağlı/Bağlı değil durumları
- ✅ Dialog onayları
- ✅ SnackBar bildirimler

### Integrations Screen

#### Genişletilebilir Kategoriler
- E-posta Entegrasyonları (3)
- Takvim Entegrasyonları (2)
- Proje Yönetimi (3)
- Depolama (3)

**Toplam**: 11 entegrasyon

#### UI/UX
- ✅ Kategori kartları (genişletilebilir)
- ✅ Icon placeholder (40x40)
- ✅ Bağlı/Bağlanmamış durumları
- ✅ Check icon göstergesi
- ✅ Bağlan/Ayır butonları
- ✅ Dialog onayları
- ✅ Responsive design

## 🎯 Ana Fonksiyonlar

### SettingsScreen
- `_onCategoryTap()` - Kategori seçimi + scroll to top
- `_showIntegrationDialog()` - Entegrasyon onay dialogu
- `_handleNotificationChanged()` - Bildirim durumu değişimi
- `_handleMenuTap()` - Navigasyon

### IntegrationsScreen
- `_handleCategoryTap()` - Kategori genişlet/daralt
- `_showIntegrationDialog()` - Entegrasyon onay dialogu
- `_handleMenuTap()` - Navigasyon

## 🔄 State Yönetimi

### SettingsScreen
- `_selectedCategory` - Seçili kategori (default: 'Entegrasyonlar')
- `_notificationStates` - Bildirim durumları (Map)
- `_scrollController` - Scroll kontrolü

### IntegrationsScreen
- `_selectedCategory` - Seçili kategori (null)

## 📱 Responsive Davranış

### Desktop (> 900px)
- Sol menü sabit (280px)
- Geniş içerik alanı
- 4 buton yan yana

### Mobile (< 900px)
- AppBar + Drawer
- 4 buton 2x2 grid
- Kompakt UI

## 🎨 Tema ve Renkler

### Kategori Butonları
- **Seçili**: Primary color (10% alpha) arka plan
- **Seçili değil**: Transparan

### Entegrasyon Kartları
- **Seçili**: Primary border (2px, 30% alpha) + light background
- **Seçili değil**: Grey border (1px)

### Durum Badge'leri
- **BAĞLI**: Green (10% alpha background)
- **BAĞLI DEĞİL**: Grey (10% alpha background)

### Butonlar
- **Bağlan**: Primary color
- **Bağlantıyı Kes**: Red
- **Ayır**: Grey

## 📝 Kod İyileştirmeleri

### SettingsScreen
**Öncesi** (967 satır):
- Tüm UI kod ana dosyada
- `_buildIntegrationsSection()` 60+ satır
- `_buildIntegrationCard()` 60+ satır
- `_buildIntegrationItem()` 70+ satır
- `_buildNotificationsSection()` 70+ satır
- `_buildNotificationCategory()` 50+ satır
- `_buildAppearanceSection()` 90+ satır
- `_buildPrivacySection()` 140+ satır
- `_buildSettingsCategoriesCard()` 100+ satır

**Sonrası** (322 satır):
- ✅ 7 ayrı widget dosyası
- ✅ Data ve utils ayrı
- ✅ Temiz ve okunabilir
- ✅ **%67 azalma!**

### IntegrationsScreen
**Öncesi** (393 satır):
- Tüm UI kod ana dosyada
- `_buildCategoryCard()` 100+ satır
- `_buildIntegrationItem()` 80+ satır
- `_getCategoryIcon()` tekrar eden kod

**Sonrası** (212 satır):
- ✅ 3 ayrı widget dosyası
- ✅ Paylaşımlı utils
- ✅ Data ayrı
- ✅ **%46 azalma!**

## 🚀 Performans

- **Category Expansion**: Animasyonlu (300ms)
- **Scroll to Top**: Smooth animasyon
- **Lazy Loading**: Sadece seçili kategori render
- **State Management**: setState (basit ve hızlı)
- **Riverpod**: Theme toggle için

## 📚 Kullanım Örneği

### Settings Screen'e Navigasyon
```dart
context.go('/settings');
```

### Integrations Screen'e Navigasyon
```dart
context.go('/integrations');
```

### Programatik Bildirim Değişimi
```dart
_notificationStates['Görev Bildirimi'] = true;
setState(() {});
```

### Yeni Entegrasyon Eklemek
```dart
// integrations_data.dart içinde:
'Yeni Kategori': [
  {'name': 'Servis Adı', 'icon': 'path', 'connected': false},
],
```

## 🏗️ Mimari

Bu modül Clean Architecture prensiplerine uygun olarak tasarlanmıştır:
- **Presentation**: Widgets ve Screens
- **Domain**: Utils (kategoriler, ikonlar)
- **Data**: Mock Data (entegrasyonlar, bildirimler)

Tüm widget'lar bağımsız ve test edilebilir.

## 🔗 Bağımlılıklar

- `flutter_riverpod` - Theme state yönetimi
- `go_router` - Navigasyon
- `SettingsData` - Ayarlar data
- `IntegrationsData` - Entegrasyon data
- `SettingsUtils` - Yardımcı fonksiyonlar

## 🧪 Test Durumu

⚠️ Test dosyaları henüz oluşturulmadı.

## 📈 Gelecek Geliştirmeler (TODO)

- [ ] Gerçek entegrasyon API'leri (OAuth)
- [ ] Bildirim ayarlarını kaydetme (Hive/Drift)
- [ ] Dil seçimi (i18n)
- [ ] Font boyutu ayarları
- [ ] Renk teması seçenekleri
- [ ] Klavye kısayolları
- [ ] İçe/Dışa aktarma (ayarlar export)
- [ ] Hesap silme seçeneği
- [ ] İki faktörlü kimlik doğrulama
- [ ] Veri kullanım istatistikleri
- [ ] Otomatik tema (sistem tercihine göre)
- [ ] Bildirim sesi seçenekleri
- [ ] Çalışma saatleri ayarları
- [ ] Tatil modu
- [ ] Fokus modu
- [ ] Widget entegrasyonları (iOS/Android)

## 📊 Dosya Satır Sayıları

### Settings Screen Modülü

| Dosya | Satır Sayısı | Açıklama |
|-------|--------------|----------|
| **settings_screen.dart** | **322** | Ana ekran (967'den düştü!) |
| settings_data.dart | 48 | Mock data |
| integrations_data.dart | 28 | Entegrasyon data |
| settings_utils.dart | 28 | Yardımcı fonksiyonlar |
| settings_category_buttons.dart | 100 | Kategori butonları |
| integration_card.dart | 70 | Entegrasyon kartı |
| integration_item.dart | 75 | Entegrasyon item |
| notifications_card.dart | 70 | Bildirimler kartı |
| notification_category_item.dart | 60 | Bildirim item |
| appearance_card.dart | 110 | Görünüm kartı |
| privacy_card.dart | 140 | Gizlilik kartı |

### Integrations Screen Modülü

| Dosya | Satır Sayısı | Açıklama |
|-------|--------------|----------|
| **integrations_screen.dart** | **212** | Ana ekran (393'ten düştü!) |
| integrations_category_card.dart | 95 | Kategori kartı (genişletilebilir) |
| integrations_item_detailed.dart | 90 | Detaylı item |

**Settings Toplam**: ~1051 satır (önceden 967 satır TEK DOSYADA!)  
**Integrations Toplam**: ~397 satır (önceden 393 satır TEK DOSYADA!)  
**Şimdi**: Settings 11 dosyada, Integrations 3 dosyada - modüler ve bakımı kolay! 🎉

## ✅ Başarılar

### Settings Screen
- ✅ Ana dosya 967 satırdan 322 satıra düştü (**%67 azalma!**)
- ✅ 11 modüler dosyaya bölündü
- ✅ 7 widget oluşturuldu
- ✅ Data ve utils ayrıldı
- ✅ Tüm özellikler çalışıyor
- ✅ Responsive design korundu
- ✅ Sıfır linter hatası

### Integrations Screen
- ✅ Ana dosya 393 satırdan 212 satıra düştü (**%46 azalma!**)
- ✅ 3 modüler dosyaya bölündü
- ✅ 2 widget oluşturuldu
- ✅ Data ayrıldı
- ✅ Utils paylaşıldı
- ✅ Tüm özellikler çalışıyor
- ✅ Responsive design korundu
- ✅ Sıfır linter hatası

## 🎯 Öne Çıkan İyileştirmeler

1. **Kod Tekrarı Azaldı**: Utils sayesinde kategori ikonları ve açıklamaları tek yerde
2. **Paylaşımlı Widget'lar**: Integration widget'ları iki ekranda da kullanılabilir
3. **Data Ayrımı**: Settings ve Integrations data'ları ayrı dosyalarda
4. **Modüler Yapı**: Her widget bağımsız ve test edilebilir
5. **Temiz Kod**: Ana dosyalar sadece koordinasyon yapıyor

---

**Son Güncelleme**: 3 Kasım 2025  
**Versiyon**: 2.0  
**Settings Ana Dosya**: 322 satır (967'den **%67 azalma!**)  
**Integrations Ana Dosya**: 212 satır (393'ten **%46 azalma!**)  
**Toplam Dosya**: 14  
**Linter**: ✅ 0 hata

