import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../auth/services/auth_provider.dart';
import '../../maps/widgets/enhanced_map_widget.dart';
import '../../maps/services/location_service.dart';
import '../../maps/utils/polyline_utils.dart';
import '../../places/widgets/category_bottom_sheet.dart';
import '../../places/widgets/places_list_widget.dart';
import '../../places/widgets/route_info_widget.dart';
import '../../places/models/place_model.dart';
import '../../places/models/travel_mode.dart';
import '../../places/providers/places_provider.dart';
import '../../navigation/widgets/navigation_view.dart';
import '../../../utils/logger.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  GoogleMapController? _mapController;
  final LocationService _locationService = LocationService();
  LatLng? _currentLocation;
  Set<Polyline> _polylines = {};
  bool _isLoadingLocation = true;
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    Logger.info('HomeView initialized');
    _initializeLocation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Escuchar cambios en el lugar seleccionado desde favoritos
    _listenToSelectedPlace();
  }

  void _listenToSelectedPlace() {
    final selectedPlace = ref.watch(selectedPlaceProvider);
    if (selectedPlace != null && _mapController != null) {
      // Centrar el mapa en el lugar seleccionado
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(selectedPlace.location, 16.0),
          );
        }
      });
    }
  }

  Future<void> _initializeLocation() async {
    final location = await _locationService.getCurrentLocation();
    if (location != null && mounted) {
      setState(() {
        _currentLocation = location;
        _isLoadingLocation = false;
      });
      ref.read(userLocationProvider.notifier).state = location;

      // Centrar el mapa en la ubicación del usuario una vez que esté listo
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(location, 15.0),
        );
      }
    } else if (mounted) {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserAsync = ref.watch(currentUserProvider);

    return Scaffold(
      body: currentUserAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => _buildErrorState(context, error),
        data: (user) => user != null
            ? _buildMapContent(context, user)
            : const Center(
          child: Text(
            'No hay usuario autenticado',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildModernAppBar(BuildContext context, AsyncValue currentUserAsync) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
            ],
          ),
        ),
      ),
      title: Row(
        children: [
          Icon(
            Icons.map_outlined,
            color: Theme.of(context).colorScheme.onPrimary,
            size: 28,
          ),
          const SizedBox(width: 8),
          Text(
            'AppMap',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ],
      ),
      actions: [
        currentUserAsync.when(
          loading: () => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ),
          error: (error, stack) => IconButton(
            icon: Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: () => _showErrorDialog(context, error),
          ),
          data: (user) => user != null
              ? _buildUserProfileButton(context, user)
              : IconButton(
            icon: Icon(
              Icons.login,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: () {
              // Navegar a login si es necesario
            },
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildUserProfileButton(BuildContext context, user) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 56),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).colorScheme.onPrimary,
            width: 2,
          ),
        ),
        child: CircleAvatar(
          radius: 18,
          backgroundColor: Theme.of(context).colorScheme.surface,
          backgroundImage: user.photoURL != null
              ? NetworkImage(user.photoURL!)
              : null,
          child: user.photoURL == null
              ? Text(
            user.displayName.isNotEmpty
                ? user.displayName[0].toUpperCase()
                : user.email[0].toUpperCase(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          )
              : null,
        ),
      ),
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                user.displayName.isNotEmpty ? user.displayName : 'Usuario',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user.email,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
              const Divider(height: 20),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'profile',
          child: Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 20,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(width: 12),
              const Text('Perfil'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'settings',
          child: Row(
            children: [
              Icon(
                Icons.settings_outlined,
                size: 20,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(width: 12),
              const Text('Configuración'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(
                Icons.logout,
                size: 20,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 12),
              Text(
                'Cerrar sesión',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
        ),
      ],
      onSelected: (String value) {
        switch (value) {
          case 'profile':
            _showProfileDialog(context, user);
            break;
          case 'settings':
            _showFeatureComingSoon(context, 'Configuración');
            break;
          case 'logout':
            _showSignOutDialog(context);
            break;
        }
      },
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.1),
            Theme.of(context).colorScheme.surface,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Error al cargar los datos',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'No se pudieron cargar los datos del usuario',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                ref.invalidate(currentUserProvider);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapContent(BuildContext context, dynamic user) {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final selectedPlace = ref.watch(selectedPlaceProvider);

    // Mostrar loading mientras se obtiene la ubicación
    if (_isLoadingLocation) {
      return Container(
        color: Theme.of(context).colorScheme.surface,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Obteniendo tu ubicación...',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        // Mapa a pantalla completa
        _buildEnhancedMap(),

        // Botón flotante para seleccionar categoría
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _showCategoryBottomSheet,
                    borderRadius: BorderRadius.circular(30),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              selectedCategory?.icon ?? Icons.explore,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedCategory != null
                                      ? selectedCategory.displayName
                                      : 'Seleccionar actividad',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (selectedCategory != null)
                                  Text(
                                    'Toca para cambiar',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.keyboard_arrow_down,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
        ),

        // Botón de ubicación actual
        Positioned(
          right: 16,
          bottom: selectedCategory != null || selectedPlace != null ? 280 : 100,
          child: SafeArea(
            child: FloatingActionButton(
              heroTag: 'location_btn',
              onPressed: _centerOnUserLocation,
              child: const Icon(Icons.my_location),
            ),
          ),
        ),

        // Overlay for places list
        if (selectedCategory != null && _currentLocation != null && _isMapReady)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildPlacesOverlay(selectedCategory),
          ),

        // Overlay for selected place route info
        if (selectedPlace != null)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildRouteInfoOverlay(selectedPlace),
          ),
      ],
    );
  }

  void _centerOnUserLocation() {
    if (_currentLocation != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLocation!, 15.0),
      );
    }
  }

  void _showProfileDialog(BuildContext context, user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Perfil de Usuario'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: user.photoURL != null
                    ? NetworkImage(user.photoURL!)
                    : null,
                child: user.photoURL == null
                    ? Text(
                  user.displayName.isNotEmpty
                      ? user.displayName[0].toUpperCase()
                      : user.email[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                )
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                user.displayName.isNotEmpty ? user.displayName : 'Usuario',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                user.email,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(BuildContext context, Object error) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 8),
              const Text('Error'),
            ],
          ),
          content: Text(error.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                ref.invalidate(currentUserProvider);
              },
              child: const Text('Reintentar'),
            ),
          ],
        );
      },
    );
  }

  void _showFeatureComingSoon(BuildContext context, String featureName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.info_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text('$featureName estará disponible pronto!'),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildEnhancedMap() {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final selectedPlace = ref.watch(selectedPlaceProvider);
    final userLocation = ref.watch(userLocationProvider);

    if (selectedCategory != null && userLocation != null) {
      final placesAsync = ref.watch(nearbyPlacesProvider(
        PlacesSearchParams(
          location: userLocation,
          category: selectedCategory,
          radius: 10000,
        ),
      ));

      return placesAsync.when(
        loading: () => Stack(
          children: [
            // Mostrar el mapa con la ubicación del usuario mientras carga
            EnhancedMapWidget(
              initialPosition: userLocation,
              selectedPlace: selectedPlace,
              polylines: _polylines,
              onMapCreated: _onMapCreated,
              onTap: _onMapTap,
            ),
            // Overlay de carga elegante
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Buscando lugares...',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
            ],
          ),
        ),
        data: (places) => EnhancedMapWidget(
          initialPosition: userLocation,
          places: places,
          selectedPlace: selectedPlace,
          polylines: _polylines,
          onMapCreated: _onMapCreated,
          onTap: _onMapTap,
          onPlaceMarkerTapped: _onPlaceSelected,
        ),
      );
    }

    return EnhancedMapWidget(
      initialPosition: _currentLocation,
      selectedPlace: selectedPlace,
      polylines: _polylines,
      onMapCreated: _onMapCreated,
      onTap: _onMapTap,
    );
  }

  Widget _buildPlacesOverlay(PlaceCategory category) {
    final userLocation = ref.watch(userLocationProvider);
    if (userLocation == null) return const SizedBox.shrink();

    final placesAsync = ref.watch(nearbyPlacesProvider(
      PlacesSearchParams(
        location: userLocation,
        category: category,
        radius: 10000,
      ),
    ));

    return placesAsync.when(
      loading: () => const SizedBox.shrink(), // No mostrar nada mientras carga
      error: (error, stack) => Container(
        height: 200,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Center(
          child: Text('Error: $error'),
        ),
      ),
      data: (places) => PlacesListWidget(
        places: places,
        onPlaceSelected: _onPlaceSelected,
      ),
    );
  }

  Widget _buildRouteInfoOverlay(PlaceModel place) {
    final userLocation = ref.watch(userLocationProvider);
    final selectedTravelMode = ref.watch(selectedTravelModeProvider);
    if (userLocation == null) return const SizedBox.shrink();

    final routeAsync = ref.watch(routeProvider(
      RouteParams(
        origin: userLocation,
        destination: place.location,
        travelMode: selectedTravelMode.apiValue,
        placeCategory: place.category,
      ),
    ));

    return routeAsync.when(
      loading: () => RouteInfoWidget(
        selectedPlace: place,
        onClose: _clearSelectedPlace,
      ),
      error: (error, stack) => RouteInfoWidget(
        selectedPlace: place,
        onClose: _clearSelectedPlace,
      ),
      data: (routeData) {
        // Update polylines with route
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            _polylines = {PolylineUtils.createRoutePolyline(routeData)};
          });
        });

        return RouteInfoWidget(
          selectedPlace: place,
          routeData: routeData,
          onClose: _clearSelectedPlace,
          onStartNavigation: () => _startNavigation(place),
          onTravelModeChanged: (mode) {
            // Invalidar el routeProvider para forzar el recálculo de la ruta
            // con el nuevo modo de transporte
            ref.invalidate(routeProvider);
          },
        );
      },
    );
  }

  void _showCategoryBottomSheet() {
    Logger.info('Opening category bottom sheet');
    CategoryBottomSheet.show(context, (category) {
      Logger.info('Category selected: ${category.displayName}');
      ref.read(selectedCategoryProvider.notifier).state = category;
      ref.read(selectedPlaceProvider.notifier).state = null;

      // Clear polylines when changing category
      setState(() {
        _polylines = {};
      });

      // Show feedback to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Buscando ${category.displayName.toLowerCase()}...'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  void _onPlaceSelected(PlaceModel place) {
    ref.read(selectedPlaceProvider.notifier).state = place;
    ref.read(selectedCategoryProvider.notifier).state = null;
    Logger.info('Place selected: ${place.name}');
  }

  void _clearSelectedPlace() {
    ref.read(selectedPlaceProvider.notifier).state = null;
    setState(() {
      _polylines = {};
    });
  }

  void _startNavigation(PlaceModel place) async {
    final userLocation = ref.read(userLocationProvider);
    final selectedTravelMode = ref.read(selectedTravelModeProvider);
    if (userLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo obtener tu ubicación'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final routeAsync = ref.read(routeProvider(
      RouteParams(
        origin: userLocation,
        destination: place.location,
        travelMode: selectedTravelMode.apiValue,
        placeCategory: place.category,
      ),
    ));

    routeAsync.when(
      loading: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Calculando ruta...'),
          ),
        );
      },
      error: (error, stack) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al calcular ruta: $error'),
            backgroundColor: Colors.red,
          ),
        );
      },
      data: (routeData) {
        // Navegar a la vista de navegación
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NavigationView(
              destination: place,
              origin: userLocation,
              routeData: routeData,
            ),
          ),
        );
      },
    );
  }

  // Map callback methods
  void _onMapTap(LatLng position) {
    Logger.info('Map tapped at: ${position.latitude}, ${position.longitude}');

    // Clear selections when tapping on map
    ref.read(selectedPlaceProvider.notifier).state = null;
    ref.read(selectedCategoryProvider.notifier).state = null;
    setState(() {
      _polylines = {};
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    Logger.info('Enhanced Map created successfully');

    // Si ya tenemos la ubicación del usuario, centrar el mapa
    if (_currentLocation != null) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(_currentLocation!, 15.0),
          );
          setState(() {
            _isMapReady = true;
          });
        }
      });
    } else {
      // Si aún no hay ubicación, marcar el mapa como listo de todas formas
      setState(() {
        _isMapReady = true;
      });
    }
  }

  Widget _buildFloatingProfileButton(BuildContext context, dynamic user) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 56),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: CircleAvatar(
          radius: 22,
          backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          backgroundImage: user.photoURL != null
              ? NetworkImage(user.photoURL!)
              : null,
          child: user.photoURL == null
              ? Text(
            user.displayName.isNotEmpty
                ? user.displayName[0].toUpperCase()
                : user.email[0].toUpperCase(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          )
              : null,
        ),
      ),
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                user.displayName.isNotEmpty ? user.displayName : 'Usuario',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user.email,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
              const Divider(height: 20),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'profile',
          child: Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 20,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(width: 12),
              const Text('Perfil'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'settings',
          child: Row(
            children: [
              Icon(
                Icons.settings_outlined,
                size: 20,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(width: 12),
              const Text('Configuración'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(
                Icons.logout,
                size: 20,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 12),
              Text(
                'Cerrar sesión',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
        ),
      ],
      onSelected: (String value) {
        switch (value) {
          case 'profile':
            _showProfileDialog(context, user);
            break;
          case 'settings':
            _showFeatureComingSoon(context, 'Configuración');
            break;
          case 'logout':
            _showSignOutDialog(context);
            break;
        }
      },
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.logout,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 8),
              const Text('Cerrar sesión'),
            ],
          ),
          content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Cerrar sesión'),
              onPressed: () {
                Navigator.of(context).pop();
                ref.read(authStateProvider.notifier).signOut();
              },
            ),
          ],
        );
      },
    );
  }
}