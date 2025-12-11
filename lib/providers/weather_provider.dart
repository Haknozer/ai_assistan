import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/weather.dart';
import '../services/weather_service.dart';
import '../core/api/api_exceptions.dart';
import 'location_provider.dart';

/// Hava durumu servisi provider'ı
final weatherServiceProvider = Provider<WeatherService>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  return WeatherService(locationService: locationService);
});

/// Hava durumu state'i
class WeatherState {
  final Weather? weather;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  const WeatherState({
    this.weather,
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  WeatherState copyWith({
    Weather? weather,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) {
    return WeatherState(
      weather: weather ?? this.weather,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Hava durumu notifier'ı
class WeatherNotifier extends StateNotifier<WeatherState> {
  final WeatherService _weatherService;

  WeatherNotifier(this._weatherService) : super(const WeatherState(isLoading: false));

  /// Mevcut konuma göre hava durumunu yükle
  Future<void> loadCurrentLocationWeather() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final weather = await _weatherService.getCurrentLocationWeather();
      if (weather != null) {
        state = state.copyWith(
          weather: weather,
          isLoading: false,
          lastUpdated: DateTime.now(),
          error: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Hava durumu verisi alınamadı',
        );
      }
    } on ApiException catch (e) {
      // API hatalarını kullanıcı dostu mesajlara çevir
      String errorMessage = _getUserFriendlyErrorMessage(e);
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
    } catch (e) {
      // Genel hatalar
      String errorMessage = _getUserFriendlyErrorMessage(e);
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
    }
  }

  /// Kullanıcı dostu hata mesajı oluştur
  String _getUserFriendlyErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // API anahtarı hataları
    if (errorString.contains('api anahtarı yapılandırılmamış') || errorString.contains('api key')) {
      return 'Hava durumu API anahtarı yapılandırılmamış. Lütfen WEATHER_API_KEY ortam değişkenini ayarlayın.';
    }

    // Konum izni hataları
    if (errorString.contains('konum alınamadı') ||
        errorString.contains('location') ||
        errorString.contains('permission')) {
      return 'Konum izni gerekli. Lütfen uygulama ayarlarından konum iznini açın.';
    }

    // Network hataları
    if (errorString.contains('ağ hatası') ||
        errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('socket') ||
        errorString.contains('failed host lookup')) {
      return 'İnternet bağlantısı yok. Lütfen bağlantınızı kontrol edin.';
    }

    // API abonelik hataları
    if (errorString.contains('abonelik gerekli') ||
        errorString.contains('subscription') ||
        errorString.contains('403')) {
      return 'OpenWeatherMap One Call API 3.0 için abonelik gerekli. Lütfen hesabınızı kontrol edin.';
    }

    // API anahtarı geçersiz
    if (errorString.contains('geçersiz') ||
        errorString.contains('invalid') ||
        errorString.contains('401') ||
        errorString.contains('unauthorized')) {
      return 'Hava durumu API anahtarı geçersiz. Lütfen API anahtarınızı kontrol edin.';
    }

    // Varsayılan mesaj
    if (error is ApiException) {
      return error.message;
    }

    return 'Hava durumu yüklenirken bir hata oluştu: ${error.toString()}';
  }

  /// Koordinatlara göre hava durumunu yükle (One Call API kullanır)
  Future<void> loadWeatherByCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final weather = await _weatherService.getWeatherByCoordinates(
        latitude: latitude,
        longitude: longitude,
      );
      if (weather != null) {
        state = state.copyWith(
          weather: weather,
          isLoading: false,
          lastUpdated: DateTime.now(),
          error: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Hava durumu verisi alınamadı',
        );
      }
    } on ApiException catch (e) {
      String errorMessage = _getUserFriendlyErrorMessage(e);
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
    } catch (e) {
      String errorMessage = _getUserFriendlyErrorMessage(e);
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
    }
  }

  /// Şehir adına göre hava durumunu yükle
  Future<void> loadWeatherByCity(String cityName) async {
    state = state.copyWith(
        isLoading: false, error: 'Şehir adına göre arama desteklenmiyor. Lütfen koordinat bazlı sorgu kullanın.');
  }

  /// Hava durumunu yenile
  Future<void> refresh() async {
    if (state.weather != null) {
      // Mevcut konuma göre yenile
      await loadCurrentLocationWeather();
    }
  }

  /// Hata durumunu temizle
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Hava durumu provider'ı
final weatherProvider = StateNotifierProvider<WeatherNotifier, WeatherState>((ref) {
  final weatherService = ref.watch(weatherServiceProvider);
  return WeatherNotifier(weatherService);
});

/// Günlük hava durumu tahmini provider'ı (One Call API)
final dailyForecastProvider = FutureProvider.family<List<Weather>, WeatherForecastParams>((ref, params) async {
  final weatherService = ref.watch(weatherServiceProvider);

  if (params.latitude != null && params.longitude != null) {
    return await weatherService.getDailyForecast(
      latitude: params.latitude!,
      longitude: params.longitude!,
    );
  } else {
    throw ApiException(message: 'Koordinatlar gerekli');
  }
});

/// Saatlik hava durumu tahmini provider'ı (One Call API)
final hourlyForecastProvider = FutureProvider.family<List<Weather>, WeatherForecastParams>((ref, params) async {
  final weatherService = ref.watch(weatherServiceProvider);

  if (params.latitude != null && params.longitude != null) {
    return await weatherService.getHourlyForecast(
      latitude: params.latitude!,
      longitude: params.longitude!,
    );
  } else {
    throw ApiException(message: 'Koordinatlar gerekli');
  }
});

/// Hava durumu tahmini parametreleri
class WeatherForecastParams {
  final double? latitude;
  final double? longitude;
  final String? cityName;

  const WeatherForecastParams({
    this.latitude,
    this.longitude,
    this.cityName,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeatherForecastParams &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          cityName == other.cityName;

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode ^ cityName.hashCode;
}
