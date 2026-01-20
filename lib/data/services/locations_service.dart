import 'package:geolocator/geolocator.dart';
import '../../data/models/delivery/location_data.dart';
import '../../network/config/app_logger.dart';


class LocationService {
  /// Obtenir la position actuelle
  static Future<LocationData?> getCurrentLocation() async {
    try {
      AppLogger.info('📍 [LocationService] Obtention de la position');

      // Vérifier les permissions
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppLogger.error('❌ [LocationService] Service de localisation désactivé');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          AppLogger.error('❌ [LocationService] Permission refusée');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        AppLogger.error('❌ [LocationService] Permission refusée définitivement');
        return null;
      }

      // Obtenir la position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final locationData = LocationData(
        lat: position.latitude,
        lng: position.longitude,
      );

      AppLogger.info('✅ [LocationService] Position obtenue');
      AppLogger.debug('   - Lat: ${locationData.lat}');
      AppLogger.debug('   - Lng: ${locationData.lng}');

      return locationData;
    } catch (e) {
      AppLogger.error('❌ [LocationService] Erreur', e);
      return null;
    }
  }

  /// Vérifier si les permissions GPS sont accordées
  static Future<bool> hasPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (e) {
      return false;
    }
  }

  /// Demander les permissions GPS
  static Future<bool> requestPermission() async {
    try {
      final permission = await Geolocator.requestPermission();
      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (e) {
      return false;
    }
  }
}