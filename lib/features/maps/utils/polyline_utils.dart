import 'dart:ui';

import 'package:google_maps_flutter/google_maps_flutter.dart';

class PolylineUtils {
  /// Decode a polyline string into a list of LatLng coordinates
  static List<LatLng> decodePolyline(String polyline) {
    List<LatLng> coordinates = [];
    int index = 0, len = polyline.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      coordinates.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return coordinates;
  }

  /// Create a Polyline from route data
  static Polyline createRoutePolyline(Map<String, dynamic> routeData) {
    final routes = routeData['routes'] as List<dynamic>?;
    if (routes == null || routes.isEmpty) {
      return const Polyline(polylineId: PolylineId('empty'), points: []);
    }

    final route = routes.first;
    final overviewPolyline = route['overview_polyline'];
    if (overviewPolyline == null) {
      return const Polyline(polylineId: PolylineId('empty'), points: []);
    }

    final encodedPolyline = overviewPolyline['points'] as String?;
    if (encodedPolyline == null) {
      return const Polyline(polylineId: PolylineId('empty'), points: []);
    }

    final points = decodePolyline(encodedPolyline);

    return Polyline(
      polylineId: const PolylineId('route'),
      points: points,
      color: const Color(0xFF2196F3),
      width: 4,
      patterns: [],
    );
  }

  /// Get route bounds from route data
  static LatLngBounds? getRouteBounds(Map<String, dynamic> routeData) {
    final routes = routeData['routes'] as List<dynamic>?;
    if (routes == null || routes.isEmpty) {
      return null;
    }

    final route = routes.first;
    final bounds = route['bounds'];
    if (bounds == null) {
      return null;
    }

    final southwest = bounds['southwest'];
    final northeast = bounds['northeast'];

    if (southwest == null || northeast == null) {
      return null;
    }

    return LatLngBounds(
      southwest: LatLng(
        southwest['lat']?.toDouble() ?? 0.0,
        southwest['lng']?.toDouble() ?? 0.0,
      ),
      northeast: LatLng(
        northeast['lat']?.toDouble() ?? 0.0,
        northeast['lng']?.toDouble() ?? 0.0,
      ),
    );
  }
}