# Core Utilities - Profesyonel İyileştirmeler

Bu klasör, uygulamanın temel yardımcı sınıflarını içerir.

## 📦 Dosyalar

### `logger.dart`
Profesyonel logging sistemi. Tüm `debugPrint()` ve `print()` kullanımlarının yerine kullanılmalıdır.

**Özellikler:**
- Debug modunda detaylı loglar
- Production'da sadece kritik hatalar
- Tag desteği ile kategorize edilmiş loglar
- Özel log tipleri: API, OAuth, Database

**Kullanım:**
```dart
// Debug log
AppLogger.debug('User logged in', 'Auth');

// Info log
AppLogger.info('Data loaded successfully', 'Data');

// Warning log
AppLogger.warning('Cache miss', 'Cache', error);

// Error log
AppLogger.error('Failed to save', tag: 'Database', error: e, stackTrace: stack);

// API log
AppLogger.api('GET', '/api/users', statusCode: 200, tag: 'API');

// OAuth log
AppLogger.oauth('Token refreshed', tag: 'OAuth');

// Database log
AppLogger.database('Query executed', 'Database');
```

### `error_handler.dart`
Merkezi hata yönetimi ve kullanıcı dostu mesajlar.

**Özellikler:**
- Otomatik hata tipi tespiti
- Kullanıcı dostu Türkçe mesajlar
- SnackBar ile otomatik gösterim
- Retry mekanizması desteği

**Kullanım:**
```dart
// Hata göster ve logla
try {
  await someOperation();
} catch (e) {
  ErrorHandler.handleError(
    context,
    e,
    tag: 'Operation',
    onRetry: () => someOperation(),
  );
}

// Sadece logla (kullanıcıya gösterme)
ErrorHandler.logError(e, tag: 'Background');

// Başarı mesajı
ErrorHandler.showSuccess(context, 'İşlem başarılı');

// Bilgilendirme mesajı
ErrorHandler.showInfo(context, 'Bilgi mesajı');
```

## 🎯 Best Practices

1. **Logging:**
   - Production kodunda `print()` kullanmayın
   - `debugPrint()` yerine `AppLogger` kullanın
   - Her log için uygun tag belirleyin

2. **Error Handling:**
   - Tüm hataları `ErrorHandler` ile yönetin
   - Kullanıcıya teknik detaylar göstermeyin
   - Retry mekanizması ekleyin mümkünse

3. **Constants:**
   - Magic numbers ve strings için `AppConstants` kullanın
   - Yeni constant'lar eklerken dokümantasyon ekleyin

## 📚 İlgili Dosyalar

- `lib/core/constants/app_constants.dart` - Uygulama sabitleri
- `lib/core/api/api_exceptions.dart` - API exception sınıfları

