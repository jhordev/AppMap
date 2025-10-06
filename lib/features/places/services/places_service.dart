import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../data/action_categories_config.dart';
import '../models/place_model.dart';
import '../widgets/category_bottom_sheet.dart';
import '../../../config/api_config.dart';
import '../../../utils/logger.dart';
import 'distance_service.dart';

class PlacesService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api';
  static const String _apiKey = ApiConfig.googlePlacesApiKey;

  // Keywords optimizados para búsquedas en Perú
  static const Map<PlaceCategory, String> _categoryKeywords = {
    PlaceCategory.swimming: 'piscina',
    PlaceCategory.hiking: 'parque',
    PlaceCategory.trekking: 'montana',
    PlaceCategory.running: 'parque',
    PlaceCategory.cycling: 'parque',
    PlaceCategory.football: 'futbol',
    PlaceCategory.basketball: 'basquet',
    PlaceCategory.volleyball: 'voley',
    PlaceCategory.gym: 'gimnasio',
    PlaceCategory.yoga: 'yoga',
    PlaceCategory.sports: 'deportivo',
    PlaceCategory.tourism: 'turismo',
  };

  // Categorías que NO deben usar rankby=distance (usar radius para mejores resultados)
  static const Set<PlaceCategory> _useDistanceRank = {};

  static const Map<String, String> _diacriticsMap = {
    '\u00E1': 'a',
    '\u00E0': 'a',
    '\u00E4': 'a',
    '\u00E2': 'a',
    '\u00E3': 'a',
    '\u00E5': 'a',
    '\u00E7': 'c',
    '\u00E9': 'e',
    '\u00E8': 'e',
    '\u00EB': 'e',
    '\u00EA': 'e',
    '\u00ED': 'i',
    '\u00EC': 'i',
    '\u00EF': 'i',
    '\u00EE': 'i',
    '\u00F1': 'n',
    '\u00F3': 'o',
    '\u00F2': 'o',
    '\u00F6': 'o',
    '\u00F4': 'o',
    '\u00F5': 'o',
    '\u00FA': 'u',
    '\u00F9': 'u',
    '\u00FC': 'u',
    '\u00FB': 'u',
  };

  Future<List<PlaceModel>> searchNearbyPlaces({
    required LatLng location,
    required PlaceCategory category,
    double radius = 10000,
  }) async {
    try {
      Logger.info(
        '=== Searching places for category: ${category.displayName} ===',
      );
      Logger.info('Location: ${location.latitude}, ${location.longitude}');
      Logger.info('Radius: ${radius}m');

      final googleCategories = ActionCategoriesConfig.getCategoriesForAction(
        category,
      );
      final filterRules = ActionCategoriesConfig.getFilterRules(category);
      final keyword = _categoryKeywords[category];

      Logger.info(
        'Searching in ${googleCategories.length} Google Place categories',
      );
      Logger.info('Categories: ${googleCategories.join(", ")}');
      Logger.info('Keyword: $keyword');

      final allPlaces = <PlaceModel>[];
      final seenPlaceIds = <String>{};
      final placeScores = <String, double>{};

      for (final type in googleCategories) {
        Logger.info('');
        Logger.info('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        Logger.info('Searching Google Places type: $type');
        Logger.info('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        final useDistanceRank = _useDistanceRank.contains(category);
        Logger.info('Use distance ranking: $useDistanceRank');

        final params = {
          'location': '${location.latitude},${location.longitude}',
          'type': type,
          'language': 'es',
          'region': 'PE',
          'key': _apiKey,
        };

        if (useDistanceRank && keyword != null) {
          params['rankby'] = 'distance';
          params['keyword'] = keyword;
          Logger.info('Ranking: DISTANCE (closest results)');
          Logger.info('Keyword: "$keyword"');
        } else {
          params['radius'] = radius.toString();
          Logger.info('Ranking: PROMINENCE (best match)');
          Logger.info('Radius: ${radius}m (${(radius / 1000).toStringAsFixed(1)}km)');
          if (keyword != null) {
            params['keyword'] = keyword;
            Logger.info('Keyword: "$keyword"');
          } else {
            Logger.info('Keyword: none');
          }
        }

        final queryString = params.entries
            .map((entry) => '${entry.key}=${Uri.encodeComponent(entry.value)}')
            .join('&');
        final url = Uri.parse('$_baseUrl/place/nearbysearch/json?$queryString');

        Logger.info('Full API URL:');
        Logger.info(url.toString().replaceAll(_apiKey, '***API_KEY***'));

        try {
          final response = await http.get(url);

          if (response.statusCode == 200) {
            final data = json.decode(response.body) as Map<String, dynamic>;
            final status = data['status'];

            Logger.info('');
            Logger.info('✓ API Response Status: $status');

            if (status == 'OK') {
              final results = List<Map<String, dynamic>>.from(
                data['results'] as List,
              );
              Logger.info('✓ API returned ${results.length} raw results');
              Logger.info('');

              var processedCount = 0;
              var skippedTypeCount = 0;
              var skippedRelevanceCount = 0;
              var addedCount = 0;

              for (final rawPlace in results) {
                try {
                  processedCount++;
                  final placeName = rawPlace['name']?.toString() ?? 'Unknown';

                  final types =
                      (rawPlace['types'] as List<dynamic>?)
                          ?.map((t) => t.toString())
                          .toList() ??
                      const [];

                  Logger.info('[$processedCount/${results.length}] Analyzing: "$placeName"');
                  Logger.info('   Types: ${types.join(", ")}');

                  if (types.isNotEmpty) {
                    final hasValidType = googleCategories.any(types.contains);
                    if (!hasValidType) {
                      skippedTypeCount++;
                      Logger.info('   ✗ SKIPPED - Types don\'t match category requirements');
                      Logger.info('   Expected any of: ${googleCategories.join(", ")}');
                      continue;
                    }
                  }

                  final relevanceScore = _evaluatePlaceRelevance(
                    rawPlace: rawPlace,
                    category: category,
                    googleCategories: googleCategories,
                    filterRules: filterRules,
                  );

                  if (relevanceScore == null) {
                    skippedRelevanceCount++;
                    Logger.info('   ✗ SKIPPED - Failed relevance filter');
                    Logger.info('   (Keywords or types didn\'t meet category requirements)');
                    continue;
                  }

                  final place = PlaceModel.fromMap(
                    rawPlace,
                    categoryOverride: category.name,
                  );

                  if (!seenPlaceIds.contains(place.id)) {
                    seenPlaceIds.add(place.id);
                    allPlaces.add(place);
                    addedCount++;
                    Logger.info('   ✓ ADDED - Relevance score: ${relevanceScore.toStringAsFixed(2)}');
                  } else {
                    Logger.info('   ⊘ DUPLICATE - Already in results');
                  }

                  final currentScore = placeScores[place.id];
                  if (currentScore == null || relevanceScore > currentScore) {
                    placeScores[place.id] = relevanceScore;
                  }
                } catch (error) {
                  Logger.warning('   ✗ ERROR parsing place: $error');
                }
              }

              Logger.info('');
              Logger.info('Summary for type "$type":');
              Logger.info('  • Processed: $processedCount places');
              Logger.info('  • Added: $addedCount places');
              Logger.info('  • Skipped (wrong type): $skippedTypeCount');
              Logger.info('  • Skipped (low relevance): $skippedRelevanceCount');
            } else if (status == 'ZERO_RESULTS') {
              Logger.info('No results for type: $type');
            } else if (status == 'REQUEST_DENIED') {
              Logger.error(
                'REQUEST_DENIED for $type - check API key and enabled APIs',
              );
            } else if (status == 'INVALID_REQUEST') {
              Logger.error('INVALID_REQUEST for $type - check parameters');
            } else {
              Logger.warning('API status for $type: $status');
            }
          } else {
            Logger.error('HTTP error ${response.statusCode} for type: $type');
          }
        } catch (error) {
          Logger.error('Error searching type $type: $error');
        }
      }

      Logger.info('');
      Logger.info('═══════════════════════════════════════════');
      Logger.info('FINAL FILTERING & RANKING');
      Logger.info('═══════════════════════════════════════════');
      Logger.info('Total unique places collected: ${allPlaces.length}');

      // Filtrar por distancia y asegurar que tienen score
      final filteredPlaces = allPlaces.where((place) {
        final distance = DistanceService.calculateDistance(
          origin: location,
          destination: place.location,
        );
        return distance <= radius && placeScores.containsKey(place.id);
      }).toList();

      Logger.info('After distance filter (≤${radius}m): ${filteredPlaces.length} places');

      filteredPlaces.sort((a, b) {
        final scoreB = placeScores[b.id] ?? 0;
        final scoreA = placeScores[a.id] ?? 0;
        final scoreComparison = scoreB.compareTo(scoreA);
        if (scoreComparison != 0) {
          return scoreComparison;
        }

        final distanceA = DistanceService.calculateDistance(
          origin: location,
          destination: a.location,
        );
        final distanceB = DistanceService.calculateDistance(
          origin: location,
          destination: b.location,
        );
        final distanceComparison = distanceA.compareTo(distanceB);
        if (distanceComparison != 0) {
          return distanceComparison;
        }

        final ratingB = b.rating ?? 0;
        final ratingA = a.rating ?? 0;
        return ratingB.compareTo(ratingA);
      });

      Logger.info('Places sorted by: 1) Relevance score, 2) Distance, 3) Rating');
      Logger.info('');

      final finalResults = filteredPlaces.take(20).toList();

      Logger.info('═══════════════════════════════════════════');
      Logger.info('FINAL RESULTS (Top ${finalResults.length})');
      Logger.info('═══════════════════════════════════════════');

      for (var i = 0; i < finalResults.length; i++) {
        final place = finalResults[i];
        final score = placeScores[place.id] ?? 0;
        final distance = DistanceService.calculateDistance(
          origin: location,
          destination: place.location,
        );
        Logger.info('${i + 1}. "${place.name}"');
        Logger.info('   Score: ${score.toStringAsFixed(2)} | Distance: ${(distance / 1000).toStringAsFixed(2)}km | Rating: ${place.rating ?? "N/A"}');
      }

      Logger.info('');
      Logger.info('✓ Search completed - returning ${finalResults.length} places');
      Logger.info('═══════════════════════════════════════════');

      return finalResults;
    } catch (error) {
      Logger.error('Error searching places: $error');
      return [];
    }
  }

  double? _evaluatePlaceRelevance({
    required Map<String, dynamic> rawPlace,
    required PlaceCategory category,
    required List<String> googleCategories,
    required CategoryFilterRules filterRules,
  }) {
    var score = 0.0;
    final types =
        (rawPlace['types'] as List<dynamic>?)
            ?.map((value) => value.toString())
            .toSet() ??
        const <String>{};

    // Dar puntos base si coincide con las categorías de Google
    if (googleCategories.any(types.contains)) {
      score += 2.0;
    }

    final hasHighValueType = filterRules.highValueTypes.any(types.contains);
    if (hasHighValueType) {
      score += 3.0;
    }

    final normalizedText = _normalizeText(
      [
        rawPlace['name']?.toString() ?? '',
        rawPlace['vicinity']?.toString() ?? '',
        rawPlace['formatted_address']?.toString() ?? '',
        types.join(' '),
      ].join(' '),
    );

    // Excluir si contiene keywords excluidas
    if (filterRules.excludedKeywords.any(
      (keyword) => keyword.isNotEmpty && normalizedText.contains(keyword),
    )) {
      return null;
    }

    final primaryMatched = filterRules.primaryKeywords.any(
      (keyword) => keyword.isNotEmpty && normalizedText.contains(keyword),
    );

    final secondaryMatches = filterRules.secondaryKeywords
        .where(
          (keyword) => keyword.isNotEmpty && normalizedText.contains(keyword),
        )
        .length;

    // Más puntos por keywords primarios
    if (primaryMatched) {
      score += 2.0;
    }

    // Puntos por keywords secundarios
    if (secondaryMatches > 0) {
      score += secondaryMatches * 0.5;
    }

    // Aceptar si tiene al menos score base (coincidencia de tipo)
    // Esto hace que sea más permisivo
    if (score >= 1.0) {
      return score;
    }

    return null;
  }

  String _normalizeText(String value) {
    final buffer = StringBuffer();
    final lower = value.toLowerCase();

    for (final rune in lower.runes) {
      final char = String.fromCharCode(rune);
      final replacement = _diacriticsMap[char];
      if (replacement != null) {
        buffer.write(replacement);
        continue;
      }

      if ((rune >= 97 && rune <= 122) || (rune >= 48 && rune <= 57)) {
        buffer.writeCharCode(rune);
      } else if (rune == 32) {
        buffer.write(' ');
      } else {
        buffer.write(' ');
      }
    }

    final normalized = buffer.toString();
    return normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  Future<List<PlaceModel>> searchPlacesByText({
    required String query,
    required LatLng location,
    double radius = 10000,
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/place/textsearch/json'
        '?query=$query'
        '&location=${location.latitude},${location.longitude}'
        '&radius=$radius'
        '&key=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final results = data['results'] as List<dynamic>;

        return results
            .map((result) => PlaceModel.fromMap(result as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to search places: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Error searching places by text: $error');
    }
  }

  Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    try {
      Logger.info('Fetching details for place: $placeId');

      final url = Uri.parse(
        '$_baseUrl/place/details/json'
        '?place_id=$placeId'
        '&fields=name,rating,formatted_phone_number,formatted_address,opening_hours,website,reviews,photos,editorial_summary,url,user_ratings_total,price_level,types'
        '&language=es'
        '&key=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final status = data['status'];

        Logger.info('Place Details API status: $status');

        if (status == 'OK') {
          return data['result'] as Map<String, dynamic>;
        } else {
          Logger.error('Place Details API Error: $status');
          return null;
        }
      } else {
        Logger.error('HTTP Error: ${response.statusCode}');
        throw Exception('Failed to get place details: ${response.statusCode}');
      }
    } catch (error) {
      Logger.error('Error getting place details: $error');
      throw Exception('Error getting place details: $error');
    }
  }

  String getPhotoUrl(String photoReference, {int maxWidth = 400}) {
    return '$_baseUrl/place/photo?maxwidth=$maxWidth&photo_reference=$photoReference&key=$_apiKey';
  }

  /// Calcula la ruta y distancia usando el servicio propio (sin Google Directions API)
  Future<Map<String, dynamic>> getDirections({
    required LatLng origin,
    required LatLng destination,
    String travelMode = 'driving',
    String? placeCategory,
  }) async {
    try {
      // Detectar modo de transporte según la categoría del lugar
      final detectedMode = _detectTravelMode(placeCategory, travelMode);

      // Usar el servicio propio de cálculo de distancias
      return DistanceService.getRouteInfo(
        origin: origin,
        destination: destination,
        travelMode: detectedMode,
      );
    } catch (error) {
      throw Exception('Error getting directions: $error');
    }
  }

  /// Detecta el modo de transporte apropiado según la categoría
  String _detectTravelMode(String? category, String defaultMode) {
    if (category == null) return defaultMode;

    switch (category.toLowerCase()) {
      // Actividades de caminata
      case 'hiking':
      case 'trekking':
      case 'running':
      case 'walking':
        return 'walking';

      // Actividades de ciclismo
      case 'cycling':
      case 'mountain_biking':
        return 'bicycling';

      // Todo lo demás en auto (natación, deportes, gimnasios, turismo)
      case 'swimming':
      case 'football':
      case 'basketball':
      case 'volleyball':
      case 'gym':
      case 'yoga':
      case 'sports':
      case 'tourism':
      default:
        return 'driving';
    }
  }

  /// Calcula solo la distancia entre dos puntos en metros
  double calculateDistance({
    required LatLng origin,
    required LatLng destination,
  }) {
    return DistanceService.calculateDistance(
      origin: origin,
      destination: destination,
    );
  }
}
