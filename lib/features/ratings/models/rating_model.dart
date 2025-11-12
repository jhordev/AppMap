import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo que representa una calificación de un usuario para un lugar
class RatingModel {
  final String id;
  final String placeId;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final int rating; // 1-5 estrellas
  final String? review; // Opinión del usuario (max 200 caracteres)
  final DateTime createdAt;
  final DateTime updatedAt;

  const RatingModel({
    required this.id,
    required this.placeId,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.rating,
    this.review,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Crea un RatingModel desde un documento de Firestore
  factory RatingModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data()!;
    return RatingModel(
      id: snapshot.id,
      placeId: data['placeId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Usuario',
      userPhotoUrl: data['userPhotoUrl'],
      rating: data['rating'] ?? 0,
      review: data['review'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Convierte el modelo a Map para guardar en Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'placeId': placeId,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'rating': rating,
      'review': review,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Crea una copia del modelo con los campos especificados actualizados
  RatingModel copyWith({
    String? id,
    String? placeId,
    String? userId,
    String? userName,
    String? userPhotoUrl,
    int? rating,
    String? review,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RatingModel(
      id: id ?? this.id,
      placeId: placeId ?? this.placeId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      rating: rating ?? this.rating,
      review: review ?? this.review,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Valida que el rating esté en el rango correcto
  bool isValid() {
    return rating >= 1 && rating <= 5;
  }

  /// Valida que el review no exceda los 200 caracteres
  bool isReviewValid() {
    if (review == null) return true;
    return review!.length <= 200;
  }
}
