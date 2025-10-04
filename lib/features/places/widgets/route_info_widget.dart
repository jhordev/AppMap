import 'package:flutter/material.dart';
import '../models/place_model.dart';

class RouteInfoWidget extends StatelessWidget {
  final PlaceModel selectedPlace;
  final Map<String, dynamic>? routeData;
  final VoidCallback? onClose;
  final VoidCallback? onStartNavigation;

  const RouteInfoWidget({
    super.key,
    required this.selectedPlace,
    this.routeData,
    this.onClose,
    this.onStartNavigation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        selectedPlace.name,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: onClose,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        selectedPlace.address,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (selectedPlace.rating != null) ...[
                      Icon(
                        Icons.star,
                        size: 20,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        selectedPlace.rating!.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: selectedPlace.isOpen ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        selectedPlace.isOpen ? 'Abierto' : 'Cerrado',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                if (routeData != null) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  _buildRouteInfo(context),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onStartNavigation,
                    icon: const Icon(Icons.directions),
                    label: Text(routeData != null ? 'Iniciar navegación' : 'Obtener direcciones'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteInfo(BuildContext context) {
    if (routeData == null) return const SizedBox.shrink();

    final routes = routeData!['routes'] as List<dynamic>?;
    if (routes == null || routes.isEmpty) return const SizedBox.shrink();

    final route = routes.first;
    final legs = route['legs'] as List<dynamic>?;
    if (legs == null || legs.isEmpty) return const SizedBox.shrink();

    final leg = legs.first;
    final distance = leg['distance']['text'] ?? 'N/A';
    final duration = leg['duration']['text'] ?? 'N/A';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Información de la ruta',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildRouteInfoCard(
                context,
                Icons.straighten,
                'Distancia',
                distance,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildRouteInfoCard(
                context,
                Icons.access_time,
                'Tiempo',
                duration,
                Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRouteInfoCard(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static void show(
    BuildContext context,
    PlaceModel place, {
    Map<String, dynamic>? routeData,
    VoidCallback? onStartNavigation,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RouteInfoWidget(
        selectedPlace: place,
        routeData: routeData,
        onClose: () => Navigator.pop(context),
        onStartNavigation: () {
          Navigator.pop(context);
          if (onStartNavigation != null) {
            onStartNavigation();
          }
        },
      ),
    );
  }
}