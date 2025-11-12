import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/rating_model.dart';
import '../models/rating_stats_model.dart';
import '../services/ratings_service.dart';

/// Provider del servicio de calificaciones
final ratingsServiceProvider = Provider<RatingsService>((ref) {
  return RatingsService();
});

/// Clase para pasar parámetros al provider de calificación de usuario
class UserRatingParams {
  final String userId;
  final String placeId;

  const UserRatingParams({
    required this.userId,
    required this.placeId,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserRatingParams &&
        other.userId == userId &&
        other.placeId == placeId;
  }

  @override
  int get hashCode => userId.hashCode ^ placeId.hashCode;
}

/// Provider para obtener la calificación de un usuario para un lugar específico
final userRatingProvider = FutureProvider.family<RatingModel?, UserRatingParams>(
  (ref, params) async {
    final service = ref.read(ratingsServiceProvider);
    return service.getUserRating(params.userId, params.placeId);
  },
);

/// Provider para obtener todas las calificaciones de un lugar (Stream)
final placeRatingsStreamProvider = StreamProvider.family<List<RatingModel>, String>(
  (ref, placeId) {
    final service = ref.read(ratingsServiceProvider);
    return service.getPlaceRatingsStream(placeId);
  },
);

/// Provider para obtener todas las calificaciones de un lugar (Future)
final placeRatingsFutureProvider = FutureProvider.family<List<RatingModel>, String>(
  (ref, placeId) async {
    final service = ref.read(ratingsServiceProvider);
    return service.getPlaceRatings(placeId);
  },
);

/// Provider para obtener las estadísticas de un lugar (Stream)
final placeStatsStreamProvider = StreamProvider.family<RatingStatsModel, String>(
  (ref, placeId) {
    final service = ref.read(ratingsServiceProvider);
    return service.getPlaceStatsStream(placeId);
  },
);

/// Provider para obtener las estadísticas de un lugar (Future)
final placeStatsFutureProvider = FutureProvider.family<RatingStatsModel, String>(
  (ref, placeId) async {
    final service = ref.read(ratingsServiceProvider);
    return service.getPlaceStats(placeId);
  },
);

/// Provider para obtener las últimas calificaciones de un lugar
class RecentRatingsParams {
  final String placeId;
  final int limit;

  const RecentRatingsParams({
    required this.placeId,
    this.limit = 5,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RecentRatingsParams &&
        other.placeId == placeId &&
        other.limit == limit;
  }

  @override
  int get hashCode => placeId.hashCode ^ limit.hashCode;
}

final recentRatingsProvider = FutureProvider.family<List<RatingModel>, RecentRatingsParams>(
  (ref, params) async {
    final service = ref.read(ratingsServiceProvider);
    return service.getRecentRatings(params.placeId, limit: params.limit);
  },
);

/// Provider para verificar si un usuario ya calificó un lugar
final hasUserRatedProvider = FutureProvider.family<bool, UserRatingParams>(
  (ref, params) async {
    final service = ref.read(ratingsServiceProvider);
    return service.hasUserRated(params.userId, params.placeId);
  },
);
