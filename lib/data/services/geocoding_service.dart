import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../network/config/app_logger.dart';

class GeocodingService {
  /// Cache pour éviter de géocoder plusieurs fois la même adresse
  static final Map<String, LatLng?> _cache = {};

  /// Convertir une adresse en coordonnées GPS (Geocoding)
  static Future<LatLng?> getCoordinatesFromAddress(String address) async {
    if (address.trim().isEmpty) {
      AppLogger.warning('⚠️ [GeocodingService] Adresse vide');
      return null;
    }

    // ✅ Vérifier le cache
    if (_cache.containsKey(address)) {
      AppLogger.debug('📦 [GeocodingService] Adresse trouvée dans le cache: $address');
      return _cache[address];
    }

    try {
      AppLogger.info('🗺️ [GeocodingService] Geocoding de: $address');

      // ✅ Appeler l'API de geocoding
      final locations = await locationFromAddress(address);

      if (locations.isEmpty) {
        AppLogger.warning('⚠️ [GeocodingService] Aucune coordonnée trouvée pour: $address');
        _cache[address] = null;
        return null;
      }

      final location = locations.first;
      final coordinates = LatLng(location.latitude, location.longitude);

      AppLogger.info('✅ [GeocodingService] Coordonnées trouvées: $coordinates');

      // ✅ Sauvegarder dans le cache
      _cache[address] = coordinates;

      return coordinates;
    } catch (e) {
      AppLogger.error('❌ [GeocodingService] Erreur geocoding pour "$address"', e);
      _cache[address] = null;
      return null;
    }
  }

  /// Convertir des coordonnées en adresse (Reverse Geocoding)
  static Future<String?> getAddressFromCoordinates(LatLng coordinates) async {
    try {
      AppLogger.info('🗺️ [GeocodingService] Reverse geocoding de: $coordinates');

      final placemarks = await placemarkFromCoordinates(
        coordinates.latitude,
        coordinates.longitude,
      );

      if (placemarks.isEmpty) {
        AppLogger.warning('⚠️ [GeocodingService] Aucune adresse trouvée');
        return null;
      }

      final placemark = placemarks.first;
      final address = '${placemark.street}, ${placemark.locality}, ${placemark.country}';

      AppLogger.info('✅ [GeocodingService] Adresse trouvée: $address');
      return address;
    } catch (e) {
      AppLogger.error('❌ [GeocodingService] Erreur reverse geocoding', e);
      return null;
    }
  }

  /// Nettoyer le cache
  static void clearCache() {
    _cache.clear();
    AppLogger.info('🗑️ [GeocodingService] Cache nettoyé');
  }

  /// Vérifier si une adresse est dans le cache
  static bool isCached(String address) {
    return _cache.containsKey(address);
  }
}