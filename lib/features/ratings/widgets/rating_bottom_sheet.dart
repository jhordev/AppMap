import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/rating_model.dart';
import '../providers/ratings_provider.dart';
import '../../../features/auth/services/auth_provider.dart';
import 'star_rating_input.dart';

/// Bottom sheet para calificar un lugar
class RatingBottomSheet extends ConsumerStatefulWidget {
  final String placeId;
  final String placeName;
  final RatingModel? existingRating; // Si ya existe, se muestra para editar

  const RatingBottomSheet({
    super.key,
    required this.placeId,
    required this.placeName,
    this.existingRating,
  });

  @override
  ConsumerState<RatingBottomSheet> createState() => _RatingBottomSheetState();
}

class _RatingBottomSheetState extends ConsumerState<RatingBottomSheet> {
  late int _rating;
  late TextEditingController _reviewController;
  bool _isSubmitting = false;
  final _maxCharacters = 200;

  @override
  void initState() {
    super.initState();
    _rating = widget.existingRating?.rating ?? 0;
    _reviewController = TextEditingController(
      text: widget.existingRating?.review ?? '',
    );
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserAsync = ref.watch(currentUserProvider);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.existingRating != null
                                      ? 'Editar calificación'
                                      : '¿Cómo fue tu experiencia?',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.placeName,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Star rating
                      Center(
                        child: Column(
                          children: [
                            Text(
                              'Calificación',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            StarRatingInput(
                              rating: _rating,
                              onRatingChanged: (rating) {
                                setState(() {
                                  _rating = rating;
                                });
                              },
                              size: 48,
                            ),
                            const SizedBox(height: 8),
                            if (_rating > 0)
                              Text(
                                _getRatingLabel(_rating),
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Review text field
                      Text(
                        'Tu opinión (opcional)',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _reviewController,
                        maxLength: _maxCharacters,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Comparte tu experiencia...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          counterText: '${_reviewController.text.length}/$_maxCharacters',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 24),
                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _rating > 0 && !_isSubmitting
                              ? () => _submitRating(currentUserAsync)
                              : null,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  widget.existingRating != null
                                      ? 'Actualizar calificación'
                                      : 'Enviar calificación',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      if (_rating == 0) ...[
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            'Selecciona al menos una estrella',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Muy malo';
      case 2:
        return 'Malo';
      case 3:
        return 'Regular';
      case 4:
        return 'Bueno';
      case 5:
        return 'Excelente';
      default:
        return '';
    }
  }

  Future<void> _submitRating(AsyncValue currentUserAsync) async {
    if (_rating == 0) return;

    final currentUser = currentUserAsync.value;
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debes iniciar sesión para calificar'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final rating = RatingModel(
        id: widget.existingRating?.id ?? '',
        placeId: widget.placeId,
        userId: currentUser.id,
        userName: currentUser.displayName.isNotEmpty
            ? currentUser.displayName
            : currentUser.email,
        userPhotoUrl: currentUser.photoURL,
        rating: _rating,
        review: _reviewController.text.trim().isEmpty
            ? null
            : _reviewController.text.trim(),
        createdAt: widget.existingRating?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final service = ref.read(ratingsServiceProvider);
      await service.saveRating(rating);

      // Invalidar providers para refrescar datos
      ref.invalidate(placeStatsStreamProvider(widget.placeId));
      ref.invalidate(placeRatingsStreamProvider(widget.placeId));
      ref.invalidate(userRatingProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingRating != null
                  ? 'Calificación actualizada'
                  : 'Calificación enviada',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar calificación: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
