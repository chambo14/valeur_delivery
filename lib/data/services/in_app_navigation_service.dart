import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/models/navigation/navigation_step.dart';
import '../../network/config/app_logger.dart';
import 'tts_service.dart';

class InAppNavigationService {
  static const String _googleApiKey = 'VOTRE_CLE_API_GOOGLE'; // ✅ À REMPLACER
  static const double _stepCompletionThreshold = 30.0; // 30 mètres

  /// Obtenir les instructions détaillées
  static Future<List<NavigationStep>?> getDetailedDirections({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      AppLogger.info('🗺️ [InAppNavigation] Récupération instructions');

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
          final steps = leg['steps'] as List;

          final navigationSteps = steps
              .map((step) => NavigationStep.fromJson(step))
              .toList();

          AppLogger.info('✅ [InAppNavigation] ${navigationSteps.length} instructions');
          return navigationSteps;
        }
      }

      return null;
    } catch (e) {
      AppLogger.error('❌ [InAppNavigation] Erreur', e);
      return null;
    }
  }

  /// Calculer la distance entre deux points
  static double calculateDistance(LatLng point1, LatLng point2) {
    return Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
  }

  /// Calculer le bearing (direction) entre deux points
  static double calculateBearing(LatLng start, LatLng end) {
    final startLat = start.latitude * pi / 180;
    final startLng = start.longitude * pi / 180;
    final endLat = end.latitude * pi / 180;
    final endLng = end.longitude * pi / 180;

    final dLng = endLng - startLng;

    final y = sin(dLng) * cos(endLat);
    final x = cos(startLat) * sin(endLat) -
        sin(startLat) * cos(endLat) * cos(dLng);

    final bearing = atan2(y, x) * 180 / pi;
    return (bearing + 360) % 360;
  }

  /// Trouver l'étape actuelle basée sur la position
  static int findCurrentStepIndex(
      Position currentPosition,
      List<NavigationStep> steps,
      int lastStepIndex,
      ) {
    final currentLatLng = LatLng(
      currentPosition.latitude,
      currentPosition.longitude,
    );

    // Vérifier si on a atteint l'étape actuelle
    if (lastStepIndex < steps.length) {
      final currentStep = steps[lastStepIndex];
      final distanceToEnd = calculateDistance(
        currentLatLng,
        currentStep.endLocation,
      );

      // Si on est proche de la fin de l'étape, passer à la suivante
      if (distanceToEnd < _stepCompletionThreshold && lastStepIndex < steps.length - 1) {
        AppLogger.info('✅ [InAppNavigation] Étape ${lastStepIndex + 1} complétée');
        return lastStepIndex + 1;
      }
    }

    return lastStepIndex;
  }

  /// Prononcer l'instruction avec distance
  static Future<void> announceInstruction(
      NavigationStep step,
      double distanceToStep,
      ) async {
    String announcement;

    if (distanceToStep > 500) {
      announcement = 'Dans ${(distanceToStep / 1000).toStringAsFixed(1)} kilomètres, ${step.instruction}';
    } else if (distanceToStep > 100) {
      announcement = 'Dans ${distanceToStep.toInt()} mètres, ${step.instruction}';
    } else {
      announcement = step.instruction;
    }

    await TtsService.speak(announcement);
  }

  /// Formater la distance pour l'affichage
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toInt()} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  /// Vérifier si l'utilisateur a dévié de la route
  static bool hasDeviatedFromRoute(
      Position currentPosition,
      List<NavigationStep> steps,
      int currentStepIndex,
      ) {
    if (currentStepIndex >= steps.length) return false;

    final currentLatLng = LatLng(
      currentPosition.latitude,
      currentPosition.longitude,
    );
    final currentStep = steps[currentStepIndex];

    // Calculer la distance à l'étape actuelle
    final distanceToStart = calculateDistance(
      currentLatLng,
      currentStep.startLocation,
    );
    final distanceToEnd = calculateDistance(
      currentLatLng,
      currentStep.endLocation,
    );

    // Déviation si > 100m de l'étape
    return distanceToStart > 100 && distanceToEnd > 100;
  }
}