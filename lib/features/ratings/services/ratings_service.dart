import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rating_model.dart';
import '../models/rating_stats_model.dart';
import '../../../utils/logger.dart';

/// Servicio para gestionar calificaciones de lugares en Firestore
class RatingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _ratingsCollection = 'place_ratings';
  static const String _statsCollection = 'place_rating_stats';

  /// Guarda o actualiza una calificación
  /// Si el usuario ya calificó el lugar, actualiza la calificación existente
  Future<void> saveRating(RatingModel rating) async {
    print('💾💾💾 saveRating CALLED for place: ${rating.placeId}');
    try {
      Logger.info('💾 Saving rating for place: ${rating.placeId}');
      Logger.info('   User: ${rating.userId} (${rating.userName})');
      Logger.info('   Rating: ${rating.rating} stars');
      Logger.info('   Review: ${rating.review ?? "No review"}');

      print('💾 User: ${rating.userId}, Rating: ${rating.rating} stars');

      // Validar rating
      if (!rating.isValid()) {
        print('❌ Invalid rating: ${rating.rating}');
        throw Exception('Rating must be between 1 and 5');
      }

      if (!rating.isReviewValid()) {
        print('❌ Invalid review length');
        throw Exception('Review must be 200 characters or less');
      }

      print('✅ Validation passed');

      // Buscar si ya existe una calificación del usuario para este lugar
      print('🔍 Checking for existing rating...');
      final existingRating = await getUserRating(rating.userId, rating.placeId);

      if (existingRating != null) {
        // Actualizar calificación existente
        print('📝 Updating existing rating: ${existingRating.id}');
        Logger.info('📝 Updating existing rating: ${existingRating.id}');
        await _firestore
            .collection(_ratingsCollection)
            .doc(existingRating.id)
            .update({
          'rating': rating.rating,
          'review': rating.review,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
        print('✅ Rating updated in Firestore');
        Logger.info('✅ Rating updated in Firestore');
      } else {
        // Crear nueva calificación
        print('🆕 Creating new rating');
        Logger.info('🆕 Creating new rating');
        final data = rating.toFirestore();
        Logger.info('📤 Data to save: $data');

        final docRef = await _firestore.collection(_ratingsCollection).add(data);
        print('✅ Rating created with ID: ${docRef.id}');
        Logger.info('✅ Rating created with ID: ${docRef.id}');
      }

      // Actualizar estadísticas del lugar
      print('📊📊📊 About to call _updatePlaceStats...');
      Logger.info('📊 Updating place statistics...');

      await _updatePlaceStats(rating.placeId);

      print('✅✅✅ _updatePlaceStats completed');

      Logger.info('✅ Rating saved successfully');
      print('💾 saveRating COMPLETED successfully');
    } catch (e, stackTrace) {
      print('❌❌❌ Error in saveRating: $e');
      print('Stack trace: $stackTrace');
      Logger.error('❌ Error saving rating: $e');
      throw Exception('Error saving rating: $e');
    }
  }

  /// Obtiene la calificación de un usuario para un lugar específico
  Future<RatingModel?> getUserRating(String userId, String placeId) async {
    try {
      final snapshot = await _firestore
          .collection(_ratingsCollection)
          .where('userId', isEqualTo: userId)
          .where('placeId', isEqualTo: placeId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return RatingModel.fromFirestore(snapshot.docs.first);
    } catch (e) {
      Logger.error('Error getting user rating: $e');
      return null;
    }
  }

  /// Obtiene todas las calificaciones de un lugar (Stream en tiempo real)
  Stream<List<RatingModel>> getPlaceRatingsStream(String placeId) {
    try {
      return _firestore
          .collection(_ratingsCollection)
          .where('placeId', isEqualTo: placeId)
          .snapshots()
          .map((snapshot) {
        Logger.info('📡 Stream update: ${snapshot.docs.length} ratings for $placeId');
        final ratings = snapshot.docs
            .map((doc) => RatingModel.fromFirestore(doc))
            .toList();

        // Ordenar en memoria en lugar de usar orderBy
        ratings.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return ratings;
      }).handleError((error) {
        Logger.error('❌ Error in ratings stream: $error');
        return <RatingModel>[];
      });
    } catch (e) {
      Logger.error('❌ Error creating ratings stream: $e');
      return Stream.value([]);
    }
  }

  /// Obtiene todas las calificaciones de un lugar (Future único)
  Future<List<RatingModel>> getPlaceRatings(String placeId) async {
    try {
      Logger.info('🔍 Getting ratings for place: $placeId');

      // Primero intentar sin orderBy para evitar problemas de índice
      final snapshot = await _firestore
          .collection(_ratingsCollection)
          .where('placeId', isEqualTo: placeId)
          .get();

      Logger.info('📦 Retrieved ${snapshot.docs.length} documents from Firestore');

      final ratings = snapshot.docs
          .map((doc) => RatingModel.fromFirestore(doc))
          .toList();

      // Ordenar en memoria
      ratings.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      Logger.info('✅ Returning ${ratings.length} ratings');

      return ratings;
    } catch (e) {
      Logger.error('❌ Error getting place ratings: $e');
      return [];
    }
  }

  /// Obtiene las estadísticas de calificaciones de un lugar
  Future<RatingStatsModel> getPlaceStats(String placeId) async {
    try {
      final snapshot = await _firestore
          .collection(_statsCollection)
          .doc(placeId)
          .get();

      if (!snapshot.exists) {
        // Si no existen estadísticas, retornar estadísticas vacías
        return RatingStatsModel.empty(placeId);
      }

      return RatingStatsModel.fromFirestore(snapshot);
    } catch (e) {
      Logger.error('Error getting place stats: $e');
      return RatingStatsModel.empty(placeId);
    }
  }

  /// Obtiene las estadísticas de calificaciones de un lugar (Stream)
  Stream<RatingStatsModel> getPlaceStatsStream(String placeId) {
    try {
      return _firestore
          .collection(_statsCollection)
          .doc(placeId)
          .snapshots()
          .map((snapshot) {
        if (!snapshot.exists) {
          return RatingStatsModel.empty(placeId);
        }
        return RatingStatsModel.fromFirestore(snapshot);
      }).handleError((error) {
        Logger.error('Error in stats stream: $error');
        return RatingStatsModel.empty(placeId);
      });
    } catch (e) {
      Logger.error('Error creating stats stream: $e');
      return Stream.value(RatingStatsModel.empty(placeId));
    }
  }

  /// Elimina una calificación
  Future<void> deleteRating(String ratingId, String placeId) async {
    try {
      Logger.info('Deleting rating: $ratingId');

      await _firestore.collection(_ratingsCollection).doc(ratingId).delete();

      // Actualizar estadísticas
      await _updatePlaceStats(placeId);

      Logger.info('Rating deleted successfully');
    } catch (e) {
      Logger.error('Error deleting rating: $e');
      throw Exception('Error deleting rating: $e');
    }
  }

  /// Actualiza las estadísticas de un lugar
  /// Se ejecuta automáticamente al crear, actualizar o eliminar una calificación
  Future<void> _updatePlaceStats(String placeId) async {
    print('🔄🔄🔄 _updatePlaceStats CALLED for place: $placeId');
    Logger.info('🔄 Updating stats for place: $placeId');

    try {
      // Obtener todas las calificaciones del lugar
      print('📥 About to call getPlaceRatings...');
      final ratings = await getPlaceRatings(placeId);
      print('📝📝📝 Found ${ratings.length} ratings for place $placeId');
      Logger.info('📝 Found ${ratings.length} ratings for place $placeId');

      if (ratings.isEmpty) {
        // Si no hay calificaciones, crear estadísticas vacías
        print('⚠️ No ratings found, creating empty stats');
        Logger.info('⚠️ No ratings found, creating empty stats');

        final emptyStats = RatingStatsModel.empty(placeId);
        final emptyStatsData = emptyStats.toFirestore();
        print('📤 Empty stats data: $emptyStatsData');

        await _firestore.collection(_statsCollection).doc(placeId).set(emptyStatsData);
        print('✅ Empty stats created for $placeId');
        Logger.info('✅ Empty stats created for $placeId');
        return;
      }

      // Calcular estadísticas
      final totalRatings = ratings.length;
      final sumRatings = ratings.fold<int>(0, (total, rating) => total + rating.rating);
      final averageRating = sumRatings / totalRatings;

      print('📊📊📊 Calculated: total=$totalRatings, sum=$sumRatings, avg=${averageRating.toStringAsFixed(2)}');
      Logger.info('📊 Calculated: total=$totalRatings, sum=$sumRatings, avg=${averageRating.toStringAsFixed(2)}');

      // Calcular distribución
      final distribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
      for (final rating in ratings) {
        distribution[rating.rating] = (distribution[rating.rating] ?? 0) + 1;
      }

      print('📈 Distribution: $distribution');
      Logger.info('📈 Distribution: $distribution');

      // Crear modelo de estadísticas
      final stats = RatingStatsModel(
        placeId: placeId,
        averageRating: averageRating,
        totalRatings: totalRatings,
        ratingsDistribution: distribution,
        lastUpdated: DateTime.now(),
      );

      print('📤 About to save stats to Firestore...');
      print('   Collection: $_statsCollection');
      print('   Document ID: $placeId');

      final statsData = stats.toFirestore();
      print('   Data: $statsData');

      // Guardar en Firestore con manejo de errores específico
      try {
        await _firestore
            .collection(_statsCollection)
            .doc(placeId)
            .set(statsData);
        print('✅✅✅ Stats saved to Firestore successfully!');
      } catch (firestoreError) {
        print('❌❌❌ FIRESTORE ERROR: $firestoreError');
        Logger.error('Firestore set error: $firestoreError');
        rethrow;
      }

      print('✅ Stats updated successfully: avg=${averageRating.toStringAsFixed(1)}, total=$totalRatings');
      Logger.info('✅ Stats updated successfully: avg=${averageRating.toStringAsFixed(1)}, total=$totalRatings');
    } catch (e, stackTrace) {
      print('❌❌❌ Error updating place stats: $e');
      print('Stack trace: $stackTrace');
      Logger.error('❌ Error updating place stats: $e');
      // No lanzar excepción para no afectar el flujo principal
    }
  }

  /// Verifica si un usuario ya calificó un lugar
  Future<bool> hasUserRated(String userId, String placeId) async {
    try {
      final rating = await getUserRating(userId, placeId);
      return rating != null;
    } catch (e) {
      Logger.error('Error checking if user rated: $e');
      return false;
    }
  }

  /// Obtiene el conteo total de calificaciones de un lugar
  Future<int> getRatingsCount(String placeId) async {
    try {
      final snapshot = await _firestore
          .collection(_ratingsCollection)
          .where('placeId', isEqualTo: placeId)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      Logger.error('Error getting ratings count: $e');
      return 0;
    }
  }

  /// Obtiene las últimas N calificaciones de un lugar
  Future<List<RatingModel>> getRecentRatings(String placeId, {int limit = 5}) async {
    try {
      Logger.info('🔍 Getting recent ratings for place: $placeId (limit: $limit)');

      // Obtener todas sin orderBy
      final snapshot = await _firestore
          .collection(_ratingsCollection)
          .where('placeId', isEqualTo: placeId)
          .get();

      Logger.info('📦 Retrieved ${snapshot.docs.length} documents for recent ratings');

      final ratings = snapshot.docs
          .map((doc) => RatingModel.fromFirestore(doc))
          .toList();

      // Ordenar en memoria y tomar solo los primeros N
      ratings.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final result = ratings.take(limit).toList();

      Logger.info('✅ Returning ${result.length} recent ratings');

      return result;
    } catch (e) {
      Logger.error('❌ Error getting recent ratings: $e');
      return [];
    }
  }
}
