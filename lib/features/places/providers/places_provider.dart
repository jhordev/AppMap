import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/place_model.dart';
import '../models/travel_mode.dart';
import '../services/places_service.dart';
import '../widgets/category_bottom_sheet.dart';

final placesServiceProvider = Provider<PlacesService>((ref) {
  return PlacesService();
});

final selectedCategoryProvider = StateProvider<PlaceCategory?>((ref) {
  return null;
});

final userLocationProvider = StateProvider<LatLng?>((ref) {
  return null;
});

final nearbyPlacesProvider = FutureProvider.family<List<PlaceModel>, PlacesSearchParams>((ref, params) async {
  final placesService = ref.read(placesServiceProvider);
  return await placesService.searchNearbyPlaces(
    location: params.location,
    category: params.category,
    radius: params.radius,
  );
});

final selectedPlaceProvider = StateProvider<PlaceModel?>((ref) {
  return null;
});

/// Provider para el modo de transporte seleccionado por el usuario
/// Por defecto es 'driving' (auto)
final selectedTravelModeProvider = StateProvider<TravelMode>((ref) {
  return TravelMode.driving;
});

final routeProvider = FutureProvider.family<Map<String, dynamic>, RouteParams>((ref, params) async {
  final placesService = ref.read(placesServiceProvider);
  return await placesService.getDirections(
    origin: params.origin,
    destination: params.destination,
    travelMode: params.travelMode,
    placeCategory: params.placeCategory,
  );
});

class PlacesSearchParams {
  final LatLng location;
  final PlaceCategory category;
  final double radius;

  const PlacesSearchParams({
    required this.location,
    required this.category,
    this.radius = 15000,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlacesSearchParams &&
        other.location.latitude == location.latitude &&
        other.location.longitude == location.longitude &&
        other.category == category &&
        other.radius == radius;
  }

  @override
  int get hashCode {
    return location.latitude.hashCode ^
        location.longitude.hashCode ^
        category.hashCode ^
        radius.hashCode;
  }
}

class RouteParams {
  final LatLng origin;
  final LatLng destination;
  final String travelMode;
  final String? placeCategory;

  const RouteParams({
    required this.origin,
    required this.destination,
    this.travelMode = 'driving',
    this.placeCategory,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RouteParams &&
        other.origin.latitude == origin.latitude &&
        other.origin.longitude == origin.longitude &&
        other.destination.latitude == destination.latitude &&
        other.destination.longitude == destination.longitude &&
        other.travelMode == travelMode &&
        other.placeCategory == placeCategory;
  }

  @override
  int get hashCode {
    return origin.latitude.hashCode ^
        origin.longitude.hashCode ^
        destination.latitude.hashCode ^
        destination.longitude.hashCode ^
        travelMode.hashCode ^
        placeCategory.hashCode;
  }
}