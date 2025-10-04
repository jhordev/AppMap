# Configuración de AppMap - Guía de instalación

## Configuración de Google Maps API

Para que la funcionalidad de lugares turísticos funcione correctamente, necesitas configurar tu API key de Google Maps:

### 1. Obtener API Key de Google Maps

1. Ve a la [Google Cloud Console](https://console.cloud.google.com/)
2. Crea un nuevo proyecto o selecciona uno existente
3. Habilita las siguientes APIs:
   - Maps SDK for Android
   - Maps SDK for iOS
   - Places API
   - Directions API
   - Geocoding API

4. Ve a "Credenciales" y crea una nueva API key
5. Restringe la API key para mayor seguridad (opcional pero recomendado)

### 2. Configurar la API Key en la aplicación

1. Abre el archivo `lib/config/api_config.dart`
2. Reemplaza `'YOUR_GOOGLE_MAPS_API_KEY'` con tu API key real:

```dart
class ApiConfig {
  static const String googleMapsApiKey = 'TU_API_KEY_AQUI';
  static const String googlePlacesApiKey = googleMapsApiKey;
}
```

### 3. Configurar la API Key en archivos nativos

#### Android
1. Abre `android/app/src/main/AndroidManifest.xml`
2. Agrega tu API key dentro de la etiqueta `<application>`:

```xml
<meta-data android:name="com.google.android.geo.API_KEY"
           android:value="TU_API_KEY_AQUI"/>
```

#### iOS
1. Abre `ios/Runner/AppDelegate.swift`
2. Agrega la siguiente línea en el método `application:didFinishLaunchingWithOptions:`

```swift
GMSServices.provideAPIKey("TU_API_KEY_AQUI")
```

### 4. Instalar dependencias

Ejecuta en la terminal:

```bash
flutter pub get
```

## Funcionalidades implementadas

### ✅ Bottom Sheet de categorías
- Selección de diferentes tipos de lugares (atracciones turísticas, restaurantes, hoteles, etc.)
- Interfaz moderna con iconos y colores distintivos

### ✅ Búsqueda de lugares
- Integración con Google Places API
- Búsqueda por categorías en un radio de 5km
- Información detallada de cada lugar (rating, horarios, fotos)

### ✅ Mapa interactivo
- Marcadores diferenciados por categoría
- Información emergente al tocar marcadores
- Ajuste automático de la cámara para mostrar todos los lugares

### ✅ Sistema de rutas
- Cálculo de rutas usando Google Directions API
- Visualización de polylines en el mapa
- Información de distancia y tiempo estimado

### ✅ Interfaz de usuario mejorada
- Lista de lugares encontrados
- Widget de información de ruta
- Integración fluida entre componentes

## Uso de la aplicación

1. **Explorar lugares**: Toca el botón flotante con icono de explorar en la pantalla principal
2. **Seleccionar categoría**: Elige el tipo de lugar que deseas buscar (ej: "Atracción turística")
3. **Ver resultados**: Los lugares aparecerán como marcadores en el mapa y en una lista
4. **Obtener ruta**: Toca un marcador o lugar de la lista para ver la ruta y obtener direcciones

## Estructura del proyecto

```
lib/
├── config/
│   └── api_config.dart              # Configuración de API keys
├── features/
│   ├── places/
│   │   ├── models/
│   │   │   └── place_model.dart     # Modelo de datos de lugares
│   │   ├── providers/
│   │   │   └── places_provider.dart # Estado global de lugares
│   │   ├── services/
│   │   │   └── places_service.dart  # Servicios de API
│   │   └── widgets/
│   │       ├── category_bottom_sheet.dart  # Selector de categorías
│   │       ├── places_list_widget.dart     # Lista de lugares
│   │       └── route_info_widget.dart      # Información de rutas
│   ├── maps/
│   │   ├── providers/
│   │   │   └── location_provider.dart      # Manejo de ubicación
│   │   ├── utils/
│   │   │   └── polyline_utils.dart         # Utilidades para rutas
│   │   └── widgets/
│   │       └── enhanced_map_widget.dart    # Mapa mejorado
│   └── home/
│       └── views/
│           └── home_view.dart              # Pantalla principal integrada
```

¡La aplicación está lista para usar! 🎉