import 'package:json_annotation/json_annotation.dart';

part 'weather.g.dart';

/// Hava durumu modeli
@JsonSerializable()
class Weather {
  final double temperature; // Celsius
  final double feelsLike; // Hissedilen sıcaklık
  final int humidity; // Nem yüzdesi
  final double pressure; // Basınç (hPa)
  final double windSpeed; // Rüzgar hızı (m/s)
  final int windDirection; // Rüzgar yönü (derece)
  final String description; // Açıklama (örn: "Açık", "Bulutlu")
  final String icon; // İkon kodu
  final String city; // Şehir adı
  final String country; // Ülke kodu
  final String timezone; // Timezone (örn: "America/Chicago")
  final DateTime timestamp; // Veri zamanı

  Weather({
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.pressure,
    required this.windSpeed,
    required this.windDirection,
    required this.description,
    required this.icon,
    required this.city,
    required this.country,
    required this.timezone,
    required this.timestamp,
  });

  factory Weather.fromJson(Map<String, dynamic> json) => _$WeatherFromJson(json);
  Map<String, dynamic> toJson() => _$WeatherToJson(this);

  /// Sıcaklığı formatla
  String get formattedTemperature => '${temperature.toStringAsFixed(1)}°C';

  /// Hissedilen sıcaklığı formatla
  String get formattedFeelsLike => '${feelsLike.toStringAsFixed(1)}°C';

  /// Rüzgar hızını formatla (m/s'den km/h'ye çevir: 1 m/s = 3.6 km/h)
  String get formattedWindSpeed {
    final kmh = windSpeed * 3.6;
    return '${kmh.toStringAsFixed(1)} km/s';
  }

  /// Basıncı formatla
  String get formattedPressure => '${pressure.toStringAsFixed(0)} hPa';

  /// Nem yüzdesini formatla
  String get formattedHumidity => '$humidity%';
}
