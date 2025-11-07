# Weather Service Modülü

Hava durumu servisi - OpenWeatherMap One Call API 3.0 entegrasyonu.

## 📂 Klasör Yapısı

```
services/
├── weather_service.dart (280 satır - 457'den!) ⭐
├── weather/
│   ├── geocoding_helper.dart (80 satır) ⭐ YENİ
│   ├── timezone_utils.dart (100 satır) ⭐ YENİ
│   └── README.md (bu dosya)
└── location_service.dart (mevcut)
```

## 🔧 Modüller

### WeatherService (280 satır)
**Öncesi**: 457 satır  
**Sonrası**: 280 satır  
**İyileştirme**: **%39 azalma!**

**Sorumluluklar**:
- One Call API 3.0 çağrıları
- Weather data parsing
- Error handling
- GeocodingHelper kullanımı
- TimezoneUtils kullanımı

**Metodlar**:
- `getWeatherByCoordinates()` - Koordinat bazlı hava durumu
- `getCurrentLocationWeather()` - Mevcut konum hava durumu
- `getHourlyForecast()` - Saatlik tahmin
- `getDailyForecast()` - Günlük tahmin
- `_parseOneCallWeatherData()` - API response parsing

### GeocodingHelper (80 satır) ⭐ YENİ
**Sorumluluklar**:
- Geocoding API çağrıları
- Şehir ve ülke bilgisi çıkarma
- Fallback stratejisi

**Metodlar**:
- `getLocationInfo()` - Koordinatlardan şehir/ülke al

**Özellikler**:
- ✅ Timeout handling (5 saniye)
- ✅ Error handling
- ✅ Multiple fallback (state → name → local_names)
- ✅ Debug logging

### TimezoneUtils (100 satır) ⭐ YENİ
**Sorumluluklar**:
- Timezone'dan şehir adı çıkarma
- Timezone'dan ülke kodu çıkarma
- City mapping (Türkçe şehirler)
- Country mapping (50+ ülke)

**Metodlar**:
- `extractCityFromTimezone()` - Şehir adı çıkar
- `extractCountryFromTimezone()` - Ülke kodu çıkar

**Özellikler**:
- ✅ 17 Türk şehri mapping
- ✅ 50+ ülke timezone mapping
- ✅ Fallback stratejisi

## 🔄 API Bağlantısı

### OpenWeatherMap One Call API 3.0
- **Base URL**: `https://api.openweathermap.org/data/3.0/onecall`
- **Geocoding URL**: `https://api.openweathermap.org/geo/1.0/reverse`
- **API Key**: `AppConfig.weatherApiKey`
- **Units**: metric
- **Language**: tr (Türkçe)

### API Flow
1. **Geocoding API** → Şehir/ülke bilgisi (fallback: timezone)
2. **One Call API** → Hava durumu verisi
3. **Parse** → Weather model'e dönüştür

## 📊 Kod İyileştirmeleri

### Öncesi (457 satır)
- Geocoding logic **3 yerde tekrarlanıyor**
- `_extractCityFromTimezone()` 30+ satır (içerde)
- `_extractCountryFromTimezone()` 55+ satır (içerde)
- Kod tekrarı çok fazla

### Sonrası (280 satır ana dosya)
- ✅ GeocodingHelper (DRY principle)
- ✅ TimezoneUtils (ayrı dosya)
- ✅ Kod tekrarı yok
- ✅ Modüler yapı
- ✅ Test edilebilir

## 🎯 Özellikler

### Hava Durumu Verileri
- ✅ Sıcaklık (temp, feels_like)
- ✅ Nem (humidity)
- ✅ Basınç (pressure)
- ✅ Rüzgar (speed, direction)
- ✅ Açıklama (description)
- ✅ İkon (icon code)
- ✅ Şehir/ülke bilgisi
- ✅ Timezone
- ✅ Timestamp

### Forecast
- ✅ Saatlik tahmin (48 saat)
- ✅ Günlük tahmin (7 gün)

### Error Handling
- ✅ API key kontrolü
- ✅ Network exception
- ✅ Unauthorized (401)
- ✅ Forbidden (403) - Abonelik gerekli
- ✅ Timeout handling
- ✅ Fallback stratejisi

## 📚 Kullanım Örneği

```dart
// WeatherService kullanımı
final weatherService = WeatherService();

// Koordinat bazlı sorgu
final weather = await weatherService.getWeatherByCoordinates(
  latitude: 41.0082,
  longitude: 28.9784,
);

// Mevcut konum
final currentWeather = await weatherService.getCurrentLocationWeather();

// Saatlik tahmin
final hourly = await weatherService.getHourlyForecast(
  latitude: 41.0082,
  longitude: 28.9784,
);

// Günlük tahmin
final daily = await weatherService.getDailyForecast(
  latitude: 41.0082,
  longitude: 28.9784,
);
```

## 🏗️ Mimari

Bu modül Clean Architecture prensiplerine uygun:
- **Service Layer**: WeatherService (API çağrıları)
- **Helper Layer**: GeocodingHelper, TimezoneUtils
- **Model Layer**: Weather model

**Bağımlılıklar**:
- `LocationService` - Konum servisi
- `GeocodingHelper` - Şehir/ülke bilgisi
- `TimezoneUtils` - Timezone mapping'leri

## 🔗 Bağımlılıklar

- `http` - HTTP istekleri
- `LocationService` - Konum servisi
- `Weather` model - Hava durumu modeli
- `ApiException` - Hata yönetimi
- `AppConfig` - API key

## 🧪 Test Durumu

⚠️ Test dosyaları henüz oluşturulmadı.

## 📈 Gelecek Geliştirmeler (TODO)

- [ ] Geocoding cache (şehir bilgisi cache)
- [ ] Weather data cache (5 dakika)
- [ ] Offline support
- [ ] Multiple location support
- [ ] Weather alerts
- [ ] Historical data
- [ ] Air quality data
- [ ] UV index
- [ ] Precipitation probability
- [ ] Weather maps
- [ ] Unit conversion (metric/imperial)
- [ ] Language support (i18n)

## ✅ Başarılar

- ✅ Ana dosya 457 satırdan 280 satıra düştü (**%39 azalma!**)
- ✅ Geocoding logic DRY principle (tek yerde)
- ✅ Timezone utils ayrı dosya
- ✅ Kod tekrarı yok
- ✅ Modüler yapı
- ✅ API bağlantısı korundu
- ✅ Tüm özellikler çalışıyor
- ✅ Sıfır linter hatası

---

**Son Güncelleme**: 3 Kasım 2025  
**Versiyon**: 2.0  
**Ana Dosya**: 280 satır (457'den **%39 azalma!**)  
**Toplam Dosya**: 3  
**Linter**: ✅ 0 hata

