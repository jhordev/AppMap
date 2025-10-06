import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../places/models/place_model.dart';
import '../services/map_marker_service.dart';
import '../../../utils/logger.dart';

class EnhancedMapWidget extends ConsumerStatefulWidget {
  final double height;
  final LatLng? initialPosition;
  final double initialZoom;
  final bool showUserLocation;
  final List<PlaceModel>? places;
  final PlaceModel? selectedPlace;
  final Set<Polyline>? polylines;
  final Function(LatLng)? onTap;
  final Function(GoogleMapController)? onMapCreated;
  final Function(PlaceModel)? onPlaceMarkerTapped;

  const EnhancedMapWidget({
    super.key,
    this.height = 400,
    this.initialPosition,
    this.initialZoom = 14.0,
    this.showUserLocation = true,
    this.places,
    this.selectedPlace,
    this.polylines,
    this.onTap,
    this.onMapCreated,
    this.onPlaceMarkerTapped,
  });

  @override
  ConsumerState<EnhancedMapWidget> createState() => _EnhancedMapWidgetState();
}

class _EnhancedMapWidgetState extends ConsumerState<EnhancedMapWidget> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  double _currentZoom = 14.0;

  @override
  void initState() {
    super.initState();
    _currentZoom = widget.initialZoom;
    _initializeIcons();
    _updateMarkers();
  }

  Future<void> _initializeIcons() async {
    await MapMarkerService.initializeIcons();
    if (mounted) {
      _updateMarkers();
    }
  }

  @override
  void didUpdateWidget(EnhancedMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.places != widget.places || oldWidget.selectedPlace != widget.selectedPlace) {
      _updateMarkers();
    }
  }

  void _updateMarkers({bool shouldFitToBounds = true, double? zoomOverride}) {
    if (!mounted) {
      return;
    }

    final zoomValue = zoomOverride ?? _currentZoom;
    final places = widget.places;
    final selectedPlace = widget.selectedPlace;

    final newMarkers = <Marker>{};

    // Agregar marcadores de lugares de la lista
    if (places != null) {
      for (final place in places) {
        final marker = Marker(
          markerId: MarkerId(place.id),
          position: place.location,
          icon: MapMarkerService.getIconForCategoryString(
            place.category,
            zoom: zoomValue,
          ),
          infoWindow: InfoWindow(
            title: place.name,
            snippet: place.address,
            onTap: () {
              if (widget.onPlaceMarkerTapped != null) {
                widget.onPlaceMarkerTapped!(place);
              }
            },
          ),
          onTap: () {
            if (widget.onPlaceMarkerTapped != null) {
              widget.onPlaceMarkerTapped!(place);
            }
          },
        );
        newMarkers.add(marker);
      }
    }

    // Agregar marcador del lugar seleccionado (si existe y no está ya en la lista)
    if (selectedPlace != null) {
      final isAlreadyInList = places?.any((p) => p.id == selectedPlace.id) ?? false;
      if (!isAlreadyInList) {
        final marker = Marker(
          markerId: MarkerId('selected_${selectedPlace.id}'),
          position: selectedPlace.location,
          icon: MapMarkerService.getIconForCategoryString(
            selectedPlace.category,
            zoom: zoomValue,
          ),
          infoWindow: InfoWindow(
            title: selectedPlace.name,
            snippet: selectedPlace.address,
          ),
        );
        newMarkers.add(marker);
      }
    }

    setState(() {
      _currentZoom = zoomValue;
      _markers = newMarkers;
    });

    if (shouldFitToBounds && places != null && places.isNotEmpty && _mapController != null) {
      _fitMarkersInCamera();
    }
  }

  void _fitMarkersInCamera() {
    if (widget.places == null || widget.places!.isEmpty || _mapController == null) {
      return;
    }

    final bounds = _calculateBounds(widget.places!);
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100.0),
    );
  }

  LatLngBounds _calculateBounds(List<PlaceModel> places) {
    double minLat = places.first.location.latitude;
    double maxLat = places.first.location.latitude;
    double minLng = places.first.location.longitude;
    double maxLng = places.first.location.longitude;

    for (final place in places) {
      minLat = minLat < place.location.latitude ? minLat : place.location.latitude;
      maxLat = maxLat > place.location.latitude ? maxLat : place.location.latitude;
      minLng = minLng < place.location.longitude ? minLng : place.location.longitude;
      maxLng = maxLng > place.location.longitude ? maxLng : place.location.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    Logger.info('Enhanced Map created successfully');

    // Update markers after map is created
    if (widget.places != null && widget.places!.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _fitMarkersInCamera();
      });
    }

    if (widget.onMapCreated != null) {
      widget.onMapCreated!(controller);
    }
  }

  void _onCameraMove(CameraPosition position) {
    final newZoom = position.zoom;

    if ((newZoom - _currentZoom).abs() > 0.25) {
      _updateMarkers(
        shouldFitToBounds: false,
        zoomOverride: newZoom,
      );
    }
  }

  Future<void> _syncZoomWithController() async {
    if (_mapController == null) {
      return;
    }

    final zoom = await _mapController!.getZoomLevel();
    if (!mounted) {
      return;
    }

    if ((zoom - _currentZoom).abs() > 0.1) {
      _updateMarkers(
        shouldFitToBounds: false,
        zoomOverride: zoom,
      );
    }
  }

  void _onCameraIdle() {
    _syncZoomWithController();
  }

  void _onTap(LatLng position) {
    Logger.info('Enhanced Map tapped at: ${position.latitude}, ${position.longitude}');
    if (widget.onTap != null) {
      widget.onTap!(position);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      onMapCreated: _onMapCreated,
      onTap: _onTap,
      onCameraMove: _onCameraMove,
      onCameraIdle: _onCameraIdle,
      initialCameraPosition: CameraPosition(
        target: widget.initialPosition ?? const LatLng(4.7110, -74.0721),
        zoom: widget.initialZoom,
      ),
      myLocationEnabled: widget.showUserLocation,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      markers: _markers,
      polylines: widget.polylines ?? {},
      mapType: MapType.normal,
      compassEnabled: true,
      rotateGesturesEnabled: true,
      scrollGesturesEnabled: true,
      tiltGesturesEnabled: true,
      zoomGesturesEnabled: true,
    );
  }
}