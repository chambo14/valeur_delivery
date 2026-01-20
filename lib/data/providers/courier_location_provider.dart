import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:geolocator/geolocator.dart';
import '../../network/config/app_logger.dart';
import '../../network/courier_service.dart';
import '../services/locations_service.dart';
import 'api_provider.dart';
import 'profile_provider.dart'; // ✅ Import du ProfileProvider

/// État pour le partage de position
class CourierLocationState {
  final bool isSharing;
  final Position? lastPosition;
  final DateTime? lastUpdateTime;
  final String? errorMessage;

  CourierLocationState({
    this.isSharing = false,
    this.lastPosition,
    this.lastUpdateTime,
    this.errorMessage,
  });

  CourierLocationState copyWith({
    bool? isSharing,
    Position? lastPosition,
    DateTime? lastUpdateTime,
    String? errorMessage,
  }) {
    return CourierLocationState(
      isSharing: isSharing ?? this.isSharing,
      lastPosition: lastPosition ?? this.lastPosition,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
      errorMessage: errorMessage,
    );
  }
}

/// Notifier pour gérer le partage de position
class CourierLocationNotifier extends StateNotifier<CourierLocationState> {
  final CourierService _courierService;
  final Ref _ref; // ✅ Ajout du Ref
  Timer? _locationTimer;
  StreamSubscription<Position>? _positionStream;

  CourierLocationNotifier(this._courierService, this._ref)
      : super(CourierLocationState());

  /// Démarrer le partage de position (toutes les 30 secondes)
  Future<void> startLocationSharing({int intervalSeconds = 30}) async {
    if (state.isSharing) {
      AppLogger.debug('📍 [CourierLocation] Partage déjà actif');
      return;
    }

    AppLogger.info('📍 [CourierLocation] Démarrage du partage');

    // Vérifier les permissions
    final hasPermission = await LocationService.hasPermission();
    if (!hasPermission) {
      final granted = await LocationService.requestPermission();
      if (!granted) {
        state = state.copyWith(
          errorMessage: 'Permission GPS refusée',
        );
        return;
      }
    }

    state = state.copyWith(isSharing: true);

    // Envoyer immédiatement la position
    await _updateLocation();

    // Configurer le timer pour les mises à jour périodiques
    _locationTimer = Timer.periodic(
      Duration(seconds: intervalSeconds),
          (_) => _updateLocation(),
    );

    AppLogger.info(
        '✅ [CourierLocation] Partage démarré (interval: ${intervalSeconds}s)');
  }

  /// Arrêter le partage de position
  void stopLocationSharing() {
    AppLogger.info('🛑 [CourierLocation] Arrêt du partage');

    _locationTimer?.cancel();
    _locationTimer = null;
    _positionStream?.cancel();
    _positionStream = null;

    state = state.copyWith(isSharing: false);
  }

  /// Mettre à jour la position immédiatement
  Future<void> _updateLocation() async {
    try {
      // Obtenir la position GPS
      final location = await LocationService.getCurrentLocation();

      if (location == null) {
        AppLogger.error('❌ [CourierLocation] Position GPS non disponible');
        state = state.copyWith(
          errorMessage: 'Position GPS non disponible',
        );
        return;
      }

      // ✅ Récupérer l'UUID depuis le ProfileProvider
      final profileState = _ref.read(profileProvider);
      final uuid = profileState.profile?.uuid;

      if (uuid == null || uuid.isEmpty) {
        AppLogger.error('❌ [CourierLocation] UUID coursier non disponible');
        AppLogger.info('💡 Tip: Assurez-vous que le profil a été chargé');
        state = state.copyWith(
          errorMessage: 'UUID coursier non disponible. Chargez le profil d\'abord.',
        );
        return;
      }

      AppLogger.debug('📍 [CourierLocation] Courier UUID: $uuid');

      // Envoyer au serveur
      final result = await _courierService.updateLocation(
        uuid,
        location.lat,
        location.lng,
      );

      result.fold(
            (error) {
          AppLogger.error('❌ [CourierLocation] Erreur MAJ: $error');
          state = state.copyWith(
            errorMessage: error,
          );
        },
            (response) {
          AppLogger.info('✅ [CourierLocation] Position mise à jour');
          AppLogger.debug('   - Lat: ${location.lat}');
          AppLogger.debug('   - Lng: ${location.lng}');

          // Créer un objet Position pour l'état
          final position = Position(
            latitude: location.lat,
            longitude: location.lng,
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
          );

          state = state.copyWith(
            lastPosition: position,
            lastUpdateTime: DateTime.now(),
            errorMessage: null,
          );
        },
      );
    } catch (e) {
      AppLogger.error('❌ [CourierLocation] Exception: $e');
      state = state.copyWith(
        errorMessage: e.toString(),
      );
    }
  }

  @override
  void dispose() {
    stopLocationSharing();
    super.dispose();
  }
}

/// Provider principal
final courierLocationProvider =
StateNotifierProvider<CourierLocationNotifier, CourierLocationState>((ref) {
  final courierService = ref.read(courierServiceProvider);
  return CourierLocationNotifier(courierService, ref); // ✅ Passer le ref
});


