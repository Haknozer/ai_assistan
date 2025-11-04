# Email Feature - Modüler Yapı Dokümantasyonu

## 📁 Feature-Based Modüler Yapı

Bu feature Clean Architecture prensiplerine uygun olarak tasarlanmıştır:

```
lib/features/email/
├── data/
│   ├── datasources/
│   │   └── email_remote_datasource.dart    # API çağrıları
│   └── repositories/
│       └── email_repository.dart          # Repository pattern (API + Cache)
├── domain/
│   └── models/                            # (Shared models klasöründen referans)
├── presentation/
│   ├── screens/
│   │   └── email_screen.dart             # Ana ekran
│   └── widgets/                           # (Shared widgets klasöründen referans)
├── providers/
│   └── email_provider.dart                # Riverpod providers
└── email_feature.dart                     # Barrel export
```

## 🔄 Katmanlar Arası İlişkiler

### Data Layer
- **EmailRemoteDataSource**: API çağrılarını yönetir
- **EmailRepository**: API ve Cache senkronizasyonu

### Domain Layer
- **Email Model**: Shared models klasöründen import edilir

### Presentation Layer
- **EmailScreen**: UI katmanı
- **Widgets**: Shared widgets klasöründen import edilir

### Providers Layer
- **EmailProvider**: State management için Riverpod providers

## 🔌 Dependency Injection

Tüm bağımlılıklar constructor injection ile sağlanır:

```dart
EmailRepository(
  remoteDataSource: EmailRemoteDataSource(),
  databaseService: DatabaseService.instance,
)
```

## 📦 Barrel Export

Tüm feature export'ları `email_feature.dart` dosyasından yapılabilir:

```dart
import 'package:ai_asisstan/features/email/email_feature.dart';
```

## 🧪 Test Yapısı

Test dosyaları `test/features/email/` klasöründe:

```
test/features/email/
├── data/
│   ├── datasources/
│   │   └── email_remote_datasource_test.dart
│   └── repositories/
│       └── email_repository_test.dart
└── providers/
    └── email_provider_test.dart
```

## ✅ Özellikler

- ✅ Feature-based modüler yapı
- ✅ Clean Architecture prensipleri
- ✅ Dependency Injection
- ✅ Repository pattern
- ✅ Offline-first yaklaşım
- ✅ Test altyapısı hazır
- ✅ Barrel export desteği

