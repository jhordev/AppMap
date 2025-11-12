# 📊 Sistema de Calificaciones de Usuarios - AppMap

Sistema completo de calificaciones y reseñas de lugares implementado para AppMap, completamente independiente de las calificaciones de Google Maps.

## ✨ Características Implementadas

### 🎯 Funcionalidades Principales

1. **Calificar Lugares**
   - Calificación de 1 a 5 estrellas
   - Opinión opcional de hasta 200 caracteres
   - Un usuario puede calificar cada lugar solo una vez
   - Posibilidad de editar calificación existente

2. **Ver Calificaciones**
   - Promedio de calificaciones comunitarias
   - Total de usuarios que han calificado
   - Últimas 3 opiniones en vista de detalles
   - Vista completa con todas las reseñas

3. **Gestión de Calificaciones**
   - Editar calificación propia
   - Eliminar calificación propia
   - Actualización en tiempo real con Firestore

4. **Diferenciación Visual**
   - **Google Maps**: ⭐ Amarillo (Star icon)
   - **AppMap Community**: 💙 Azul (Heart icon)
   - Etiquetas claras para distinguirlas

## 📁 Estructura de Archivos

```
lib/features/ratings/
├── models/
│   ├── rating_model.dart           # Modelo de calificación
│   └── rating_stats_model.dart     # Modelo de estadísticas
├── services/
│   └── ratings_service.dart        # Servicio CRUD de Firestore
├── providers/
│   └── ratings_provider.dart       # Providers de Riverpod
├── widgets/
│   ├── rating_bottom_sheet.dart    # Modal para calificar
│   ├── star_rating_input.dart      # Selector de estrellas
│   ├── rating_display.dart         # Mostrar calificaciones
│   └── user_review_card.dart       # Card de opinión
├── views/
│   └── all_reviews_view.dart       # Vista de todas las reseñas
└── README.md                        # Este archivo
```

## 🗄️ Estructura de Base de Datos (Firestore)

### Colección: `place_ratings`

Almacena todas las calificaciones individuales de los usuarios.

```dart
{
  "id": "auto_generated_id",
  "placeId": "ChIJ...",              // Google Place ID
  "userId": "user_firebase_uid",     // ID del usuario
  "userName": "Juan Pérez",          // Nombre del usuario
  "userPhotoUrl": "https://...",     // Foto del usuario
  "rating": 4,                       // Calificación 1-5
  "review": "Muy buen lugar...",     // Opinión (max 200 chars)
  "createdAt": Timestamp,            // Fecha de creación
  "updatedAt": Timestamp,            // Última actualización
}
```

**Índices necesarios:**
- `placeId` (asc), `createdAt` (desc)
- `userId` (asc), `placeId` (asc)

### Colección: `place_rating_stats`

Almacena estadísticas agregadas para consultas rápidas.

```dart
{
  "placeId": "ChIJ...",              // Google Place ID (Document ID)
  "averageRating": 4.2,              // Promedio de calificaciones
  "totalRatings": 23,                // Total de calificaciones
  "ratingsDistribution": {           // Distribución por estrellas
    "1": 1,
    "2": 2,
    "3": 5,
    "4": 8,
    "5": 7
  },
  "lastUpdated": Timestamp,
}
```

**Índices necesarios:**
- `placeId` (asc)

## 🚀 Cómo Usar

### 1. Mostrar Calificación Comunitaria

```dart
// En cualquier widget
RatingDisplay(
  placeId: place.id,
  iconSize: 20,
  fontSize: 16,
  showLabel: true,      // Mostrar "Usuarios"
  showCount: true,      // Mostrar "(23)"
)
```

### 2. Abrir Modal para Calificar

```dart
// Para nueva calificación
RatingBottomSheet.show(
  context,
  placeId: place.id,
  placeName: place.name,
);

// Para editar calificación existente
RatingBottomSheet.show(
  context,
  placeId: place.id,
  placeName: place.name,
  existingRating: userRating,  // RatingModel existente
);
```

### 3. Ver Todas las Reseñas

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => AllReviewsView(
      placeId: place.id,
      placeName: place.name,
    ),
  ),
);
```

### 4. Obtener Calificación del Usuario

```dart
// En un ConsumerWidget
final userRatingAsync = ref.watch(
  userRatingProvider(
    UserRatingParams(
      userId: currentUserId,
      placeId: placeId,
    ),
  ),
);

userRatingAsync.when(
  data: (rating) => rating != null
    ? Text('Ya calificaste: ${rating.rating} estrellas')
    : Text('Aún no has calificado'),
  loading: () => CircularProgressIndicator(),
  error: (e, s) => Text('Error'),
);
```

### 5. Obtener Estadísticas de un Lugar

```dart
// Stream en tiempo real
final statsAsync = ref.watch(placeStatsStreamProvider(placeId));

// Future único
final statsAsync = ref.watch(placeStatsFutureProvider(placeId));

statsAsync.when(
  data: (stats) => Text(
    'Promedio: ${stats.averageRating.toStringAsFixed(1)} '
    '(${stats.totalRatings} calificaciones)'
  ),
  loading: () => CircularProgressIndicator(),
  error: (e, s) => Text('Error'),
);
```

## 🎨 Integración en la UI

### PlaceDetailSheet (Vista de Detalles)

**Ubicación:** `lib/features/places/widgets/place_detail_sheet.dart`

**Características:**
- Muestra calificación de Google Maps
- Muestra calificación de AppMap Community
- Botón "Calificar este lugar" (o "Editar mi calificación")
- Últimas 3 opiniones de usuarios
- Botón "Ver todas" que abre `AllReviewsView`

**Diferenciación visual:**
```
⭐ 4.5 (127 reseñas) Google     ← Google Maps
💙 4.2 (23 usuarios)             ← AppMap Community
```

### PlacesListWidget (Lista de Lugares)

**Ubicación:** `lib/features/places/widgets/places_list_widget.dart`

**Características:**
- Muestra calificación de Google Maps en badge amarillo
- Muestra calificación de AppMap Community en badge azul
- Compacto y claro

**Ejemplo visual:**
```
┌────────────────────────────────┐
│ 🏊 Piscina Municipal          │
│ Av. Principal 123             │
│ ⭐ 4.5  💙 4.2  🟢 Abierto    │
└────────────────────────────────┘
```

## 🔧 Servicios Disponibles

### RatingsService

```dart
// Guardar o actualizar calificación
await ratingsService.saveRating(ratingModel);

// Obtener calificación del usuario
final rating = await ratingsService.getUserRating(userId, placeId);

// Obtener todas las calificaciones (Stream)
Stream<List<RatingModel>> ratings = ratingsService.getPlaceRatingsStream(placeId);

// Obtener estadísticas
final stats = await ratingsService.getPlaceStats(placeId);

// Eliminar calificación
await ratingsService.deleteRating(ratingId, placeId);

// Verificar si usuario ya calificó
final hasRated = await ratingsService.hasUserRated(userId, placeId);
```

## 📱 Flujo de Usuario

1. **Usuario ve lista de lugares**
   - Ve calificaciones de Google y AppMap juntas

2. **Usuario selecciona un lugar**
   - Se abre `PlaceDetailSheet`
   - Ve calificación promedio de la comunidad
   - Ve últimas 3 opiniones

3. **Usuario quiere calificar**
   - Click en "Calificar este lugar"
   - Se abre modal con selector de estrellas
   - Puede agregar opinión (opcional, max 200 chars)
   - Click en "Enviar calificación"

4. **Usuario quiere editar su calificación**
   - Click en "Editar mi calificación"
   - Modal se abre pre-llenado con datos existentes
   - Puede modificar estrellas y opinión
   - Click en "Actualizar calificación"

5. **Usuario quiere ver todas las opiniones**
   - Click en "Ver todas"
   - Se abre `AllReviewsView` con:
     - Header con estadísticas y distribución
     - Lista completa de todas las reseñas
     - Puede editar/eliminar su propia reseña

## ⚠️ Validaciones

- ✅ Calificación debe ser entre 1 y 5 estrellas
- ✅ Opinión máximo 200 caracteres
- ✅ Usuario debe estar autenticado
- ✅ Un usuario solo puede tener 1 calificación por lugar
- ✅ Solo puede editar/eliminar su propia calificación

## 🔄 Actualización Automática

El sistema usa **Firestore Streams** para actualizaciones en tiempo real:

- Cuando un usuario califica, las estadísticas se actualizan automáticamente
- Otros usuarios ven los cambios sin necesidad de refrescar
- La lista de reseñas se actualiza en tiempo real

## 🎯 Próximas Mejoras Posibles

- [ ] Reportar reseñas inapropiadas
- [ ] Ordenar reseñas por fecha, rating, etc.
- [ ] Filtrar reseñas por cantidad de estrellas
- [ ] Reacciones a opiniones (útil, divertido, etc.)
- [ ] Fotos en las reseñas
- [ ] Insignias para usuarios frecuentes
- [ ] Verificación de visita real al lugar

## 📄 Dependencias Agregadas

```yaml
dependencies:
  intl: ^0.19.0  # Para formateo de fechas
```

## 🧪 Testing

Para probar el sistema:

1. Ejecuta la app: `flutter run`
2. Selecciona un lugar de la lista
3. Click en "Calificar este lugar"
4. Selecciona estrellas y agrega opinión
5. Envía la calificación
6. Verifica que aparezca en la lista de opiniones
7. Edita tu calificación
8. Elimina tu calificación

## 📞 Soporte

Si encuentras algún problema o tienes sugerencias, por favor reporta en el repositorio del proyecto.

---

**Implementado:** Sistema completo de calificaciones y reseñas
**Fecha:** 2025
**Versión:** 1.0.0
