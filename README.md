# AI Asistan

Clean Architecture, Riverpod ve modüler feature yapısı kullanan çoklu hesap (Gmail/Outlook), takvim, görev, analytics ve AI asistan deneyimi sunan Flutter uygulaması.

## Gereksinimler
- Flutter 3.22+ / Dart 3.4+
- Desktop hedefleri için platform bağımlılıkları (Windows/macOS/Linux)
- Gmail/Outlook OAuth client bilgileri

## Hızlı Başlangıç (Windows)
1) `run_windows.bat` içindeki ortam değişkenlerini doldurun:
   - `API_BASE_URL` (mock için `http://localhost:3000` kullanabilirsiniz)
   - `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET`
   - `MICROSOFT_CLIENT_ID` / `MICROSOFT_CLIENT_SECRET`
   - `TELEGRAM_BOT_TOKEN`, `N8N_TELEGRAM_WEBHOOK_URL`, `N8N_EMAIL_WEBHOOK_URL`
2) Çalıştırın:
   ```bat
   run_windows.bat
   ```

## Diğer Platformlarda Çalıştırma
```bash
flutter pub get
flutter run \
  --dart-define=API_BASE_URL=https://api.example.com \
  --dart-define=GOOGLE_CLIENT_ID=... \
  --dart-define=GOOGLE_CLIENT_SECRET=... \
  --dart-define=MICROSOFT_CLIENT_ID=... \
  --dart-define=MICROSOFT_CLIENT_SECRET=... \
  --dart-define=TELEGRAM_BOT_TOKEN=... \
  --dart-define=N8N_TELEGRAM_WEBHOOK_URL=... \
  --dart-define=N8N_EMAIL_WEBHOOK_URL=...
```

## Mimari Özeti
- Clean Architecture + feature bazlı modüller (`lib/features/*`)
- Core katmanı: API client, config, constants, utils (`AppLogger`, `ErrorHandler`)
- State management: Riverpod
- Routing: GoRouter (`lib/core/router/app_router.dart`)
- UI: `lib/presentation/screens` + paylaşılan widget’lar

### Dokümanlar
- `ARCHITECTURE.md`
- `MODULAR_STRUCTURE_AUDIT.md`
- `PROFESSIONAL_IMPROVEMENTS.md`
- Feature README’leri: `lib/features/*/` ve `lib/presentation/screens/*/README.md`

## Test
```bash
flutter test                # tüm testler
flutter test test/core/utils # core utils hızlı kontrol
```

## API / Mock
- Gerçek backend için `API_BASE_URL`’i kendi sunucunuza yönlendirin.
- Hızlı deneme: JSON Server mock (bkz. `API_NASIL_HAZIR_OLACAK.md`).

## Google Cloud Speech / TTS
- Google Cloud’da Speech-to-Text ve Text-to-Speech API’lerini enable edin.
- Bir Service Account oluşturup JSON anahtarını yerelde saklayın (repo dışı).
- `run_windows.bat` içinde doldurun:
  - `GOOGLE_APPLICATION_CREDENTIALS=C:\keys\gcp-service-account.json`
  - `GCP_PROJECT_ID=proje-id`
  - `GCP_STT_LANGUAGE=tr-TR` (veya ihtiyacınız)
  - `GCP_TTS_VOICE=tr-TR-Wavenet-D` (veya seçtiğiniz voice)
  - `GCP_TTS_ENCODING=MP3`
- Masaüstü uygulamasında “Sesli Asistan” butonu ve kısayolu (Ctrl/Cmd + Shift + V) ile push-to-talk çalışır.

## Güvenlik
- Örnek client secret / token değerlerini üretimde kullanmayın.
- Ortam değişkenlerini `.env`/CI gizli değişkenleri veya platforma özel script’lerle geçirin.
