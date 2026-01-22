import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/models/navigation/navigation_step.dart';
import '../../data/providers/courier_location_provider.dart';
import '../../data/services/in_app_navigation_service.dart';
import '../../data/services/location_service.dart';
import '../../data/services/navigation_service.dart';
import '../../data/services/tts_service.dart';
import '../../network/config/app_logger.dart';
import '../../theme/app_theme.dart';

class NavigationScreen extends ConsumerStatefulWidget {
  final LatLng destination;
  final String destinationName;
  final String destinationAddress;

  const NavigationScreen({
    super.key,
    required this.destination,
    required this.destinationName,
    required this.destinationAddress,
  });

  @override
  ConsumerState<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends ConsumerState<NavigationScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  StreamSubscription<Position>? _positionSub;

  List<NavigationStep> _steps = [];
  int _currentStepIndex = 0;

  bool _isLoading = true;
  bool _hasArrived = false;
  bool _isMuted = false;
  bool _hasAnnouncedFirstStep = false;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  double _totalDistance = 0;
  double _remainingDistance = 0;
  String _estimatedTime = '';
  double _currentBearing = 0;

  DateTime? _lastRecalculation;

  // ✅ NOUVEAU : Pour éviter les annonces répétitives
  Map<int, Set<int>> _announcedDistances = {};

  @override
  void initState() {
    super.initState();
    _initNavigation();

    ref.read(courierLocationProvider.notifier).startLocationSharing(
      intervalSeconds: 15,
    );
  }

  // ───────────────── INIT ─────────────────

  Future<void> _initNavigation() async {
    final position = await LocationService.getCurrentPosition();
    if (position == null) {
      _showError('Impossible d\'obtenir la position GPS');
      return;
    }

    _currentPosition = position;

    final origin = LatLng(position.latitude, position.longitude);

    // Étapes détaillées
    final steps = await InAppNavigationService.getDetailedDirections(
      origin: origin,
      destination: widget.destination,
    );

    if (steps == null || steps.isEmpty) {
      _showError('Impossible de calculer l\'itinéraire');
      return;
    }

    // Polyline + infos globales
    final directions = await NavigationService.getDirections(
      origin: origin,
      destination: widget.destination,
    );

    if (directions == null) {
      _showError('Erreur lors du chargement de la route');
      return;
    }

    final polylinePoints =
    NavigationService.decodePolyline(directions['polyline']);

    setState(() {
      _steps = steps;
      _isLoading = false;
      _totalDistance = directions['distanceValue'].toDouble();
      _remainingDistance = _totalDistance;
      _estimatedTime = directions['duration'];

      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: polylinePoints,
          color: AppTheme.primaryRed,
          width: 6,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      );

      _markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: widget.destination,
          infoWindow: InfoWindow(
            title: widget.destinationName,
            snippet: widget.destinationAddress,
          ),
        ),
      );
    });

    _startTracking();

    // ✅ TTS initial amélioré
    if (!_isMuted && !_hasAnnouncedFirstStep) {
      _hasAnnouncedFirstStep = true;
      await TtsService.speak(
        'Navigation démarrée vers ${widget.destinationName}',
      );
      await Future.delayed(const Duration(seconds: 2));

      // ✅ UTILISER LA NOUVELLE MÉTHODE
      final distToFirstStep = InAppNavigationService.calculateDistance(
        origin,
        _steps[0].startLocation,
      );
      await TtsService.announceNavigationStep(_steps[0], distToFirstStep);
    }
  }

  // ───────────────── TRACKING ─────────────────

  void _startTracking() {
    _positionSub = LocationService.getPositionStream().listen(
          (pos) {
        _currentPosition = pos;
        _updateNavigation(pos);
      },
      onError: (e) {
        AppLogger.error('❌ Erreur GPS navigation', e);
      },
    );
  }

  void _updateNavigation(Position pos) {
    if (_steps.isEmpty || _hasArrived) return;

    final currentLatLng = LatLng(pos.latitude, pos.longitude);

    // Distance restante réaliste
    double remaining = 0;
    for (int i = _currentStepIndex; i < _steps.length; i++) {
      remaining += _steps[i].distanceValue.toDouble();
    }
    _remainingDistance = remaining;

    // Arrivée
    if (InAppNavigationService.calculateDistance(
      currentLatLng,
      widget.destination,
    ) < 20) {
      _onArrival();
      return;
    }

    // Étape courante
    final newIndex = InAppNavigationService.findCurrentStepIndex(
      pos,
      _steps,
      _currentStepIndex,
    );

    if (newIndex != _currentStepIndex && newIndex < _steps.length) {
      _currentStepIndex = newIndex;
      _announcedDistances[_currentStepIndex] = {}; // Reset pour nouvelle étape

      if (!_isMuted) {
        final step = _steps[newIndex];
        final dist = InAppNavigationService.calculateDistance(
          currentLatLng,
          step.startLocation,
        );

        // ✅ UTILISER LA NOUVELLE MÉTHODE
        TtsService.announceNavigationStep(step, dist);
      }
    }

    // ✅ NOUVEAU : Annoncer les étapes à venir à certaines distances
    if (!_isMuted && _currentStepIndex < _steps.length) {
      final step = _steps[_currentStepIndex];
      final distToStep = InAppNavigationService.calculateDistance(
        currentLatLng,
        step.startLocation,
      );

      // Distances clés pour les annonces: 200m, 100m, 50m
      final distanceThresholds = [200, 100, 50];

      for (final threshold in distanceThresholds) {
        if (distToStep <= threshold && distToStep > threshold - 20) {
          // Vérifier si cette distance n'a pas déjà été annoncée
          _announcedDistances[_currentStepIndex] ??= {};

          if (!_announcedDistances[_currentStepIndex]!.contains(threshold)) {
            _announcedDistances[_currentStepIndex]!.add(threshold);

            TtsService.announceNavigationStep(step, distToStep);

            AppLogger.info('🔊 Annonce à ${threshold}m: ${step.getVoiceInstruction(distToStep)}');
            break; // Une seule annonce à la fois
          }
        }
      }
    }

    // Bearing & caméra (fluide)
    final target = _steps[_currentStepIndex].endLocation;
    final bearing =
    InAppNavigationService.calculateBearing(currentLatLng, target);

    if ((bearing - _currentBearing).abs() > 10) {
      _currentBearing = bearing;
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: currentLatLng,
            zoom: 18,
            bearing: bearing,
            tilt: 45,
          ),
        ),
      );
    }

    // Déviation (avec cooldown)
    if (InAppNavigationService.hasDeviatedFromRoute(
      pos,
      _steps,
      _currentStepIndex,
    )) {
      if (_lastRecalculation == null ||
          DateTime.now().difference(_lastRecalculation!).inSeconds > 20) {
        _lastRecalculation = DateTime.now();
        _recalculateRoute();
      }
    }

    setState(() {});
  }

  // ───────────────── RECALCUL ─────────────────

  Future<void> _recalculateRoute() async {
    if (!_isMuted) {
      await TtsService.speak('Recalcul de l\'itinéraire');
    }

    setState(() {
      _isLoading = true;
      _steps.clear();
      _polylines.clear();
      _currentStepIndex = 0;
      _hasAnnouncedFirstStep = false;
      _announcedDistances.clear(); // ✅ Reset les annonces
    });

    await _initNavigation();
  }

  // ───────────────── ARRIVÉE ─────────────────

  void _onArrival() {
    if (_hasArrived) return;

    _hasArrived = true;
    _positionSub?.cancel();

    if (!_isMuted) {
      TtsService.speak('Vous êtes arrivé à destination');
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 28),
            const SizedBox(width: 12),
            const Text('Arrivée'),
          ],
        ),
        content: Text('Vous êtes arrivé à ${widget.destinationName}'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Terminer'),
          ),
        ],
      ),
    );
  }

  // ───────────────── UI ─────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryRed),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (c) => _mapController = c,
            initialCameraPosition: CameraPosition(
              target: LatLng(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
              ),
              zoom: 18,
              tilt: 45,
            ),
            polylines: _polylines,
            markers: _markers,
            myLocationEnabled: true,
            zoomControlsEnabled: false,
            compassEnabled: false,
            mapToolbarEnabled: false,
          ),

          Positioned(top: 50, left: 16, right: 16, child: _instructionCard()),
          Positioned(bottom: 0, left: 0, right: 0, child: _bottomPanel()),
        ],
      ),
    );
  }

  Widget _instructionCard() {
    final step = _steps[_currentStepIndex];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardLight,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // ✅ Icône de manœuvre
          Text(
            step.maneuverIcon,
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ Instruction courte
                Text(
                  step.getShortInstruction(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),

                // ✅ Nom de rue si disponible
                if (step.streetName != null && step.streetName!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      step.streetName!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.primaryRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                // Distance restante pour cette étape
                if (_currentPosition != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      InAppNavigationService.formatDistance(
                        InAppNavigationService.calculateDistance(
                          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                          step.startLocation,
                        ),
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textGrey.withOpacity(0.8),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Infos principales
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _info(
                  Icons.straighten_rounded,
                  InAppNavigationService.formatDistance(_remainingDistance),
                  'Distance',
                ),
                _info(
                  Icons.access_time_rounded,
                  _estimatedTime,
                  'Temps',
                ),
                _info(
                  Icons.navigation_rounded,
                  '${(_currentStepIndex + 1)}/${_steps.length}',
                  'Étape',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() => _isMuted = !_isMuted);
                      if (_isMuted) {
                        TtsService.stop();
                      } else {
                        TtsService.speak('Instructions vocales activées');
                      }
                    },
                    icon: Icon(
                      _isMuted
                          ? Icons.volume_off_rounded
                          : Icons.volume_up_rounded,
                      color: _isMuted ? AppTheme.textGrey : AppTheme.primaryRed,
                    ),
                    label: Text(
                      _isMuted ? 'Muet' : 'Son',
                      style: TextStyle(
                        color: _isMuted ? AppTheme.textGrey : AppTheme.primaryRed,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: _isMuted ? AppTheme.textGrey : AppTheme.primaryRed,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Quitter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.error,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _info(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 24, color: AppTheme.primaryRed),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppTheme.textGrey.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  // ───────────────── CLEANUP ─────────────────

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.error),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    ref.read(courierLocationProvider.notifier).stopLocationSharing();
    TtsService.dispose();
    _mapController?.dispose();
    super.dispose();
  }
}