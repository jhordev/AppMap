import 'package:location/location.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../utils/logger.dart';

class LocationService {
  final Location _location = Location();

  // Check if location services are available and get current location
  Future<LatLng?> getCurrentLocation() async {
    try {
      Logger.info('Getting current location');

      // Check if location services are enabled
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        Logger.warning('Location services are disabled');
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          Logger.error('Location services could not be enabled');
          return null;
        }
      }

      // Check location permissions
      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          Logger.error('Location permission denied');
          return null;
        }
      }

      // Get current location
      LocationData locationData = await _location.getLocation();

      if (locationData.latitude != null && locationData.longitude != null) {
        Logger.info('Current location: ${locationData.latitude}, ${locationData.longitude}');
        return LatLng(locationData.latitude!, locationData.longitude!);
      }

      return null;
    } catch (e) {
      Logger.error('Error getting current location: $e');
      return null;
    }
  }

  // Stream for location updates
  Stream<LatLng?> get locationStream {
    return _location.onLocationChanged.map((locationData) {
      if (locationData.latitude != null && locationData.longitude != null) {
        return LatLng(locationData.latitude!, locationData.longitude!);
      }
      return null;
    });
  }

  // Check if location permissions are granted
  Future<bool> hasPermissions() async {
    try {
      PermissionStatus permissionGranted = await _location.hasPermission();
      return permissionGranted == PermissionStatus.granted;
    } catch (e) {
      Logger.error('Error checking location permissions: $e');
      return false;
    }
  }

  // Request location permissions
  Future<bool> requestPermissions() async {
    try {
      PermissionStatus permissionGranted = await _location.requestPermission();
      return permissionGranted == PermissionStatus.granted;
    } catch (e) {
      Logger.error('Error requesting location permissions: $e');
      return false;
    }
  }

  // Check if location services are enabled
  Future<bool> isServiceEnabled() async {
    try {
      return await _location.serviceEnabled();
    } catch (e) {
      Logger.error('Error checking location services: $e');
      return false;
    }
  }

  // Request location services
  Future<bool> requestService() async {
    try {
      return await _location.requestService();
    } catch (e) {
      Logger.error('Error requesting location services: $e');
      return false;
    }
  }
}