# Calendar Feature - Google Calendar API Entegrasyonu

Bu feature, Google Calendar API ile entegre edilmiş takvim yönetimi sağlar.

## 📁 Klasör Yapısı

```
lib/features/calendar/
├── data/
│   ├── datasources/
│   │   ├── calendar_remote_datasource.dart
│   │   └── google/
│   │       └── google_calendar_api_client.dart
│   └── repositories/
│       └── calendar_repository.dart
├── providers/
│   └── calendar_provider.dart
└── calendar_feature.dart
```

## 🔧 Kullanım

### 1. Calendar Screen'de Provider Kullanımı

```dart
import 'package:ai_asisstan/features/calendar/calendar_feature.dart';
import 'package:ai_asisstan/providers/user_provider.dart';

// Calendar screen'de
final currentUser = ref.watch(currentUserProvider);
final accessToken = 'your-access-token'; // OAuth servisinden alınacak

// Event listesi için
final eventParams = EventListParams(
  calendarId: 'primary', // veya belirli bir calendar ID
  timeMin: DateTime.now(),
  timeMax: DateTime.now().add(Duration(days: 30)),
  maxResults: 50,
  accessToken: accessToken,
  userId: currentUser?.id,
);

final eventsAsync = ref.watch(calendarNotifierProvider(eventParams));

eventsAsync.when(
  data: (events) {
    // Event'leri göster
    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return ListTile(
          title: Text(event.title),
          subtitle: Text(event.formattedTime),
        );
      },
    );
  },
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => Text('Hata: $error'),
);
```

### 2. Event Oluşturma

```dart
final calendarNotifier = ref.read(calendarNotifierProvider(eventParams).notifier);

await calendarNotifier.createEvent(
  title: 'Yeni Toplantı',
  startTime: DateTime.now().add(Duration(hours: 1)),
  endTime: DateTime.now().add(Duration(hours: 2)),
  description: 'Toplantı açıklaması',
  location: 'Ofis',
  eventType: EventType.meeting,
);
```

### 3. Event Güncelleme

```dart
await calendarNotifier.updateEvent(
  eventId: 'google-calendar-event-id',
  title: 'Güncellenmiş Başlık',
  startTime: DateTime.now().add(Duration(hours: 2)),
  endTime: DateTime.now().add(Duration(hours: 3)),
);
```

### 4. Event Silme

```dart
await calendarNotifier.deleteEvent('google-calendar-event-id');
```

### 5. Calendar Listesi

```dart
final calendarsAsync = ref.watch(calendarsProvider(accessToken));

calendarsAsync.when(
  data: (calendars) {
    return ListView.builder(
      itemCount: calendars.length,
      itemBuilder: (context, index) {
        final calendar = calendars[index];
        return ListTile(
          title: Text(calendar['summary'] ?? 'Calendar'),
          subtitle: Text(calendar['id'] ?? ''),
        );
      },
    );
  },
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => Text('Hata: $error'),
);
```

## 🔐 OAuth Entegrasyonu

Google Calendar OAuth servisi `lib/services/google_calendar_oauth_service.dart` dosyasında bulunur.

### OAuth Bağlantısı

```dart
import 'package:ai_asisstan/services/google_calendar_oauth_service.dart';

final oauthService = GoogleCalendarOAuthService();

try {
  final result = await oauthService.connectCalendar();
  // result.accessToken kullanılabilir
  // result.refreshToken saklanmalı
  // result.email kullanıcı e-postası
} catch (e) {
  // Hata yönetimi
}
```

### Token Yenileme

```dart
final newResult = await oauthService.refreshAccessToken(refreshToken);
// Yeni access token kullanılabilir
```

## 📝 Notlar

1. **Access Token**: OAuth servisinden alınan access token, Calendar API çağrılarında kullanılır.
2. **Refresh Token**: Access token süresi dolduğunda, refresh token ile yeni access token alınabilir.
3. **Calendar ID**: `'primary'` varsayılan calendar'ı temsil eder. Diğer calendar'lar için calendar listesinden ID alınmalıdır.
4. **Time Zones**: Event'ler UTC olarak saklanır, gösterimde local time'a çevrilir.

## 🐛 Hata Yönetimi

- `UnauthorizedException`: Access token geçersiz veya süresi dolmuş. Token yenilenmeli veya OAuth yeniden yapılmalı.
- `ApiException`: Genel API hataları. Mesaj içinde detay bulunur.

## ✅ Özellikler

- ✅ Calendar listesi çekme
- ✅ Event listesi çekme (tarih aralığı ile)
- ✅ Event oluşturma
- ✅ Event güncelleme
- ✅ Event silme
- ✅ OAuth entegrasyonu
- ✅ Token yenileme
- ✅ Riverpod state management

