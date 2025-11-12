import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/rating_stats_model.dart';
import '../providers/ratings_provider.dart';
import '../widgets/user_review_card.dart';
import '../widgets/rating_bottom_sheet.dart';
import '../../../features/auth/services/auth_provider.dart';
import '../../../utils/logger.dart';

/// Vista para mostrar todas las reseñas de un lugar
class AllReviewsView extends ConsumerWidget {
  final String placeId;
  final String placeName;

  const AllReviewsView({
    super.key,
    required this.placeId,
    required this.placeName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratingsAsync = ref.watch(placeRatingsStreamProvider(placeId));
    final statsAsync = ref.watch(placeStatsStreamProvider(placeId));
    final currentUserAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Opiniones'),
            Text(
              placeName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Stats header
          statsAsync.when(
            loading: () => const _LoadingStatsHeader(),
            error: (error, stack) => const SizedBox.shrink(),
            data: (stats) => _StatsHeader(stats: stats),
          ),
          const Divider(height: 1),
          // Reviews list
          Expanded(
            child: ratingsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error al cargar las opiniones',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => ref.invalidate(placeRatingsStreamProvider(placeId)),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
              data: (ratings) {
                if (ratings.isEmpty) {
                  return _EmptyState(
                    placeName: placeName,
                    onRate: () => _showRatingSheet(context, null, currentUserAsync),
                  );
                }

                final currentUserId = currentUserAsync.value?.id;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: ratings.length,
                  itemBuilder: (context, index) {
                    final rating = ratings[index];
                    final isCurrentUser = rating.userId == currentUserId;

                    return UserReviewCard(
                      rating: rating,
                      showActions: true,
                      isCurrentUser: isCurrentUser,
                      onEdit: isCurrentUser
                          ? () => _showRatingSheet(context, rating, currentUserAsync)
                          : null,
                      onDelete: isCurrentUser
                          ? () => _deleteRating(context, ref, rating)
                          : null,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showRatingSheet(
    BuildContext context,
    rating,
    AsyncValue currentUserAsync,
  ) {
    if (currentUserAsync.value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes iniciar sesión para calificar'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RatingBottomSheet(
        placeId: placeId,
        placeName: placeName,
        existingRating: rating,
      ),
    );
  }

  Future<void> _deleteRating(
    BuildContext context,
    WidgetRef ref,
    rating,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar calificación'),
        content: const Text('¿Estás seguro de que quieres eliminar tu calificación?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final service = ref.read(ratingsServiceProvider);
      await service.deleteRating(rating.id, rating.placeId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Calificación eliminada'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      Logger.error('Error deleting rating: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _StatsHeader extends StatelessWidget {
  final RatingStatsModel stats;

  const _StatsHeader({required this.stats});

  @override
  Widget build(BuildContext context) {
    if (!stats.hasRatings) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Row(
        children: [
          // Average rating
          Expanded(
            child: Column(
              children: [
                Text(
                  stats.averageRating.toStringAsFixed(1),
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final isActive = index < stats.averageRating.round();
                    return Icon(
                      isActive ? Icons.star : Icons.star_border,
                      size: 20,
                      color: isActive ? Colors.amber : Colors.grey,
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Text(
                  '${stats.totalRatings} calificaciones',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                ),
              ],
            ),
          ),
          // Distribution
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(5, (index) {
                final starNumber = 5 - index;
                final count = stats.ratingsDistribution[starNumber] ?? 0;
                final percentage = stats.getPercentage(starNumber);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        '$starNumber',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.star,
                        size: 12,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: percentage / 100,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 30,
                        child: Text(
                          '$count',
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingStatsHeader extends StatelessWidget {
  const _LoadingStatsHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String placeName;
  final VoidCallback onRate;

  const _EmptyState({
    required this.placeName,
    required this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.rate_review_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Aún no hay opiniones',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '¡Sé el primero en compartir tu experiencia!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRate,
              icon: const Icon(Icons.star),
              label: const Text('Calificar lugar'),
            ),
          ],
        ),
      ),
    );
  }
}
