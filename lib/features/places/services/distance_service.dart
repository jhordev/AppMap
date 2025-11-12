import 'dart:convert';
import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

/// Servicio propio para calcular distancias y rutas sin depender de Google Directions API
/// Usa OSRM (Open Source Routing Machine) para obtener rutas reales
class DistanceService {
  /// Radio de la Tierra en kilómetros
  static const double _earthRadiusKm = 6371.0;

  /// Calcula la distancia en metros entre dos puntos usando la fórmula de Haversine
  static double calculateDistance({
    required LatLng origin,
    required LatLng destination,
  }) {
    final dLat = _degreesToRadians(destination.latitude - origin.latitude);
    final dLon = _degreesToRadians(destination.longitude - origin.longitude);

    final lat1Rad = _degreesToRadians(origin.latitude);
    final lat2Rad = _degreesToRadians(destination.latitude);

    final a =
        (sin(dLat / 2) * sin(dLat / 2)) +
        (sin(dLon / 2) * sin(dLon / 2)) * cos(lat1Rad) * cos(lat2Rad);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    final distanceKm = _earthRadiusKm * c;
    return distanceKm * 1000; // Retorna en metros
  }

  /// Calcula información de ruta usando OSRM (Open Source Routing Machine)
  ///
  /// Retorna un mapa con:
  /// - distance: distancia en metros
  /// - duration: duración estimada en segundos
  /// - distanceText: distancia formateada (ej: "5.2 km")
  /// - durationText: duración formateada (ej: "15 min")
  /// - polylinePoints: lista de puntos para dibujar la ruta
  /// - encodedPolyline: polyline codificado
  static Future<Map<String, dynamic>> getRouteInfo({
    required LatLng origin,
    required LatLng destination,
    String travelMode = 'driving',
  }) async {
    try {
      // Mapear modo de transporte a perfil OSRM
      final profile = _getOSRMProfile(travelMode);

      // Llamar a OSRM API
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/$profile/'
        '${origin.longitude},${origin.latitude};'
        '${destination.longitude},${destination.latitude}'
        '?overview=full&geometries=polyline',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        if (data['code'] == 'Ok' && data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final route = (data['routes'] as List)[0] as Map<String, dynamic>;
          final distanceInMeters = (route['distance'] as num).toDouble();
          final encodedPolyline = route['geometry'] as String;

          // IMPORTANTE: Siempre recalcular la duración usando nuestras velocidades promedio
          // NO usar la duración de OSRM, porque OSRM no diferencia entre auto y moto
          final durationInSeconds = _estimateDuration(
            distanceInMeters: distanceInMeters,
            travelMode: travelMode,
          );

          // Decodificar polyline
          final polylinePoints = PolylinePoints();
          final decodedPoints = polylinePoints.decodePolyline(encodedPolyline);

          final pointsList = decodedPoints.map((point) => {
            'lat': point.latitude,
            'lng': point.longitude,
          }).toList();

          return {
            'status': 'OK',
            'distance': distanceInMeters,
            'duration': durationInSeconds,
            'distanceText': _formatDistance(distanceInMeters),
            'durationText': _formatDuration(durationInSeconds),
            'polylinePoints': pointsList,
            'encodedPolyline': encodedPolyline,
            'routes': [
              {
                'legs': [
                  {
                    'distance': {
                      'value': distanceInMeters.round(),
                      'text': _formatDistance(distanceInMeters),
                    },
                    'duration': {
                      'value': durationInSeconds,
                      'text': _formatDuration(durationInSeconds),
                    },
                    'start_location': {
                      'lat': origin.latitude,
                      'lng': origin.longitude,
                    },
                    'end_location': {
                      'lat': destination.latitude,
                      'lng': destination.longitude,
                    },
                  }
                ],
              }
            ],
          };
        }
      }

      // Si OSRM falla, usar estimación directa como fallback
      return _getFallbackRouteInfo(origin, destination, travelMode);
    } catch (e) {
      // En caso de error, usar estimación directa
      return _getFallbackRouteInfo(origin, destination, travelMode);
    }
  }

  /// Obtiene el perfil OSRM según el modo de transporte
  static String _getOSRMProfile(String travelMode) {
    switch (travelMode.toLowerCase()) {
      case 'walking':
        return 'foot';
      case 'bicycling':
        return 'bike';
      case 'motorcycle':
      case 'driving':
      case 'transit':
      default:
        return 'car';
    }
  }

  /// Ruta de fallback cuando OSRM no está disponible
  static Map<String, dynamic> _getFallbackRouteInfo(
    LatLng origin,
    LatLng destination,
    String travelMode,
  ) {
    final distanceInMeters = calculateDistance(
      origin: origin,
      destination: destination,
    );

    final durationInSeconds = _estimateDuration(
      distanceInMeters: distanceInMeters,
      travelMode: travelMode,
    );

    // Crear una línea recta simple entre origen y destino
    final pointsList = [
      {'lat': origin.latitude, 'lng': origin.longitude},
      {'lat': destination.latitude, 'lng': destination.longitude},
    ];

    return {
      'status': 'OK',
      'distance': distanceInMeters,
      'duration': durationInSeconds,
      'distanceText': _formatDistance(distanceInMeters),
      'durationText': _formatDuration(durationInSeconds),
      'polylinePoints': pointsList,
      'encodedPolyline': '',
      'routes': [
        {
          'legs': [
            {
              'distance': {
                'value': distanceInMeters.round(),
                'text': _formatDistance(distanceInMeters),
              },
              'duration': {
                'value': durationInSeconds.round(),
                'text': _formatDuration(durationInSeconds),
              },
              'start_location': {
                'lat': origin.latitude,
                'lng': origin.longitude,
              },
              'end_location': {
                'lat': destination.latitude,
                'lng': destination.longitude,
              },
            }
          ],
        }
      ],
    };
  }

  /// Estima la duración del viaje según el modo de transporte
  /// Velocidades promedio realistas considerando condiciones urbanas:
  /// - walking: 5 km/h - velocidad de caminata normal
  /// - bicycling: 12 km/h - bicicleta urbana con tráfico
  /// - motorcycle: 35 km/h - moto en ciudad con tráfico
  /// - driving: 30 km/h - auto en ciudad con tráfico
  /// - transit: 20 km/h - transporte público con paradas
  static int _estimateDuration({
    required double distanceInMeters,
    required String travelMode,
  }) {
    final distanceInKm = distanceInMeters / 1000;
    double averageSpeedKmh;

    switch (travelMode.toLowerCase()) {
      case 'walking':
        // Caminata normal: 5 km/h
        averageSpeedKmh = 5.0;
        break;
      case 'bicycling':
        // Bicicleta urbana: 12 km/h
        averageSpeedKmh = 12.0;
        break;
      case 'motorcycle':
        // Moto en ciudad: 35 km/h
        averageSpeedKmh = 35.0;
        break;
      case 'transit':
        // Transporte público con paradas: 20 km/h
        averageSpeedKmh = 20.0;
        break;
      case 'driving':
      default:
        // Auto en ciudad: 30 km/h
        averageSpeedKmh = 30.0;
        break;
    }

    final durationInHours = distanceInKm / averageSpeedKmh;
    final durationInSeconds = (durationInHours * 3600).round();

    // Agregar tiempo base mínimo (semáforos, arranque, etc.)
    // Para distancias cortas, agregar tiempo base
    int baseTime = 0;
    if (distanceInKm < 1 && travelMode.toLowerCase() != 'walking') {
      baseTime = 30; // 30 segundos adicionales para distancias muy cortas en vehículos
    } else if (distanceInKm < 5 && travelMode.toLowerCase() == 'driving') {
      baseTime = 60; // 1 minuto adicional para autos en distancias cortas (más semáforos)
    }

    return durationInSeconds + baseTime;
  }

  /// Formatea la distancia en texto legible
  static String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    } else {
      final km = meters / 1000;
      return '${km.toStringAsFixed(1)} km';
    }
  }

  /// Formatea la duración en texto legible
  static String _formatDuration(int seconds) {
    if (seconds < 60) {
      return '$seconds seg';
    } else if (seconds < 3600) {
      final minutes = (seconds / 60).round();
      return '$minutes min';
    } else {
      final hours = (seconds / 3600).floor();
      final minutes = ((seconds % 3600) / 60).round();
      if (minutes == 0) {
        return '$hours h';
      }
      return '$hours h $minutes min';
    }
  }

  /// Convierte grados a radianes
  static double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  /// Calcula el rumbo (bearing) entre dos puntos en grados
  /// 0° = Norte, 90° = Este, 180° = Sur, 270° = Oeste
  static double calculateBearing({
    required LatLng origin,
    required LatLng destination,
  }) {
    final lat1 = _degreesToRadians(origin.latitude);
    final lat2 = _degreesToRadians(destination.latitude);
    final dLon = _degreesToRadians(destination.longitude - origin.longitude);

    final y = sin(dLon) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);

    final bearingRad = atan2(y, x);
    final bearingDeg = bearingRad * 180 / pi;

    return (bearingDeg + 360) % 360; // Normalizar a 0-360
  }

  /// Obtiene la dirección cardinal del rumbo
  static String getCardinalDirection(double bearing) {
    const directions = [
      'N', 'NE', 'E', 'SE', 'S', 'SO', 'O', 'NO'
    ];
    final index = ((bearing + 22.5) / 45).floor() % 8;
    return directions[index];
  }
}
