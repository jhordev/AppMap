import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/favorite_model.dart';
import '../../../utils/logger.dart';

class FavoritesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'favorites';

  /// Obtiene todos los favoritos de un usuario
  Stream<List<FavoriteModel>> getUserFavoritesStream(String userId) {
    try {
      return _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .snapshots()
          .map((snapshot) {
        final favorites = snapshot.docs
            .map((doc) => FavoriteModel.fromFirestore(doc))
            .toList();

        // Ordenar en memoria por addedAt
        favorites.sort((a, b) => b.addedAt.compareTo(a.addedAt));
        return favorites;
      }).handleError((error) {
        Logger.error('Error in favorites stream: $error');
        return <FavoriteModel>[];
      });
    } catch (e) {
      Logger.error('Error creating favorites stream: $e');
      return Stream.value([]);
    }
  }

  /// Obtiene todos los favoritos de un usuario (futuro único)
  Future<List<FavoriteModel>> getUserFavorites(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .get();

      final favorites = snapshot.docs
          .map((doc) => FavoriteModel.fromFirestore(doc))
          .toList();

      // Ordenar en memoria por addedAt
      favorites.sort((a, b) => b.addedAt.compareTo(a.addedAt));
      return favorites;
    } catch (e) {
      Logger.error('Error getting favorites: $e');
      return [];
    }
  }

  /// Verifica si un lugar está en favoritos
  Future<bool> isFavorite(String userId, String placeId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('placeId', isEqualTo: placeId)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      Logger.error('Error checking favorite: $e');
      return false;
    }
  }

  /// Agrega un lugar a favoritos
  Future<void> addFavorite(FavoriteModel favorite) async {
    try {
      // Verificar si ya existe
      final existing = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: favorite.userId)
          .where('placeId', isEqualTo: favorite.placeId)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        Logger.info('Place already in favorites');
        return;
      }

      // Agregar nuevo favorito
      await _firestore.collection(_collection).add(favorite.toFirestore());
      Logger.info('Favorite added: ${favorite.placeName}');
    } catch (e) {
      Logger.error('Error adding favorite: $e');
      throw Exception('Error adding favorite: $e');
    }
  }

  /// Elimina un lugar de favoritos
  Future<void> removeFavorite(String userId, String placeId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('placeId', isEqualTo: placeId)
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }

      Logger.info('Favorite removed: $placeId');
    } catch (e) {
      Logger.error('Error removing favorite: $e');
      throw Exception('Error removing favorite: $e');
    }
  }

  /// Alterna el estado de favorito (agregar/eliminar)
  Future<void> toggleFavorite(FavoriteModel favorite) async {
    try {
      final isFav = await isFavorite(favorite.userId, favorite.placeId);

      if (isFav) {
        await removeFavorite(favorite.userId, favorite.placeId);
      } else {
        await addFavorite(favorite);
      }
    } catch (e) {
      Logger.error('Error toggling favorite: $e');
      throw Exception('Error toggling favorite: $e');
    }
  }

  /// Obtiene el conteo de favoritos de un usuario
  Future<int> getFavoritesCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      Logger.error('Error getting favorites count: $e');
      return 0;
    }
  }

  /// Elimina todos los favoritos de un usuario
  Future<void> clearAllFavorites(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      Logger.info('All favorites cleared for user: $userId');
    } catch (e) {
      Logger.error('Error clearing favorites: $e');
      throw Exception('Error clearing favorites: $e');
    }
  }
}
