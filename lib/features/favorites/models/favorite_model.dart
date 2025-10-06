import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class FavoriteModel {
  final String id;
  final String userId;
  final String placeId;
  final String placeName;
  final String placeAddress;
  final LatLng placeLocation;
  final String placeCategory;
  final double? placeRating;
  final String? placePhotoUrl;
  final DateTime addedAt;

  const FavoriteModel({
    required this.id,
    required this.userId,
    required this.placeId,
    required this.placeName,
    required this.placeAddress,
    required this.placeLocation,
    required this.placeCategory,
    this.placeRating,
    this.placePhotoUrl,
    required this.addedAt,
  });

  factory FavoriteModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data()!;
    return FavoriteModel(
      id: snapshot.id,
      userId: data['userId'] ?? '',
      placeId: data['placeId'] ?? '',
      placeName: data['placeName'] ?? '',
      placeAddress: data['placeAddress'] ?? '',
      placeLocation: LatLng(
        data['placeLocation']['lat']?.toDouble() ?? 0.0,
        data['placeLocation']['lng']?.toDouble() ?? 0.0,
      ),
      placeCategory: data['placeCategory'] ?? '',
      placeRating: data['placeRating']?.toDouble(),
      placePhotoUrl: data['placePhotoUrl'],
      addedAt: (data['addedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'placeId': placeId,
      'placeName': placeName,
      'placeAddress': placeAddress,
      'placeLocation': {
        'lat': placeLocation.latitude,
        'lng': placeLocation.longitude,
      },
      'placeCategory': placeCategory,
      'placeRating': placeRating,
      'placePhotoUrl': placePhotoUrl,
      'addedAt': Timestamp.fromDate(addedAt),
    };
  }

  factory FavoriteModel.fromPlace({
    required String userId,
    required String placeId,
    required String placeName,
    required String placeAddress,
    required LatLng placeLocation,
    required String placeCategory,
    double? placeRating,
    String? placePhotoUrl,
  }) {
    return FavoriteModel(
      id: '',
      userId: userId,
      placeId: placeId,
      placeName: placeName,
      placeAddress: placeAddress,
      placeLocation: placeLocation,
      placeCategory: placeCategory,
      placeRating: placeRating,
      placePhotoUrl: placePhotoUrl,
      addedAt: DateTime.now(),
    );
  }
}
