import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/place_model.dart';
import '../services/places_service.dart';
import '../../../utils/logger.dart';

class PlaceDetailSheet extends StatefulWidget {
  final PlaceModel place;
  final VoidCallback? onClose;
  final VoidCallback? onNavigate;

  const PlaceDetailSheet({
    super.key,
    required this.place,
    this.onClose,
    this.onNavigate,
  });

  @override
  State<PlaceDetailSheet> createState() => _PlaceDetailSheetState();
}

class _PlaceDetailSheetState extends State<PlaceDetailSheet> {
  final PlacesService _placesService = PlacesService();
  Map<String, dynamic>? _placeDetails;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlaceDetails();
  }

  Future<void> _loadPlaceDetails() async {
    try {
      // Solo cargar detalles si el lugar tiene un place_id de Google
      if (!widget.place.id.startsWith('custom_')) {
        final details = await _placesService.getPlaceDetails(widget.place.id);
        if (mounted) {
          setState(() {
            _placeDetails = details;
            _isLoading = false;
          });
        }
      } else {
        // Para lugares personalizados, no hay detalles adicionales
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      Logger.error('Error loading place details: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Stack(
        children: [
          Column(
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
              // Content
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildContent(),
              ),
            ],
          ),
          // Bottom button
          if (widget.onNavigate != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: ElevatedButton.icon(
                    onPressed: widget.onNavigate,
                    icon: const Icon(Icons.map),
                    label: const Text('Ver ubicación'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photos carousel
          _buildPhotosCarousel(),

          // Place info
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name and rating
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.place.name,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: widget.onClose,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Rating
                if (widget.place.rating != null) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: 20,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.place.rating!.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_placeDetails?['user_ratings_total'] != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          '(${_placeDetails!['user_ratings_total']} reseñas)',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Description
                if (_placeDetails?['editorial_summary']?['overview'] != null) ...[
                  Text(
                    'Descripción',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _placeDetails!['editorial_summary']['overview'],
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                ],

                // Address
                _buildInfoRow(
                  Icons.location_on,
                  'Dirección',
                  widget.place.address,
                ),
                const SizedBox(height: 12),

                // Phone
                if (_placeDetails?['formatted_phone_number'] != null) ...[
                  _buildInfoRow(
                    Icons.phone,
                    'Teléfono',
                    _placeDetails!['formatted_phone_number'],
                    onTap: () => _launchPhone(_placeDetails!['formatted_phone_number']),
                  ),
                  const SizedBox(height: 12),
                ],

                // Website
                if (_placeDetails?['website'] != null) ...[
                  _buildInfoRow(
                    Icons.language,
                    'Sitio web',
                    _placeDetails!['website'],
                    onTap: () => _launchUrl(_placeDetails!['website']),
                  ),
                  const SizedBox(height: 12),
                ],

                // Opening hours
                if (_placeDetails?['opening_hours']?['weekday_text'] != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Horarios',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._buildOpeningHours(),
                  const SizedBox(height: 16),
                ],

                // Reviews
                if (_placeDetails?['reviews'] != null) ...[
                  Text(
                    'Reseñas',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._buildReviews(),
                ],

                const SizedBox(height: 80), // Space for bottom buttons
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosCarousel() {
    final photos = _placeDetails?['photos'] as List<dynamic>?;

    if (photos == null || photos.isEmpty) {
      return Container(
        height: 250,
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
        child: Center(
          child: Icon(
            Icons.image,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    return SizedBox(
      height: 250,
      child: PageView.builder(
        itemCount: photos.length,
        itemBuilder: (context, index) {
          final photo = photos[index];
          final photoReference = photo['photo_reference'];
          final photoUrl = _placesService.getPhotoUrl(photoReference, maxWidth: 800);

          return Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                photoUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: const Center(
                      child: Icon(Icons.error),
                    ),
                  );
                },
              ),
              // Photo counter
              Positioned(
                bottom: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${index + 1}/${photos.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    decoration: onTap != null ? TextDecoration.underline : null,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildOpeningHours() {
    final weekdayText = _placeDetails!['opening_hours']['weekday_text'] as List<dynamic>;
    return weekdayText.map((text) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4.0),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }).toList();
  }

  List<Widget> _buildReviews() {
    final reviews = _placeDetails!['reviews'] as List<dynamic>;
    return reviews.take(3).map((review) {
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: review['profile_photo_url'] != null
                        ? NetworkImage(review['profile_photo_url'])
                        : null,
                    child: review['profile_photo_url'] == null
                        ? const Icon(Icons.person, size: 16)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review['author_name'],
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Row(
                          children: [
                            ...List.generate(5, (index) {
                              return Icon(
                                index < review['rating']
                                    ? Icons.star
                                    : Icons.star_border,
                                size: 14,
                                color: Colors.amber,
                              );
                            }),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                review['text'],
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir el enlace')),
        );
      }
    }
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir el teléfono')),
        );
      }
    }
  }

}

// Función global para mostrar el detalle del lugar
void showPlaceDetail(
  BuildContext context,
  PlaceModel place, {
  VoidCallback? onNavigate,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => PlaceDetailSheet(
      place: place,
      onClose: () => Navigator.pop(context),
      onNavigate: onNavigate,
    ),
  );
}
