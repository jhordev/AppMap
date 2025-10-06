import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../places/models/place_model.dart';
import '../../auth/services/auth_provider.dart';
import '../models/favorite_model.dart';
import '../providers/favorites_provider.dart';

class FavoriteButton extends ConsumerWidget {
  final PlaceModel place;
  final double size;
  final Color? color;

  const FavoriteButton({
    super.key,
    required this.place,
    this.size = 24.0,
    this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final favoritesAsync = ref.watch(userFavoritesStreamProvider);

    if (user == null) {
      return const SizedBox.shrink();
    }

    return favoritesAsync.when(
      loading: () => Icon(
        Icons.favorite_border,
        size: size,
        color: color ?? Colors.grey,
      ),
      error: (_, __) => Icon(
        Icons.favorite_border,
        size: size,
        color: color ?? Colors.grey,
      ),
      data: (favorites) {
        final isFavorite = favorites.any((fav) => fav.placeId == place.id);

        return GestureDetector(
          onTap: () => _toggleFavorite(context, ref, user.id, isFavorite),
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              size: size,
              color: isFavorite
                  ? Colors.red
                  : (color ?? Colors.grey),
            ),
          ),
        );
      },
    );
  }

  Future<void> _toggleFavorite(
    BuildContext context,
    WidgetRef ref,
    String userId,
    bool isFavorite,
  ) async {
    final favoritesService = ref.read(favoritesServiceProvider);

    try {
      if (isFavorite) {
        await favoritesService.removeFavorite(userId, place.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${place.name} eliminado de favoritos'),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.grey[700],
            ),
          );
        }
      } else {
        final favorite = FavoriteModel.fromPlace(
          userId: userId,
          placeId: place.id,
          placeName: place.name,
          placeAddress: place.address,
          placeLocation: place.location,
          placeCategory: place.category,
          placeRating: place.rating,
          placePhotoUrl: place.photoUrl,
        );

        await favoritesService.addFavorite(favorite);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.favorite, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('${place.name} agregado a favoritos'),
                  ),
                ],
              ),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.red[700],
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar favoritos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
