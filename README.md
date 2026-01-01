# 🤖 AI Asistan

Yapay zeka destekli kişisel asistan uygulaması. Flutter ile geliştirilmiş cross-platform mobil ve masaüstü uygulaması ile FastAPI tabanlı backend servisinden oluşmaktadır.

---

## 📋 İçindekiler

- [Özellikler](#özellikler)
- [Gereksinimler](#gereksinimler)
- [Kurulum](#kurulum)
  - [Backend Kurulumu](#backend-kurulumu)
  - [Flutter Uygulaması Kurulumu](#flutter-uygulaması-kurulumu)
  - [n8n Workflow Kurulumu](#n8n-workflow-kurulumu)
- [Ortam Değişkenleri](#ortam-değişkenleri)
- [Çalıştırma](#çalıştırma)
- [Mimari](#mimari)

---

## ✨ Özellikler

- 🗣️ **Sesli Komutlar**: "Jarvis" wake word ile sesli asistan aktivasyonu
- 📧 **E-posta Entegrasyonu**: Gmail ve Microsoft Outlook e-posta yönetimi
- 🤖 **AI Chatbot**: n8n tabanlı yapay zeka sohbet asistanı
- 📊 **Görev Yönetimi**: Kişisel görev takibi ve hatırlatmalar
- 🔔 **Bildirimler**: Gerçek zamanlı push bildirimleri
- 🌐 **Multi-platform**: Windows, macOS, Linux, Android, iOS ve Web desteği

---

## 🛠️ Gereksinimler

### Flutter (Mobil/Desktop Uygulama)
- **Flutter SDK**: 3.0.0 veya üzeri
- **Dart SDK**: 3.0.0 veya üzeri

### Backend
- **Docker** ve **Docker Compose** (Önerilen)
- veya
- **Python**: 3.10 veya üzeri
- **PostgreSQL**: 15+
- **Redis**: 7+

### Harici Servisler
- Google Cloud hesabı (Gmail API, Pub/Sub için)
- n8n hesabı (webhook entegrasyonu için)
- Supabase hesabı (Authentication için)
- Picovoice hesabı (Porcupine wake word için - opsiyonel)

---

## 🚀 Kurulum

### Backend Kurulumu

#### 1. Docker ile Kurulum (Önerilen)

```bash
# Backend klasörüne git
cd ai_asisstan_backend

# Ortam değişkenlerini ayarla
cp .env.example .env
# .env dosyasını düzenle ve gerekli değerleri gir

# Docker containerları başlat
docker-compose up -d
```

Bu komut aşağıdaki servisleri başlatacaktır:
- **Backend API**: `http://localhost:3000`
- **PostgreSQL**: `localhost:5432`
- **Redis**: `localhost:6379`

#### 2. Manuel Kurulum (Docker olmadan)

```bash
# Backend klasörüne git
cd ai_asisstan_backend

# Virtual environment oluştur
python -m venv venv

# Virtual environment aktive et
# Windows:
venv\Scripts\activate
# Linux/macOS:
source venv/bin/activate

# Bağımlılıkları yükle
pip install -r requirements.txt

# Veritabanı migrasyonlarını çalıştır
alembic upgrade head

# Backend'i başlat
uvicorn app.main:app --host 0.0.0.0 --port 3000 --reload
```

> **Not**: Manuel kurulumda PostgreSQL ve Redis servislerinin ayrıca çalışır durumda olması gerekmektedir.

---

### Flutter Uygulaması Kurulumu

```bash
# Ana proje klasörüne git
cd ai_asisstan

# Flutter bağımlılıklarını yükle
flutter pub get

# Kodu generate et (Riverpod ve JSON serialization için)
flutter pub run build_runner build --delete-conflicting-outputs
```

---

### n8n Workflow Kurulumu

Proje, n8n otomasyon platformu ile entegre çalışmaktadır. Hazır workflow dosyaları `n8n/` klasöründe bulunmaktadır:

| Dosya | Açıklama |
|-------|----------|
| `Jarvis.json` | AI chatbot ve sesli asistan workflow'u |
| `Görev.json` | E-posta ve görev yönetimi workflow'u |

#### Workflow'ları n8n'e Import Etme

1. n8n hesabınıza giriş yapın
2. Sol menüden **Workflows** > **Import from File** seçin
3. `n8n/` klasöründeki JSON dosyalarını sırayla import edin
4. Her workflow için:
   - Credential'ları (API anahtarları) yapılandırın
   - Webhook URL'lerini kopyalayın
   - Workflow'u **Activate** edin

5. Kopyaladığınız webhook URL'lerini:
   - Backend `.env` dosyasına (`N8N_EMAIL_WEBHOOK_URL`)
   - Flutter `app_config.dart` dosyasına (`chatbotWebhookUrl`) ekleyin

> **Not**: Workflow'ların düzgün çalışması için OpenAI API key ve diğer credential'ların n8n'de tanımlı olması gerekmektedir.

---

## 🔧 Ortam Değişkenleri

### Backend (.env)

`ai_asisstan_backend/.env` dosyasını oluşturun:

```env
# Database
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/ai_asisstan

# Security
SECRET_KEY=your-secret-key-here
DEBUG=True
ENVIRONMENT=development

# Redis
REDIS_URL=redis://localhost:6379/0

# Google Cloud
GOOGLE_CLOUD_PROJECT_ID=your-project-id
PUBSUB_SUBSCRIPTION_NAME=your-subscription
PUBSUB_TOPIC_NAME=your-topic
GOOGLE_APPLICATION_CREDENTIALS=./credentials/your-credentials.json

# OAuth - Google
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret

# OAuth - Microsoft
MS_CLIENT_ID=your-microsoft-client-id
MS_CLIENT_SECRET=your-microsoft-client-secret

# n8n Webhook
N8N_EMAIL_WEBHOOK_URL=https://your-n8n-instance/webhook/your-webhook-id

# CORS
CORS_ORIGINS=http://localhost:3000,http://localhost:8080
```

### Flutter Uygulaması

`lib/core/config/app_config.dart` dosyasında API URL'lerini güncelleyin:

```dart
// Backend API URL
static const String apiBaseUrl = 'http://localhost:3000';

// n8n Webhook URL'leri
static const String chatbotWebhookUrl = 'https://your-n8n-instance/webhook/...';
```

---

## ▶️ Çalıştırma

### 1. Backend'i Başlat

```bash
cd ai_asisstan_backend
docker-compose up -d
```

### 2. Flutter Uygulamasını Başlat

```bash
# Windows
flutter run -d windows

# macOS
flutter run -d macos

# Linux
flutter run -d linux

# Android (Emülatör veya bağlı cihaz)
flutter run -d android

# iOS (macOS + Xcode gerekli)
flutter run -d ios

# Web
flutter run -d chrome
```

### API Dokümantasyonu

Backend çalışırken API dokümantasyonuna erişebilirsiniz:
- **Swagger UI**: http://localhost:3000/docs
- **ReDoc**: http://localhost:3000/redoc

---

## 🏗️ Mimari

```
ai_asisstan/
├── lib/                          # Flutter uygulama kodu
│   ├── core/                     # Çekirdek modüller (config, router, theme)
│   ├── features/                 # Özellik bazlı modüller
│   ├── models/                   # Veri modelleri
│   ├── providers/                # Riverpod state yönetimi
│   ├── services/                 # API ve platform servisleri
│   └── main.dart                 # Uygulama giriş noktası
│
├── ai_asisstan_backend/          # FastAPI backend
│   ├── app/
│   │   ├── api/                  # API endpoint'leri
│   │   ├── models/               # SQLAlchemy modelleri
│   │   ├── services/             # İş mantığı servisleri
│   │   └── main.py               # Backend giriş noktası
│   ├── docker-compose.yml        # Docker yapılandırması
│   └── requirements.txt          # Python bağımlılıkları
│
├── n8n/                          # n8n workflow dosyaları
│   ├── Jarvis.json               # AI chatbot workflow
│   └── Görev.json                # E-posta/görev workflow
│
├── android/                      # Android platform kodu
├── ios/                          # iOS platform kodu
├── windows/                      # Windows platform kodu
├── macos/                        # macOS platform kodu
├── linux/                        # Linux platform kodu
├── web/                          # Web platform kodu
└── pubspec.yaml                  # Flutter bağımlılıkları
```

---

## 🔍 Sorun Giderme

### Backend bağlantı hatası
- Backend servisinin çalıştığından emin olun: `docker ps`
- Firewall ayarlarını kontrol edin
- Backend URL'inin doğru yapılandırıldığını kontrol edin

### Flutter derleme hataları
```bash
# Cache'i temizle
flutter clean

# Bağımlılıkları yeniden yükle
flutter pub get

# Build runner'ı çalıştır
flutter pub run build_runner build --delete-conflicting-outputs
```

### Veritabanı migrasyonu hataları
```bash
cd ai_asisstan_backend

# Docker ile
docker-compose exec backend alembic upgrade head

# Manuel
alembic upgrade head
```

---

## 📝 Lisans

Bu proje özel kullanım içindir.

---

## 📞 İletişim

Sorularınız için issue açabilirsiniz.
