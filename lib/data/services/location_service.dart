import 'package:geolocator/geolocator.dart';
import '../../network/config/app_logger.dart';


class LocationService {
  /// Vérifier les permissions de localisation
  static Future<bool> checkPermissions() async {
    try {
      AppLogger.info('📍 [LocationService] Vérification des permissions');

      // Vérifier si le service de localisation est activé
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppLogger.warning('⚠️ [LocationService] Service de localisation désactivé');
        return false;
      }

      // Vérifier les permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        AppLogger.info('📍 [LocationService] Demande de permission');
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          AppLogger.warning('❌ [LocationService] Permission refusée');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        AppLogger.error('❌ [LocationService] Permission refusée définitivement');
        return false;
      }

      AppLogger.info('✅ [LocationService] Permissions OK');
      return true;
    } catch (e) {
      AppLogger.error('❌ [LocationService] Erreur permissions', e);
      return false;
    }
  }

  /// Obtenir la position actuelle
  static Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await checkPermissions();
      if (!hasPermission) return null;

      AppLogger.info('📍 [LocationService] Récupération position actuelle');

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      AppLogger.info('✅ [LocationService] Position obtenue');
      AppLogger.debug('   - Lat: ${position.latitude}');
      AppLogger.debug('   - Lng: ${position.longitude}');
      AppLogger.debug('   - Précision: ${position.accuracy}m');

      return position;
    } catch (e) {
      AppLogger.error('❌ [LocationService] Erreur récupération position', e);
      return null;
    }
  }

  /// Suivre la position en temps réel
  static Stream<Position> getPositionStream() {
    AppLogger.info('📡 [LocationService] Démarrage suivi position');

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Mise à jour tous les 10 mètres
    );

    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  /// Calculer la distance entre deux points (en mètres)
  static double calculateDistance(
      double lat1,
      double lng1,
      double lat2,
      double lng2,
      ) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }

  /// Formater la distance pour l'affichage
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }
}