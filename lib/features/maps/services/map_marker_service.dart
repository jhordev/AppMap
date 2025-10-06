import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../places/widgets/category_bottom_sheet.dart';

/// Servicio modular para crear y gestionar marcadores personalizados del mapa
class MapMarkerService {
  // Cache con múltiples tamaños: small, medium, large
  static final Map<String, BitmapDescriptor> _iconCache = {};
  static bool _isInitialized = false;

  // Tamaños predefinidos según zoom
  static const double _smallSize = 30.0;   // Zoom lejano (< 13)
  static const double _mediumSize = 40.0;  // Zoom medio (13-15)
  static const double _largeSize = 60.0;  // Zoom cercano (> 15)

  /// Inicializa todos los iconos personalizados en diferentes tamaños
  static Future<void> initializeIcons() async {
    if (_isInitialized) return;

    try {
      for (final category in PlaceCategory.values) {
        // Crear 3 versiones de cada icono
        final smallIcon = await _createCustomMarkerIcon(
          category.icon,
          category.color,
          size: _smallSize,
        );
        final mediumIcon = await _createCustomMarkerIcon(
          category.icon,
          category.color,
          size: _mediumSize,
        );
        final largeIcon = await _createCustomMarkerIcon(
          category.icon,
          category.color,
          size: _largeSize,
        );

        _iconCache['${category.name}_small'] = smallIcon;
        _iconCache['${category.name}_medium'] = mediumIcon;
        _iconCache['${category.name}_large'] = largeIcon;
      }
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing map icons: $e');
    }
  }

  /// Obtiene el icono para una categoría específica según nivel de zoom
  static BitmapDescriptor getIconForCategory(
    PlaceCategory category, {
    double zoom = 14.0,
  }) {
    final size = _getSizeForZoom(zoom);
    final key = '${category.name}_$size';
    return _iconCache[key] ?? _iconCache['${category.name}_medium'] ?? BitmapDescriptor.defaultMarker;
  }

  /// Obtiene el icono basado en el string de categoría (del modelo)
  static BitmapDescriptor getIconForCategoryString(
    String categoryString, {
    double zoom = 14.0,
  }) {
    try {
      final category = PlaceCategory.values.firstWhere(
        (cat) => cat.name == categoryString,
        orElse: () => PlaceCategory.tourism,
      );
      return getIconForCategory(category, zoom: zoom);
    } catch (e) {
      return BitmapDescriptor.defaultMarker;
    }
  }

  /// Determina el tamaño del icono según el nivel de zoom
  static String _getSizeForZoom(double zoom) {
    if (zoom < 13) {
      return 'small';
    } else if (zoom < 15) {
      return 'medium';
    } else {
      return 'large';
    }
  }

  /// Detecta la categoría desde los tipos de Google Places
  static PlaceCategory detectCategoryFromTypes(List<String> types) {
    // Gimnasios
    if (types.contains('gym') || types.contains('health')) {
      return PlaceCategory.gym;
    }

    // Deportes
    if (types.contains('stadium')) {
      return PlaceCategory.sports;
    }

    // Parques - pueden ser para múltiples actividades
    if (types.contains('park')) {
      // Analizar el nombre o contexto si es necesario
      return PlaceCategory.hiking;
    }

    // Turismo
    if (types.contains('tourist_attraction') ||
        types.contains('museum') ||
        types.contains('church') ||
        types.contains('art_gallery')) {
      return PlaceCategory.tourism;
    }

    // Natural features
    if (types.contains('natural_feature') || types.contains('campground')) {
      return PlaceCategory.trekking;
    }

    // Por defecto
    return PlaceCategory.tourism;
  }

  /// Crea un icono personalizado desde un IconData y Color
  static Future<BitmapDescriptor> _createCustomMarkerIcon(
    IconData iconData,
    Color color, {
    double size = 80.0,
  }) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final iconSize = size * 0.5;

    // Dibujar círculo de fondo
    final circlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2,
      circlePaint,
    );

    // Borde blanco
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;

    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2 - 3,
      borderPaint,
    );

    // Dibujar icono
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    textPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: iconSize,
        fontFamily: iconData.fontFamily,
        package: iconData.fontPackage,
        color: Colors.white,
      ),
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size - textPainter.width) / 2,
        (size - textPainter.height) / 2,
      ),
    );

    // Convertir a imagen
    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  /// Limpia el caché de iconos
  static void clearCache() {
    _iconCache.clear();
    _isInitialized = false;
  }

  /// Crea un icono personalizado en tiempo real (sin caché)
  static Future<BitmapDescriptor> createCustomIcon({
    required IconData icon,
    required Color color,
  }) async {
    return await _createCustomMarkerIcon(icon, color);
  }
}
