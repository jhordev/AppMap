import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo que representa las estadísticas de calificaciones de un lugar
class RatingStatsModel {
  final String placeId;
  final double averageRating;
  final int totalRatings;
  final Map<int, int> ratingsDistribution; // {1: 5, 2: 3, 3: 10, 4: 20, 5: 15}
  final DateTime lastUpdated;

  const RatingStatsModel({
    required this.placeId,
    required this.averageRating,
    required this.totalRatings,
    required this.ratingsDistribution,
    required this.lastUpdated,
  });

  /// Crea un RatingStatsModel desde un documento de Firestore
  factory RatingStatsModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();

    if (data == null) {
      // Si no hay datos, retornar estadísticas vacías
      return RatingStatsModel.empty(snapshot.id);
    }

    return RatingStatsModel(
      placeId: snapshot.id,
      averageRating: (data['averageRating'] ?? 0.0).toDouble(),
      totalRatings: data['totalRatings'] ?? 0,
      ratingsDistribution: Map<int, int>.from(
        data['ratingsDistribution'] ?? {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
      ),
      lastUpdated: data['lastUpdated'] != null
          ? (data['lastUpdated'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Crea estadísticas vacías para un lugar
  factory RatingStatsModel.empty(String placeId) {
    return RatingStatsModel(
      placeId: placeId,
      averageRating: 0.0,
      totalRatings: 0,
      ratingsDistribution: {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
      lastUpdated: DateTime.now(),
    );
  }

  /// Convierte el modelo a Map para guardar en Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'averageRating': averageRating,
      'totalRatings': totalRatings,
      'ratingsDistribution': ratingsDistribution,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  /// Obtiene el porcentaje de una calificación específica
  double getPercentage(int rating) {
    if (totalRatings == 0) return 0.0;
    final count = ratingsDistribution[rating] ?? 0;
    return (count / totalRatings) * 100;
  }

  /// Verifica si hay calificaciones
  bool get hasRatings => totalRatings > 0;

  /// Obtiene la calificación más común
  int? get mostCommonRating {
    if (!hasRatings) return null;

    int maxRating = 1;
    int maxCount = ratingsDistribution[1] ?? 0;

    for (int i = 2; i <= 5; i++) {
      final count = ratingsDistribution[i] ?? 0;
      if (count > maxCount) {
        maxCount = count;
        maxRating = i;
      }
    }

    return maxCount > 0 ? maxRating : null;
  }

  /// Crea una copia del modelo con los campos especificados actualizados
  RatingStatsModel copyWith({
    String? placeId,
    double? averageRating,
    int? totalRatings,
    Map<int, int>? ratingsDistribution,
    DateTime? lastUpdated,
  }) {
    return RatingStatsModel(
      placeId: placeId ?? this.placeId,
      averageRating: averageRating ?? this.averageRating,
      totalRatings: totalRatings ?? this.totalRatings,
      ratingsDistribution: ratingsDistribution ?? this.ratingsDistribution,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
