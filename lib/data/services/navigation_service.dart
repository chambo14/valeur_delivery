import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:valeur_delivery/data/utils/key_map.dart';

import '../../network/config/app_logger.dart';


class NavigationService {
  // ✅ Remplacez par votre clé API Google
  static const String _googleApiKey = MapKey.key;

  /// Obtenir l'itinéraire entre deux points
  static Future<Map<String, dynamic>?> getDirections({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      AppLogger.info('🗺️ [NavigationService] Calcul de l\'itinéraire');

      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?'
            'origin=${origin.latitude},${origin.longitude}'
            '&destination=${destination.latitude},${destination.longitude}'
            '&mode=driving'
            '&language=fr'
            '&key=$_googleApiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];

          final result = {
            'distance': leg['distance']['text'], // "5.2 km"
            'distanceValue': leg['distance']['value'], // 5200 (en mètres)
            'duration': leg['duration']['text'], // "12 min"
            'durationValue': leg['duration']['value'], // 720 (en secondes)
            'polyline': route['overview_polyline']['points'],
            'startAddress': leg['start_address'],
            'endAddress': leg['end_address'],
          };

          AppLogger.info('✅ [NavigationService] Itinéraire calculé');
          AppLogger.debug('   - Distance: ${result['distance']}');
          AppLogger.debug('   - Durée: ${result['duration']}');

          return result;
        } else {
          AppLogger.error('❌ [NavigationService] Aucun itinéraire trouvé');
          return null;
        }
      } else {
        AppLogger.error('❌ [NavigationService] Erreur API: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      AppLogger.error('❌ [NavigationService] Erreur', e);
      return null;
    }
  }

  /// Décoder la polyline en points
  static List<LatLng> decodePolyline(String encoded) {
    final polylinePoints = PolylinePoints(apiKey: MapKey.key);
    final decoded = PolylinePoints.decodePolyline(encoded);

    return decoded
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList();
  }

  /// Lancer Google Maps pour navigation (avec guidage vocal natif)
  static Future<bool> launchGoogleMapsNavigation({
    required LatLng destination,
    LatLng? origin,
  }) async {
    try {
      AppLogger.info('🧭 [NavigationService] Lancement de la navigation');

      // URL pour Google Maps avec navigation
      final String googleMapsUrl;

      if (origin != null) {
        // Avec point de départ personnalisé
        googleMapsUrl = 'https://www.google.com/maps/dir/?api=1'
            '&origin=${origin.latitude},${origin.longitude}'
            '&destination=${destination.latitude},${destination.longitude}'
            '&travelmode=driving'
            '&dir_action=navigate';
      } else {
        // Depuis la position actuelle
        googleMapsUrl = 'https://www.google.com/maps/dir/?api=1'
            '&destination=${destination.latitude},${destination.longitude}'
            '&travelmode=driving'
            '&dir_action=navigate';
      }

      final uri = Uri.parse(googleMapsUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication, // Ouvre l'app Google Maps
        );
        AppLogger.info('✅ [NavigationService] Navigation lancée');
        return true;
      } else {
        AppLogger.error('❌ [NavigationService] Impossible de lancer Google Maps');
        return false;
      }
    } catch (e) {
      AppLogger.error('❌ [NavigationService] Erreur lancement navigation', e);
      return false;
    }
  }

  /// Lancer Waze (alternative)
  static Future<bool> launchWazeNavigation({
    required LatLng destination,
  }) async {
    try {
      final wazeUrl = 'https://waze.com/ul?ll=${destination.latitude},${destination.longitude}&navigate=yes';
      final uri = Uri.parse(wazeUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.error('❌ [NavigationService] Erreur lancement Waze', e);
      return false;
    }
  }

  /// Calculer le temps d'arrivée estimé
  static DateTime calculateETA(int durationSeconds) {
    return DateTime.now().add(Duration(seconds: durationSeconds));
  }

  /// Formater le temps d'arrivée
  static String formatETA(DateTime eta) {
    final now = DateTime.now();
    final difference = eta.difference(now);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min';
    } else {
      final hours = difference.inHours;
      final minutes = difference.inMinutes % 60;
      return '${hours}h ${minutes}min';
    }
  }
}