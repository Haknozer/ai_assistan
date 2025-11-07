import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

/// Konum servisi - Kullanıcının konumunu almak için
class LocationService {
  /// Konum iznini kontrol et ve iste
  Future<bool> requestLocationPermission() async {
    try {
      // Windows için özel kontrol
      if (defaultTargetPlatform == TargetPlatform.windows) {
        // Windows'ta konum servisi genellikle sistem ayarlarından kontrol edilir
        // Geolocator Windows'ta çalışır ancak izin kontrolü farklı olabilir
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          debugPrint('Konum servisi kapalı. Lütfen Windows ayarlarından konum servisini açın.');
          return false;
        }
        return true;
      }

      // Android ve iOS için izin kontrolü
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Konum izni reddedildi');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Konum izni kalıcı olarak reddedildi. Ayarlardan açmanız gerekiyor.');
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('Konum izni hatası: $e');
      return false;
    }
  }

  /// Mevcut konumu al
  /// [accuracy] konum doğruluğu (LocationAccuracy.low, medium, high, best)
  Future<Position?> getCurrentLocation({
    LocationAccuracy accuracy = LocationAccuracy.medium,
  }) async {
    try {
      // İzin kontrolü
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        return null;
      }

      // Konum servisinin açık olup olmadığını kontrol et
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Konum servisi kapalı');
        return null;
      }

      // Konumu al (daha yüksek doğruluk için best kullan)
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high, // Daha yüksek doğruluk
          timeLimit: Duration(seconds: 15), // Daha uzun timeout
        ),
      );

      debugPrint(
          '📍 Konum alındı: Lat=${position.latitude}, Lon=${position.longitude}, Accuracy=${position.accuracy}m');

      return position;
    } catch (e) {
      debugPrint('Konum alma hatası: $e');
      return null;
    }
  }

  /// Son bilinen konumu al (daha hızlı)
  Future<Position?> getLastKnownLocation() async {
    try {
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        return null;
      }

      final position = await Geolocator.getLastKnownPosition();
      return position;
    } catch (e) {
      debugPrint('Son bilinen konum alma hatası: $e');
      return null;
    }
  }

  /// Konum değişikliklerini dinle
  Stream<Position> watchPosition({
    LocationAccuracy accuracy = LocationAccuracy.medium,
    int distanceFilter = 10, // Metre cinsinden minimum mesafe
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      ),
    );
  }

  /// İki konum arasındaki mesafeyi hesapla (kilometre)
  double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }

  /// Konum izninin durumunu kontrol et
  Future<LocationPermissionStatus> getPermissionStatus() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.windows) {
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        return serviceEnabled ? LocationPermissionStatus.granted : LocationPermissionStatus.denied;
      }

      final permission = await Geolocator.checkPermission();
      switch (permission) {
        case LocationPermission.denied:
          return LocationPermissionStatus.denied;
        case LocationPermission.deniedForever:
          return LocationPermissionStatus.deniedForever;
        case LocationPermission.whileInUse:
        case LocationPermission.always:
          return LocationPermissionStatus.granted;
        case LocationPermission.unableToDetermine:
          return LocationPermissionStatus.denied;
      }
    } catch (e) {
      debugPrint('İzin durumu kontrol hatası: $e');
      return LocationPermissionStatus.denied;
    }
  }
}

/// Konum izni durumları
enum LocationPermissionStatus {
  granted,
  denied,
  deniedForever,
}
