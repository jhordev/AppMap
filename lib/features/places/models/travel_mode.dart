import 'package:flutter/material.dart';

/// Enum que define los modos de transporte disponibles
enum TravelMode {
  walking,
  bicycling,
  motorcycle,
  driving,
}

/// Extensión para agregar propiedades útiles a TravelMode
extension TravelModeExtension on TravelMode {
  /// Nombre para mostrar en la UI
  String get displayName {
    switch (this) {
      case TravelMode.walking:
        return 'Caminata';
      case TravelMode.bicycling:
        return 'Bicicleta';
      case TravelMode.motorcycle:
        return 'Moto';
      case TravelMode.driving:
        return 'Auto';
    }
  }

  /// Icono asociado al modo de transporte
  IconData get icon {
    switch (this) {
      case TravelMode.walking:
        return Icons.directions_walk;
      case TravelMode.bicycling:
        return Icons.directions_bike;
      case TravelMode.motorcycle:
        return Icons.two_wheeler;
      case TravelMode.driving:
        return Icons.directions_car;
    }
  }

  /// Color asociado al modo de transporte
  Color get color {
    switch (this) {
      case TravelMode.walking:
        return const Color(0xFF4CAF50); // Verde
      case TravelMode.bicycling:
        return const Color(0xFF2196F3); // Azul
      case TravelMode.motorcycle:
        return const Color(0xFFFF9800); // Naranja
      case TravelMode.driving:
        return const Color(0xFFF44336); // Rojo
    }
  }

  /// Valor para usar en las APIs (Google Maps, OSRM, etc.)
  String get apiValue {
    switch (this) {
      case TravelMode.walking:
        return 'walking';
      case TravelMode.bicycling:
        return 'bicycling';
      case TravelMode.motorcycle:
        return 'motorcycle';
      case TravelMode.driving:
        return 'driving';
    }
  }

  /// Velocidad promedio en km/h
  double get averageSpeed {
    switch (this) {
      case TravelMode.walking:
        return 5.0;
      case TravelMode.bicycling:
        return 12.0;
      case TravelMode.motorcycle:
        return 35.0;
      case TravelMode.driving:
        return 30.0;
    }
  }
}
