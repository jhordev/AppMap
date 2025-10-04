import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../places/models/place_model.dart';
import '../../../utils/logger.dart';

class EnhancedMapWidget extends ConsumerStatefulWidget {
  final double height;
  final LatLng? initialPosition;
  final double initialZoom;
  final bool showUserLocation;
  final List<PlaceModel>? places;
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

  @override
  void initState() {
    super.initState();
    _updateMarkers();
  }

  @override
  void didUpdateWidget(EnhancedMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.places != widget.places) {
      _updateMarkers();
    }
  }

  void _updateMarkers() {
    if (widget.places == null) {
      setState(() {
        _markers = {};
      });
      return;
    }

    final newMarkers = <Marker>{};

    for (int i = 0; i < widget.places!.length; i++) {
      final place = widget.places![i];
      final marker = Marker(
        markerId: MarkerId(place.id),
        position: place.location,
        icon: _getMarkerIcon(place.category),
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

    setState(() {
      _markers = newMarkers;
    });

    // Adjust camera to show all markers
    if (widget.places!.isNotEmpty && _mapController != null) {
      _fitMarkersInCamera();
    }
  }

  BitmapDescriptor _getMarkerIcon(String category) {
    switch (category) {
      case 'tourist_attraction':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      case 'restaurant':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      case 'hotel':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case 'gas_station':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      case 'hospital':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueMagenta);
      case 'bank':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
      default:
        return BitmapDescriptor.defaultMarker;
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

  void _onTap(LatLng position) {
    Logger.info('Enhanced Map tapped at: ${position.latitude}, ${position.longitude}');
    if (widget.onTap != null) {
      widget.onTap!(position);
    }
  }

  @override
  Widget build(BuildContext context) {
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
            target: widget.initialPosition ?? const LatLng(4.7110, -74.0721),
            zoom: widget.initialZoom,
          ),
          myLocationEnabled: widget.showUserLocation,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: true,
          mapToolbarEnabled: false,
          markers: _markers,
          polylines: widget.polylines ?? {},
          mapType: MapType.normal,
        ),
      ),
    );
  }
}