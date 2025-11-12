import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/ratings_provider.dart';

/// Widget para mostrar la calificación promedio de un lugar (AppMap Community)
class RatingDisplay extends ConsumerWidget {
  final String placeId;
  final double iconSize;
  final double fontSize;
  final bool showLabel;
  final bool showCount;

  const RatingDisplay({
    super.key,
    required this.placeId,
    this.iconSize = 16.0,
    this.fontSize = 14.0,
    this.showLabel = false,
    this.showCount = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(placeStatsStreamProvider(placeId));

    return statsAsync.when(
      loading: () => _buildLoadingState(context),
      error: (error, stack) {
        // Log del error para debug
        debugPrint('❌ Error loading stats for $placeId: $error');
        return _buildEmptyState(context);
      },
      data: (stats) {
        // Log para debug
        debugPrint('📊 Stats for $placeId: avg=${stats.averageRating}, total=${stats.totalRatings}, hasRatings=${stats.hasRatings}');

        if (!stats.hasRatings) {
          return _buildEmptyState(context);
        }

        return _buildRatingDisplay(context, stats.averageRating, stats.totalRatings);
      },
    );
  }

  Widget _buildRatingDisplay(BuildContext context, double rating, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.favorite,
          size: iconSize,
          color: Colors.blue[600],
        ),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        if (showCount) ...[
          const SizedBox(width: 4),
          Text(
            '($count)',
            style: TextStyle(
              fontSize: fontSize - 2,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
        if (showLabel) ...[
          const SizedBox(width: 4),
          Text(
            'Usuarios',
            style: TextStyle(
              fontSize: fontSize - 2,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: iconSize,
          height: iconSize,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.favorite_border,
          size: iconSize,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
        ),
        const SizedBox(width: 4),
        Text(
          'Sin calificaciones',
          style: TextStyle(
            fontSize: fontSize - 2,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

/// Widget para mostrar estrellas de solo lectura
class StarRatingDisplay extends StatelessWidget {
  final double rating;
  final double size;
  final Color? color;
  final int maxStars;

  const StarRatingDisplay({
    super.key,
    required this.rating,
    this.size = 16.0,
    this.color,
    this.maxStars = 5,
  });

  @override
  Widget build(BuildContext context) {
    final starColor = color ?? Colors.amber;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxStars, (index) {
        final starNumber = index + 1;
        final isFullStar = starNumber <= rating.floor();
        final isHalfStar = !isFullStar && starNumber <= rating.ceil();

        IconData iconData;
        if (isFullStar) {
          iconData = Icons.star_rounded;
        } else if (isHalfStar) {
          iconData = Icons.star_half_rounded;
        } else {
          iconData = Icons.star_border_rounded;
        }

        return Icon(
          iconData,
          size: size,
          color: isFullStar || isHalfStar
              ? starColor
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
        );
      }),
    );
  }
}
