# Calendar Screen - Widget Yapısı

Bu modül, takvim ekranı için profesyonel bir şekilde organize edilmiş widget yapısını içerir.

## 📁 Dosya Yapısı

```
lib/presentation/
├── screens/calendar/
│   ├── calendar_screen.dart        # Ana ekran (311 satır - 1425'ten!)
│   ├── data/
│   │   └── mock_events.dart         # Test verileri + yardımcı metodlar
│   └── utils/
│       └── calendar_utils.dart      # Yardımcı fonksiyonlar
└── widgets/calendar/                # Takvim widget'ları
    ├── calendar_page_header.dart    # Sayfa başlığı + etkinlik ekle
    ├── month_selector.dart          # Ay/yıl seçimi + bugün butonu
    ├── calendar_grid.dart           # Takvim günleri grid'i
    ├── day_cell.dart                # Tek gün hücresi
    ├── events_list.dart             # Etkinlik listesi
    ├── event_card.dart              # Tek etkinlik kartı
    ├── add_event_dialog.dart        # Etkinlik ekleme formu
    └── event_notification_overlay.dart # Bildirim overlay'i
```

## 🏗️ Mimari Yapı

### 1. **Data Katmanı**
- `MockEvents`: Mock etkinlik verileri ve yardımcı metodlar
  - `events`: Liste etkinlikler
  - `getEventsForDay()`: Günlük etkinlikler
  - `getEventsForMonth()`: Aylık etkinlikler
  - `getTodayEvents()`: Bugünün etkinlikleri
  - `getUpcomingEvents()`: Yaklaşan etkinlikler

### 2. **Utils Katmanı**
- `CalendarUtils`: Yardımcı fonksiyonlar
  - **Renk/İkon Fonksiyonları**:
    - `getEventTypeColor()`: Etkinlik tipi rengi
    - `getEventTypeIcon()`: Etkinlik tipi ikonu
    - `getEventSourceColor()`: Kaynak rengi
    - `getEventSourceIcon()`: Kaynak ikonu
  - **Tarih Fonksiyonları**:
    - `formatDate()`: Tarih formatla
    - `formatTime()`: Saat formatla
    - `formatDateTime()`: Tarih/saat formatla
    - `calculateDuration()`: Süre hesapla
  - **Kontrol Fonksiyonları**:
    - `isToday()`: Bugün mü?
    - `isPast()`: Geçmiş mi?
    - `isFuture()`: Gelecek mi?
  - **Hesaplama Fonksiyonları**:
    - `getFirstDayOfMonth()`: Ayın ilk günü
    - `getLastDayOfMonth()`: Ayın son günü
    - `getDaysInMonth()`: Aydaki gün sayısı
    - `getFirstWeekdayOfMonth()`: İlk günün haftanın hangi günü

### 3. **Widget Katmanı**

#### Ana Layout Widget'ları
- **CalendarPageHeader**: Sayfa başlığı + etkinlik ekle butonu
  - Desktop: Geniş başlık + text butonu
  - Mobile: Kompakt başlık + icon butonu

- **MonthSelector**: Ay/yıl navigasyonu
  - Önceki/sonraki ay butonları
  - Mevcut ay/yıl gösterimi
  - "Bugün" butonu

#### Takvim Widget'ları
- **CalendarGrid**: Takvim grid container
  - Haftanın günleri başlığı
  - 6 hafta x 7 gün grid (42 hücre)
  - Önceki/sonraki ay günleri dahil

- **DayCell**: Tek gün hücresi
  - Gün numarası
  - Etkinlik göstergeleri (maksimum 3)
  - "+N" fazla etkinlik göstergesi
  - Bugün vurgusu
  - Tıklanabilir

#### Etkinlik Widget'ları
- **EventsList**: Etkinlik listesi container
  - Başlık + etkinlik sayısı
  - Scroll edilebilir liste
  - Boş durum göstergesi

- **EventCard**: Tek etkinlik kartı
  - Etkinlik tipi renk göstergesi
  - Başlık + tip ikonu
  - Zaman bilgisi + süre
  - Lokasyon (opsiyonel)
  - Açıklama (opsiyonel)
  - Kaynak ikonu

#### Dialog Widget'ı
- **AddEventDialog**: Etkinlik ekleme formu
  - Başlık (zorunlu)
  - Açıklama (opsiyonel)
  - Lokasyon (opsiyonel)
  - Etkinlik tipi seçici (chip'ler)
  - Tarih seçici
  - Başlangıç/bitiş saati seçici
  - Form validasyonu

#### Bildirim Widget'ı
- **EventNotificationOverlay**: Toast bildirimleri
  - Etkinlik ekleme bildirimi
  - Otomatik kapanma (4 saniye)
  - Manuel kapatma butonu

## 📊 Kod Metrikleri

| Metrik | Önce | Sonra | İyileştirme |
|--------|------|-------|-------------|
| **Ana Dosya** | 1425 satır | 311 satır | ✅ **78% azalma** |
| **Dosya Sayısı** | 1 | 11 | ✅ Modüler |
| **Ortalama Satır/Dosya** | 1425 | ~283 | ✅ Okunabilir |
| **Linter Hatası** | 0 | 0 | ✅ Temiz |

## 🎯 Özellikler

### ✅ Eklenen İyileştirmeler
1. **Modüler Yapı**: Her widget ayrı dosyada
2. **Utility Fonksiyonlar**: Tekrar eden kod yok
3. **Mock Data Ayrımı**: Veri yönetimi kolaylaştı
4. **Widget Hierarchy**: Alt widget'lar ile temiz yapı
5. **Calendar Grid**: 6 haftalık görünüm (42 gün)
6. **Day Selection**: Günlük etkinlik filtreleme
7. **Responsive**: Desktop ve mobile uyumlu
8. **Bildirimler**: Overlay bildirimleri
9. **Form Validation**: Etkinlik ekleme validasyonu
10. **Theme-Aware**: Dark mode uyumlu

### 🚀 Kullanım

```dart
// Ana Ekran
CalendarScreen()

// Widget'ları Tek Tek Kullanma
CalendarPageHeader(
  onAddEvent: () {},
  isDesktop: true,
)

MonthSelector(
  currentMonth: DateTime.now(),
  onPreviousMonth: () {},
  onNextMonth: () {},
  onTodayTap: () {},
)

CalendarGrid(
  currentMonth: DateTime.now(),
  events: events,
  onDayTap: (day) {},
)

EventsList(
  title: 'Etkinlikler',
  events: events,
  onEventTap: (event) {},
)
```

## 🔄 Genişletme Önerileri

1. **State Management**: Riverpod ile etkinlik yönetimi
2. **API Entegrasyonu**: Backend bağlantısı
3. **Google Calendar Sync**: Google Calendar entegrasyonu
4. **Outlook Sync**: Outlook Calendar entegrasyonu
5. **Recurring Events**: Tekrarlayan etkinlikler
6. **Event Reminders**: Hatırlatıcılar
7. **Event Categories**: Kategori yönetimi
8. **Drag & Drop**: Etkinlikleri sürükle
9. **Month/Week/Day Views**: Farklı görünümler
10. **Event Sharing**: Etkinlik paylaşma

## 📝 Widget İlişkileri

```
CalendarScreen
├── CalendarPageHeader
├── MonthSelector
└── Column/Row (Responsive)
    ├── CalendarGrid
    │   ├── WeekdayHeader
    │   └── GridView.builder
    │       └── DayCell (x42)
    └── EventsList
        ├── Header (title + count)
        └── ListView.builder
            └── EventCard (xN)

AddEventDialog
├── Form Fields
│   ├── Title (required)
│   ├── Description
│   ├── Location
│   ├── EventType Selector (FilterChip)
│   ├── Date Picker
│   ├── Start Time Picker
│   └── End Time Picker
└── Action Buttons

EventNotificationOverlay
└── OverlayEntry (Toast)
```

## 🎨 Tasarım Kararları

### Renkler
- **Meeting**: Mavi (Primary)
- **Appointment**: Yeşil (Success)
- **Task**: Turuncu (Warning)
- **Personal**: Mor (Purple)
- **Other**: Gri (Grey)

**Kaynaklar**:
- **Manual**: Gri
- **Google**: Google Mavi (#4285F4)
- **Outlook**: Microsoft Mavi (#0078D4)
- **Apple**: Siyah

### Takvim Grid
- **42 Hücre**: 6 hafta x 7 gün
- **Önceki/Sonraki Ay**: Düşük opaklık
- **Bugün**: Primary renk border + background
- **Geçmiş Günler**: Düşük opaklık
- **Etkinlik Göstergeleri**: Maksimum 3 çizgi

### Responsive
- **Desktop**: Yatay layout (Grid %60 + Liste %40)
- **Mobile**: Dikey layout (Grid üstte + Liste altta)

## 🔧 Önemli Notlar

1. **CalendarEvent Model**: `models/calendar_event.dart` kullanılıyor
2. **EventType Enum**: meeting, appointment, task, personal, other
3. **EventSource Enum**: manual, google, outlook, apple
4. **Theme System**: AppTheme ve AppColors kullanıyor
5. **Riverpod**: User provider entegrasyonu var
6. **Go Router**: Navigasyon için kullanılıyor
7. **Intl Package**: Tarih formatlama için

## ⚡ Performans

- **Widget const**: Mümkün olduğunca const constructor
- **GridView.builder**: Lazy loading takvim hücreleri
- **ListView.builder**: Lazy loading etkinlik listesi
- **Minimal Rebuild**: setState kullanımı optimize
- **Efficient Filtering**: Etkinlik filtreleme optimize

## 📱 Platform Desteği

- ✅ **Web**: Tam destek
- ✅ **iOS**: Tam destek
- ✅ **Android**: Tam destek
- ✅ **macOS**: Tam destek
- ✅ **Windows**: Tam destek
- ✅ **Linux**: Tam destek

---

**Son Güncelleme**: 2 Kasım 2025  
**Versiyon**: 2.0  
**Toplam Dosya**: 11 (1'den 11'e!)  
**Ana Dosya**: 311 satır (1425'ten %78 azalma!)  
**Linter**: ✅ 0 hata

