import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/location_service.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final currentLocationProvider = FutureProvider<LatLng?>((ref) async {
  final locationService = ref.read(locationServiceProvider);
  return await locationService.getCurrentLocation();
});

final locationStreamProvider = StreamProvider<LatLng?>((ref) {
  final locationService = ref.read(locationServiceProvider);
  return locationService.locationStream;
});