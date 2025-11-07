import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';

/// Konum servisi provider'ı
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

/// Konum izni durumu provider'ı
final locationPermissionProvider = FutureProvider<LocationPermissionStatus>((ref) async {
  final locationService = ref.watch(locationServiceProvider);
  return await locationService.getPermissionStatus();
});

/// Mevcut konum provider'ı
final currentLocationProvider = FutureProvider<Position?>((ref) async {
  final locationService = ref.watch(locationServiceProvider);
  return await locationService.getCurrentLocation();
});

/// Son bilinen konum provider'ı
final lastKnownLocationProvider = FutureProvider<Position?>((ref) async {
  final locationService = ref.watch(locationServiceProvider);
  return await locationService.getLastKnownLocation();
});
