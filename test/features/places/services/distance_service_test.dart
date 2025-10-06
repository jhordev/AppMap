import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:appmap/features/places/services/distance_service.dart';

void main() {
  group('DistanceService', () {
    test('calculateDistance retorna distancia correcta entre dos puntos', () {
      // Lima, Perú (Plaza de Armas)
      final origin = LatLng(-12.046374, -77.042793);

      // Miraflores, Lima (Parque Kennedy)
      final destination = LatLng(-12.120644, -77.029137);

      final distance = DistanceService.calculateDistance(
        origin: origin,
        destination: destination,
      );

      // La distancia aproximada es ~8.5 km
      expect(distance, greaterThan(8000));
      expect(distance, lessThan(9000));
    });

    test('calculateDistance retorna 0 para el mismo punto', () {
      final point = LatLng(-12.046374, -77.042793);

      final distance = DistanceService.calculateDistance(
        origin: point,
        destination: point,
      );

      expect(distance, equals(0));
    });

    test('getRouteInfo retorna estructura correcta para modo driving', () async {
      final origin = LatLng(-12.046374, -77.042793);
      final destination = LatLng(-12.120644, -77.029137);

      final routeInfo = await DistanceService.getRouteInfo(
        origin: origin,
        destination: destination,
        travelMode: 'driving',
      );

      expect(routeInfo['status'], equals('OK'));
      expect(routeInfo['distance'], isA<double>());
      expect(routeInfo['duration'], isA<int>());
      expect(routeInfo['distanceText'], isA<String>());
      expect(routeInfo['durationText'], isA<String>());
      expect(routeInfo['routes'], isA<List>());
      expect(routeInfo['routes'].length, equals(1));

      final route = routeInfo['routes'][0];
      expect(route['legs'], isA<List>());
      expect(route['legs'].length, equals(1));

      final leg = route['legs'][0];
      expect(leg['distance']['value'], isA<int>());
      expect(leg['distance']['text'], isA<String>());
      expect(leg['duration']['value'], isA<int>());
      expect(leg['duration']['text'], isA<String>());
    });

    test('getRouteInfo calcula duraciones diferentes según modo de transporte', () async {
      final origin = LatLng(-12.046374, -77.042793);
      final destination = LatLng(-12.120644, -77.029137);

      final drivingInfo = await DistanceService.getRouteInfo(
        origin: origin,
        destination: destination,
        travelMode: 'driving',
      );

      final walkingInfo = await DistanceService.getRouteInfo(
        origin: origin,
        destination: destination,
        travelMode: 'walking',
      );

      // Caminar debe tomar más tiempo o igual que conducir
      expect(walkingInfo['duration'], greaterThanOrEqualTo(drivingInfo['duration']));
    });

    test('calculateBearing retorna rumbo correcto', () {
      // Norte de Lima hacia Sur
      final north = LatLng(-12.046374, -77.042793);
      final south = LatLng(-12.120644, -77.042793); // Misma longitud

      final bearing = DistanceService.calculateBearing(
        origin: north,
        destination: south,
      );

      // Debería ser aproximadamente 180° (Sur)
      expect(bearing, greaterThan(170));
      expect(bearing, lessThan(190));
    });

    test('getCardinalDirection retorna dirección correcta', () {
      expect(DistanceService.getCardinalDirection(0), equals('N'));
      expect(DistanceService.getCardinalDirection(45), equals('NE'));
      expect(DistanceService.getCardinalDirection(90), equals('E'));
      expect(DistanceService.getCardinalDirection(135), equals('SE'));
      expect(DistanceService.getCardinalDirection(180), equals('S'));
      expect(DistanceService.getCardinalDirection(225), equals('SO'));
      expect(DistanceService.getCardinalDirection(270), equals('O'));
      expect(DistanceService.getCardinalDirection(315), equals('NO'));
    });

    test('formatDistance muestra metros para distancias cortas', () async {
      final origin = LatLng(-12.046374, -77.042793);
      final destination = LatLng(-12.046500, -77.042793);

      final routeInfo = await DistanceService.getRouteInfo(
        origin: origin,
        destination: destination,
        travelMode: 'walking',
      );

      // Distancia corta debe mostrarse en metros
      expect(routeInfo['distanceText'], contains('m'));
    });

    test('formatDistance muestra kilómetros para distancias largas', () async {
      final origin = LatLng(-12.046374, -77.042793);
      final destination = LatLng(-12.120644, -77.029137);

      final routeInfo = await DistanceService.getRouteInfo(
        origin: origin,
        destination: destination,
        travelMode: 'driving',
      );

      // Distancia larga debe mostrarse en kilómetros
      expect(routeInfo['distanceText'], contains('km'));
    });
  });
}
