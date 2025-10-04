import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import '../../../utils/logger.dart';

class MapWidget extends ConsumerStatefulWidget {
  final double height;
  final LatLng? initialPosition;
  final double initialZoom;
  final bool showUserLocation;
  final Set<Marker>? markers;
  final Function(LatLng)? onTap;
  final Function(GoogleMapController)? onMapCreated;

  const MapWidget({
    super.key,
    this.height = 400,
    this.initialPosition,
    this.initialZoom = 14.0,
    this.showUserLocation = true,
    this.markers,
    this.onTap,
    this.onMapCreated,
  });

  @override
  ConsumerState<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends ConsumerState<MapWidget> {
  GoogleMapController? _mapController;
  Location _location = Location();
  LatLng? _currentPosition;
  bool _loading = true;

  // Default position (Bogotá, Colombia)
  static const LatLng _defaultPosition = LatLng(4.7110, -74.0721);

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      Logger.info('Initializing map location');

      if (widget.initialPosition != null) {
        setState(() {
          _currentPosition = widget.initialPosition;
          _loading = false;
        });
        return;
      }

      if (!widget.showUserLocation) {
        setState(() {
          _currentPosition = _defaultPosition;
          _loading = false;
        });
        return;
      }

      // Check if location services are enabled
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        Logger.warning('Location services are disabled');
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          setState(() {
            _currentPosition = _defaultPosition;
            _loading = false;
          });
          return;
        }
      }

      // Check location permissions
      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          Logger.warning('Location permission denied');
          setState(() {
            _currentPosition = _defaultPosition;
            _loading = false;
          });
          return;
        }
      }

      // Get current location
      try {
        LocationData locationData = await _location.getLocation();
        Logger.info('Got user location: ${locationData.latitude}, ${locationData.longitude}');

        setState(() {
          _currentPosition = LatLng(
            locationData.latitude!,
            locationData.longitude!,
          );
          _loading = false;
        });
      } catch (e) {
        Logger.error('Error getting location: $e');
        setState(() {
          _currentPosition = _defaultPosition;
          _loading = false;
        });
      }
    } catch (e) {
      Logger.error('Error initializing location: $e');
      setState(() {
        _currentPosition = _defaultPosition;
        _loading = false;
      });
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    Logger.info('Google Map created');

    if (widget.onMapCreated != null) {
      widget.onMapCreated!(controller);
    }
  }

  void _onTap(LatLng position) {
    Logger.info('Map tapped at: ${position.latitude}, ${position.longitude}');
    if (widget.onTap != null) {
      widget.onTap!(position);
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Cargando mapa...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GoogleMap(
          onMapCreated: _onMapCreated,
          onTap: _onTap,
          initialCameraPosition: CameraPosition(
            target: _currentPosition!,
            zoom: widget.initialZoom,
          ),
          myLocationEnabled: widget.showUserLocation,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: true,
          mapToolbarEnabled: false,
          markers: widget.markers ?? {},
          mapType: MapType.normal,
        ),
      ),
    );
  }
}