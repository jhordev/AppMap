import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../config/api_config.dart';

class PlaceModel {
  final String id;
  final String name;
  final String address;
  final LatLng location;
  final double? rating;
  final int? priceLevel;
  final String? photoUrl;
  final bool isOpen;
  final String category;

  const PlaceModel({
    required this.id,
    required this.name,
    required this.address,
    required this.location,
    this.rating,
    this.priceLevel,
    this.photoUrl,
    required this.isOpen,
    required this.category,
  });

  factory PlaceModel.fromMap(Map<String, dynamic> map, {String? categoryOverride}) {
    final geometry = map['geometry'];
    final location = geometry['location'];

    return PlaceModel(
      id: map['place_id'] ?? '',
      name: map['name'] ?? '',
      address: map['formatted_address'] ?? map['vicinity'] ?? '',
      location: LatLng(
        location['lat']?.toDouble() ?? 0.0,
        location['lng']?.toDouble() ?? 0.0,
      ),
      rating: map['rating']?.toDouble(),
      priceLevel: map['price_level'],
      photoUrl: _getPhotoUrl(map['photos']),
      isOpen: _getOpenStatus(map['opening_hours']),
      category: categoryOverride ?? _getCategory(map['types']),
    );
  }

  static String? _getPhotoUrl(List<dynamic>? photos) {
    if (photos == null || photos.isEmpty) return null;

    final photo = photos.first;
    final photoReference = photo['photo_reference'];
    if (photoReference == null) return null;

    return 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$photoReference&key=${ApiConfig.googlePlacesApiKey}';
  }

  static bool _getOpenStatus(Map<String, dynamic>? openingHours) {
    if (openingHours == null) return false;
    return openingHours['open_now'] ?? false;
  }

  static String _getCategory(List<dynamic>? types) {
    if (types == null || types.isEmpty) return 'general';

    // Map Google Places types to our categories
    final typeString = types.first.toString();
    switch (typeString) {
      case 'tourist_attraction':
        return 'tourist_attraction';
      case 'restaurant':
      case 'food':
        return 'restaurant';
      case 'lodging':
        return 'hotel';
      case 'gas_station':
        return 'gas_station';
      case 'hospital':
        return 'hospital';
      case 'bank':
        return 'bank';
      default:
        return 'general';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'location': {
        'lat': location.latitude,
        'lng': location.longitude,
      },
      'rating': rating,
      'priceLevel': priceLevel,
      'photoUrl': photoUrl,
      'isOpen': isOpen,
      'category': category,
    };
  }
}