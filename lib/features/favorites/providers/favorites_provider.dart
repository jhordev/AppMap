import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/favorite_model.dart';
import '../services/favorites_service.dart';
import '../../auth/services/auth_provider.dart';

/// Provider del servicio de favoritos
final favoritesServiceProvider = Provider<FavoritesService>((ref) {
  return FavoritesService();
});

/// Provider que escucha los favoritos del usuario actual
final userFavoritesStreamProvider = StreamProvider<List<FavoriteModel>>((ref) {
  final user = ref.watch(currentUserProvider).value;

  if (user == null) {
    return Stream.value([]);
  }

  final favoritesService = ref.watch(favoritesServiceProvider);
  return favoritesService.getUserFavoritesStream(user.id).handleError((error) {
    // Retornar lista vacía en caso de error
    return <FavoriteModel>[];
  });
});

// Provider para verificar si un lugar es favorito
final isFavoriteProvider = FutureProvider.family<bool, String>((ref, placeId) async {
  final user = ref.watch(currentUserProvider).value;

  if (user == null) {
    return false;
  }

  final favoritesService = ref.watch(favoritesServiceProvider);
  return await favoritesService.isFavorite(user.id, placeId);
});

/// Provider para el conteo de favoritos
final favoritesCountProvider = FutureProvider<int>((ref) async {
  final user = ref.watch(currentUserProvider).value;

  if (user == null) {
    return 0;
  }

  final favoritesService = ref.watch(favoritesServiceProvider);
  return await favoritesService.getFavoritesCount(user.id);
});

/// Provider para gestionar el estado de favoritos (cache local)
class FavoritesNotifier extends StateNotifier<Set<String>> {
  FavoritesNotifier() : super({});

  void addFavorite(String placeId) {
    state = {...state, placeId};
  }

  void removeFavorite(String placeId) {
    state = state.where((id) => id != placeId).toSet();
  }

  bool isFavorite(String placeId) {
    return state.contains(placeId);
  }

  void toggleFavorite(String placeId) {
    if (state.contains(placeId)) {
      removeFavorite(placeId);
    } else {
      addFavorite(placeId);
    }
  }

  void setFavorites(List<String> placeIds) {
    state = placeIds.toSet();
  }

  void clear() {
    state = {};
  }
}

final favoritesNotifierProvider = StateNotifierProvider<FavoritesNotifier, Set<String>>((ref) {
  return FavoritesNotifier();
});
