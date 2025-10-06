import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../places/models/place_model.dart';
import '../../maps/services/location_service.dart';
import '../../places/services/distance_service.dart';
import '../../../utils/logger.dart';

class NavigationView extends ConsumerStatefulWidget {
  final PlaceModel destination;
  final LatLng origin;
  final Map<String, dynamic> routeData;

  const NavigationView({
    super.key,
    required this.destination,
    required this.origin,
    required this.routeData,
  });

  @override
  ConsumerState<NavigationView> createState() => _NavigationViewState();
}

class _NavigationViewState extends ConsumerState<NavigationView> {
  GoogleMapController? _mapController;
  final LocationService _locationService = LocationService();
  LatLng? _currentLocation;
  double _currentBearing = 0.0;
  Timer? _locationUpdateTimer;
  bool _isMapReady = false;

  // Datos de la ruta que NO cambian durante la navegación
  late final String _initialDistance;
  late final String _initialDuration;
  late final Set<Polyline> _polylines;
  late final Set<Marker> _markers;

  // Distancia actual para detectar llegada
  double _currentDistanceInMeters = 0.0;

  @override
  void initState() {
    super.initState();
    _currentLocation = widget.origin;
    _initializeRouteData();
    _createPolyline();
    _createMarkers();
    _startLocationUpdates();
  }

  void _initializeRouteData() {
    // Guardar los datos iniciales de la ruta - ESTOS NO CAMBIAN
    _initialDistance = widget.routeData['distanceText'] ?? '';
    _initialDuration = widget.routeData['durationText'] ?? '';

    if (widget.routeData['distance'] != null) {
      _currentDistanceInMeters = (widget.routeData['distance'] as num).toDouble();
    }
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _startLocationUpdates() {
    // Actualizar ubicación cada 5 segundos (más espaciado)
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      final newLocation = await _locationService.getCurrentLocation();
      if (newLocation != null && mounted) {
        final oldLocation = _currentLocation;

        // Calcular bearing solo si hay movimiento significativo
        double newBearing = _currentBearing;
        if (oldLocation != null) {
          final distance = DistanceService.calculateDistance(
            origin: oldLocation,
            destination: newLocation,
          );
          // Solo actualizar bearing si se movió más de 10 metros
          if (distance > 10) {
            newBearing = _calculateBearing(oldLocation, newLocation);
          }
        }

        // Actualizar estado solo si cambió significativamente
        if (_shouldUpdateState(newLocation, newBearing)) {
          _currentLocation = newLocation;
          _currentBearing = newBearing;

          // Calcular distancia actual solo para detectar llegada
          _currentDistanceInMeters = DistanceService.calculateDistance(
            origin: newLocation,
            destination: widget.destination.location,
          );

          // Actualizar cámara suavemente solo si el mapa está listo
          if (_isMapReady && _mapController != null) {
            _mapController!.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: newLocation,
                  zoom: 18.0,
                  bearing: _currentBearing,
                  tilt: 45.0,
                ),
              ),
            );
          }

          // Verificar si llegamos al destino (menos de 50 metros)
          if (_currentDistanceInMeters < 50) {
            _arrivedAtDestination();
          }
        }
      }
    });
  }

  bool _shouldUpdateState(LatLng newLocation, double newBearing) {
    // Solo actualizar si hay cambio significativo
    if (_currentLocation == null) return true;

    final distance = DistanceService.calculateDistance(
      origin: _currentLocation!,
      destination: newLocation,
    );

    final bearingDiff = (newBearing - _currentBearing).abs();

    // Actualizar si se movió más de 5 metros o el bearing cambió más de 10 grados
    return distance > 5 || bearingDiff > 10;
  }

  double _calculateBearing(LatLng start, LatLng end) {
    final lat1 = start.latitude * math.pi / 180;
    final lat2 = end.latitude * math.pi / 180;
    final dLng = (end.longitude - start.longitude) * math.pi / 180;

    final y = math.sin(dLng) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);

    final bearing = math.atan2(y, x) * 180 / math.pi;
    return (bearing + 360) % 360;
  }

  void _createPolyline() {
    final polylinePoints = widget.routeData['polylinePoints'] as List<dynamic>?;

    if (polylinePoints != null && polylinePoints.isNotEmpty) {
      final points = polylinePoints.map((point) {
        return LatLng(point['lat'], point['lng']);
      }).toList();

      _polylines = {
        Polyline(
          polylineId: const PolylineId('navigation_route'),
          points: points,
          color: Colors.blue,
          width: 6,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      };
    }
  }

  void _createMarkers() {
    _markers = {
      Marker(
        markerId: const MarkerId('destination'),
        position: widget.destination.location,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: widget.destination.name,
          snippet: 'Destino',
        ),
      ),
    };
  }

  void _arrivedAtDestination() {
    _locationUpdateTimer?.cancel();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: Colors.green, size: 32),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('¡Has llegado!')),
          ],
        ),
        content: Text('Has llegado a ${widget.destination.name}'),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop(); // Cerrar diálogo
              Navigator.of(context).pop(); // Cerrar navegación
            },
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Mapa con perspectiva 3D
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.origin,
              zoom: 18.0,
              bearing: _currentBearing,
              tilt: 45.0,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              // Marcar el mapa como listo después de un delay
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  setState(() {
                    _isMapReady = true;
                  });
                }
              });
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            compassEnabled: false,
            mapToolbarEnabled: false,
            polylines: _polylines,
            markers: _markers,
            zoomControlsEnabled: false,
          ),

          // Panel superior con información de navegación
          SafeArea(
            child: Column(
              children: [
                _buildNavigationPanel(),
                const Spacer(),
                _buildBottomControls(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationPanel() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header con destino
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.navigation,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Navegando hacia',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      Text(
                        widget.destination.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  onPressed: _showExitDialog,
                ),
              ],
            ),
          ),

          // Información de distancia y tiempo (constantes durante la navegación)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoCard(
                  icon: Icons.straighten,
                  label: 'Distancia total',
                  value: _initialDistance.isEmpty ? '...' : _initialDistance,
                  color: Colors.blue,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                _buildInfoCard(
                  icon: Icons.access_time,
                  label: 'Tiempo estimado',
                  value: _initialDuration.isEmpty ? '...' : _initialDuration,
                  color: Colors.orange,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomControls() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Botón de recentrar
          FloatingActionButton(
            heroTag: 'recenter_btn',
            onPressed: () {
              if (_currentLocation != null && _mapController != null) {
                _mapController!.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: _currentLocation!,
                      zoom: 18.0,
                      bearing: _currentBearing,
                      tilt: 45.0,
                    ),
                  ),
                );
              }
            },
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(width: 12),
          // Botón de vista normal/3D
          FloatingActionButton(
            heroTag: 'view_btn',
            onPressed: () {
              if (_currentLocation != null && _mapController != null) {
                _mapController!.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: _currentLocation!,
                      zoom: 18.0,
                      bearing: 0,
                      tilt: 0,
                    ),
                  ),
                );
              }
            },
            child: const Icon(Icons.threed_rotation),
          ),
        ],
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Salir de navegación'),
        content: const Text('¿Estás seguro de que quieres detener la navegación?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              Navigator.pop(context); // Cerrar diálogo
              Navigator.pop(context); // Cerrar navegación
            },
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }
}
