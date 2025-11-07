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
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
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
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Şehir adına göre hava durumunu yükle
  Future<void> loadWeatherByCity(String cityName) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final weather = await _weatherService.getWeatherByCityName(cityName);
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
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
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
