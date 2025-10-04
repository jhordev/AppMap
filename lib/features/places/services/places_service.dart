import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/place_model.dart';
import '../widgets/category_bottom_sheet.dart';
import '../../../config/api_config.dart';
import '../../../utils/logger.dart';

class PlacesService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api';
  static const String _apiKey = ApiConfig.googlePlacesApiKey;

  static const Map<PlaceCategory, String> _categoryToType = {
    PlaceCategory.touristAttraction: 'tourist_attraction',
    PlaceCategory.restaurant: 'restaurant',
    PlaceCategory.hotel: 'lodging',
    PlaceCategory.gasStation: 'gas_station',
    PlaceCategory.hospital: 'hospital',
    PlaceCategory.bank: 'bank',
  };

  Future<List<PlaceModel>> searchNearbyPlaces({
    required LatLng location,
    required PlaceCategory category,
    double radius = 5000, // 5km radius
  }) async {
    try {
      final type = _categoryToType[category] ?? 'tourist_attraction';
      final url = Uri.parse(
        '$_baseUrl/place/nearbysearch/json'
        '?location=${location.latitude},${location.longitude}'
        '&radius=$radius'
        '&type=$type'
        '&key=$_apiKey',
      );

      Logger.info('Searching places for category: ${category.displayName}');
      Logger.info('API URL: ${url.toString().replaceAll(_apiKey, '***')}');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final status = data['status'];

        Logger.info('API Response status: $status');

        if (status == 'OK') {
          final results = data['results'] as List<dynamic>;
          Logger.info('Found ${results.length} places');

          return results
              .map((result) => PlaceModel.fromMap(result))
              .toList();
        } else if (status == 'ZERO_RESULTS') {
          Logger.warning('No places found for this location and category');
          return [];
        } else {
          Logger.error('API Error: $status');
          throw Exception('API Error: $status');
        }
      } else {
        Logger.error('HTTP Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load places: ${response.statusCode}');
      }
    } catch (e) {
      Logger.error('Error searching places: $e');
      throw Exception('Error searching places: $e');
    }
  }

  Future<List<PlaceModel>> searchPlacesByText({
    required String query,
    required LatLng location,
    double radius = 10000,
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/place/textsearch/json'
        '?query=$query'
        '&location=${location.latitude},${location.longitude}'
        '&radius=$radius'
        '&key=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List<dynamic>;

        return results
            .map((result) => PlaceModel.fromMap(result))
            .toList();
      } else {
        throw Exception('Failed to search places: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching places by text: $e');
    }
  }

  Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/place/details/json'
        '?place_id=$placeId'
        '&fields=name,rating,formatted_phone_number,formatted_address,opening_hours,website,reviews'
        '&key=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['result'];
      } else {
        throw Exception('Failed to get place details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting place details: $e');
    }
  }

  Future<Map<String, dynamic>> getDirections({
    required LatLng origin,
    required LatLng destination,
    String travelMode = 'driving',
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/directions/json'
        '?origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&mode=$travelMode'
        '&key=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get directions: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting directions: $e');
    }
  }
}