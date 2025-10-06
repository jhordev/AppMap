import '../widgets/category_bottom_sheet.dart';

class CategoryFilterRules {
  final List<String> primaryKeywords;
  final List<String> secondaryKeywords;
  final List<String> excludedKeywords;
  final List<String> highValueTypes;
  final bool allowFallbackWithoutPrimary;

  const CategoryFilterRules({
    this.primaryKeywords = const [],
    this.secondaryKeywords = const [],
    this.excludedKeywords = const [],
    this.highValueTypes = const [],
    this.allowFallbackWithoutPrimary = true,
  });
}

class ActionCategoriesConfig {
  /// Tipos válidos de Google Places API (Table 1: https://developers.google.com/maps/documentation/places/web-service/supported_types)
  static const Map<PlaceCategory, List<String>> actionToGoogleCategories = {
    // NATACIÓN - Piscinas y lugares acuáticos
    PlaceCategory.swimming: [
      'tourist_attraction',
      'park',
      'lodging',
      'spa',
      'gym',
      'point_of_interest',
    ],

    // CAMINATA - Parques y áreas naturales para caminar
    PlaceCategory.hiking: [
      'park',
      'tourist_attraction',
      'campground',
      'natural_feature',
      'point_of_interest',
    ],

    // SENDERISMO / TREKKING - Rutas de montaña
    PlaceCategory.trekking: [
      'park',
      'tourist_attraction',
      'campground',
      'natural_feature',
      'point_of_interest',
    ],

    // CORRER - Parques y pistas
    PlaceCategory.running: [
      'park',
      'stadium',
      'point_of_interest',
    ],

    // CICLISMO - Parques y rutas
    PlaceCategory.cycling: [
      'park',
      'tourist_attraction',
      'point_of_interest',
      'bicycle_store',
    ],

    // FÚTBOL - Estadios y canchas
    PlaceCategory.football: [
      'stadium',
      'point_of_interest',
      'park',
    ],

    // BALONCESTO - Gimnasios y canchas
    PlaceCategory.basketball: [
      'gym',
      'stadium',
      'point_of_interest',
    ],

    // VOLEIBOL - Gimnasios y canchas
    PlaceCategory.volleyball: [
      'gym',
      'stadium',
      'point_of_interest',
    ],

    // GIMNASIO
    PlaceCategory.gym: [
      'gym',
      'health',
    ],

    // YOGA
    PlaceCategory.yoga: [
      'gym',
      'spa',
      'health',
    ],

    // DEPORTES VARIOS
    PlaceCategory.sports: [
      'stadium',
      'gym',
      'point_of_interest',
    ],

    // TURISMO / PASEOS
    PlaceCategory.tourism: [
      'tourist_attraction',
      'museum',
      'park',
      'church',
      'cemetery',
      'zoo',
      'aquarium',
      'art_gallery',
      'city_hall',
      'library',
      'point_of_interest',
    ],
  };

  /// Reglas de filtrado por categoría (ajustadas para Perú)
  static const Map<PlaceCategory, CategoryFilterRules> _categoryFilterRules = {
    PlaceCategory.swimming: CategoryFilterRules(
      primaryKeywords: [
        'piscina', 'natacion', 'alberca', 'pool', 'acuatico', 'balneario', 'agua'
      ],
      secondaryKeywords: ['recreo', 'club', 'termal', 'banos'],
      highValueTypes: ['tourist_attraction', 'spa', 'lodging', 'gym'],
      allowFallbackWithoutPrimary: true,
    ),
    PlaceCategory.hiking: CategoryFilterRules(
      primaryKeywords: [
        'sendero', 'trail', 'caminata', 'parque', 'reserva', 'mirador',
        'bosque', 'cascada', 'laguna', 'cerro', 'montana', 'natural'
      ],
      secondaryKeywords: ['ecologico', 'aventura', 'paisaje', 'nacional'],
      highValueTypes: ['park', 'tourist_attraction', 'natural_feature', 'campground'],
      allowFallbackWithoutPrimary: true,
    ),
    PlaceCategory.trekking: CategoryFilterRules(
      primaryKeywords: [
        'trekking', 'senderismo', 'montana', 'cerro', 'ruta', 'mirador',
        'nevado', 'cumbre', 'pico', 'escalada'
      ],
      secondaryKeywords: ['aventura', 'alta montana', 'alpinismo'],
      highValueTypes: ['park', 'tourist_attraction', 'natural_feature', 'campground'],
      allowFallbackWithoutPrimary: true,
    ),
    PlaceCategory.running: CategoryFilterRules(
      primaryKeywords: [
        'parque', 'pista', 'atletismo', 'running', 'correr', 'jogging', 'deporte'
      ],
      secondaryKeywords: ['deportivo', 'cardio', 'malecón', 'paseo'],
      highValueTypes: ['park', 'stadium'],
      allowFallbackWithoutPrimary: true,
    ),
    PlaceCategory.cycling: CategoryFilterRules(
      primaryKeywords: [
        'ciclovia', 'bicicleta', 'bike', 'ciclismo', 'bici', 'cicloruta', 'parque'
      ],
      secondaryKeywords: ['ruta', 'mtb', 'paseo', 'pista'],
      highValueTypes: ['park', 'tourist_attraction', 'bicycle_store'],
      allowFallbackWithoutPrimary: true,
    ),
    PlaceCategory.football: CategoryFilterRules(
      primaryKeywords: [
        'futbol', 'fulbito', 'cancha', 'estadio', 'soccer', 'gras', 'sintetico'
      ],
      secondaryKeywords: ['club', 'deportivo', 'liga'],
      highValueTypes: ['stadium', 'park'],
      allowFallbackWithoutPrimary: true,
    ),
    PlaceCategory.basketball: CategoryFilterRules(
      primaryKeywords: [
        'basquet', 'basketball', 'baloncesto', 'cancha', 'coliseo'
      ],
      secondaryKeywords: ['deportivo', 'gimnasio'],
      highValueTypes: ['gym', 'stadium'],
      allowFallbackWithoutPrimary: true,
    ),
    PlaceCategory.volleyball: CategoryFilterRules(
      primaryKeywords: [
        'voley', 'voleibol', 'volleyball', 'cancha', 'coliseo'
      ],
      secondaryKeywords: ['deportivo', 'gimnasio', 'playa'],
      highValueTypes: ['gym', 'stadium'],
      allowFallbackWithoutPrimary: true,
    ),
    PlaceCategory.gym: CategoryFilterRules(
      primaryKeywords: [
        'gym', 'gimnasio', 'fitness', 'entrenamiento', 'crossfit', 'bodytech'
      ],
      secondaryKeywords: ['pesas', 'cardio', 'funcional'],
      highValueTypes: ['gym', 'health'],
      allowFallbackWithoutPrimary: true,
    ),
    PlaceCategory.yoga: CategoryFilterRules(
      primaryKeywords: [
        'yoga', 'pilates', 'meditacion', 'zen', 'mindfulness'
      ],
      secondaryKeywords: ['relajacion', 'bienestar', 'spa', 'wellness'],
      highValueTypes: ['gym', 'spa', 'health'],
      allowFallbackWithoutPrimary: true,
    ),
    PlaceCategory.sports: CategoryFilterRules(
      primaryKeywords: [
        'polideportivo', 'coliseo', 'deportivo', 'estadio', 'complejo', 'club'
      ],
      secondaryKeywords: ['multideportivo', 'deportes', 'cancha'],
      highValueTypes: ['stadium', 'gym'],
      allowFallbackWithoutPrimary: true,
    ),
    PlaceCategory.tourism: CategoryFilterRules(
      primaryKeywords: [
        'turismo', 'atraccion', 'mirador', 'plaza', 'iglesia', 'catedral',
        'museo', 'monumento', 'historico', 'parque', 'malecon'
      ],
      secondaryKeywords: ['cultural', 'colonial', 'centro', 'turistico'],
      highValueTypes: [
        'tourist_attraction', 'museum', 'park', 'church', 'art_gallery',
        'zoo', 'aquarium', 'library', 'city_hall'
      ],
      allowFallbackWithoutPrimary: true,
    ),
  };

  static List<String> getCategoriesForAction(PlaceCategory action) {
    return actionToGoogleCategories[action] ?? const ['tourist_attraction'];
  }

  static Map<PlaceCategory, List<String>> getAllConfigurations() {
    return actionToGoogleCategories;
  }

  static bool hasConfiguration(PlaceCategory action) {
    return actionToGoogleCategories.containsKey(action);
  }

  static int getCategoriesCount(PlaceCategory action) {
    return actionToGoogleCategories[action]?.length ?? 0;
  }

  static CategoryFilterRules getFilterRules(PlaceCategory action) {
    return _categoryFilterRules[action] ?? const CategoryFilterRules();
  }
}
