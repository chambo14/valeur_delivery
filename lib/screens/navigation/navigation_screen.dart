import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/models/navigation/navigation_step.dart';
import '../../data/services/in_app_navigation_service.dart';
import '../../data/services/location_service.dart';
import '../../data/services/navigation_service.dart';
import '../../data/services/tts_service.dart';
import '../../network/config/app_logger.dart';
import '../../theme/app_theme.dart';

class NavigationScreen extends StatefulWidget {
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
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStreamSubscription;

  List<NavigationStep> _steps = [];
  int _currentStepIndex = 0;
  bool _isLoading = true;
  bool _hasArrived = false;
  bool _isMuted = false;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  double _totalDistance = 0;
  double _remainingDistance = 0;
  String _estimatedTime = '';
  double _currentBearing = 0;

  @override
  void initState() {
    super.initState();
    _initializeNavigation();
  }

  Future<void> _initializeNavigation() async {
    // 1. Obtenir position actuelle
    final position = await LocationService.getCurrentPosition();
    if (position == null) {
      _showError('Impossible d\'obtenir votre position');
      return;
    }

    setState(() => _currentPosition = position);

    // 2. Calculer l'itinéraire
    final origin = LatLng(position.latitude, position.longitude);
    final steps = await InAppNavigationService.getDetailedDirections(
      origin: origin,
      destination: widget.destination,
    );

    if (steps == null || steps.isEmpty) {
      _showError('Impossible de calculer l\'itinéraire');
      return;
    }

    // 3. Obtenir la polyline
    final directions = await NavigationService.getDirections(
      origin: origin,
      destination: widget.destination,
    );

    if (directions != null) {
      final polylinePoints = NavigationService.decodePolyline(
        directions['polyline'],
      );

      setState(() {
        _steps = steps;
        _isLoading = false;
        _totalDistance = directions['distanceValue'].toDouble();
        _remainingDistance = _totalDistance;
        _estimatedTime = directions['duration'];

        // Polyline
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

        // Markers
        _markers.add(
          Marker(
            markerId: const MarkerId('start'),
            position: origin,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
          ),
        );
        _markers.add(
          Marker(
            markerId: const MarkerId('destination'),
            position: widget.destination,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
            infoWindow: InfoWindow(
              title: widget.destinationName,
              snippet: widget.destinationAddress,
            ),
          ),
        );
      });

      // 4. Démarrer le suivi
      _startPositionTracking();

      // 5. Annoncer première instruction
      // Dans _initializeNavigation(), remplacez la partie TTS par:

// 5. Annoncer première instruction (si TTS disponible)
      if (_steps.isNotEmpty && !_isMuted) {
        await TtsService.speak('Navigation démarrée vers ${widget.destinationName}');
        await Future.delayed(const Duration(seconds: 2));
        await InAppNavigationService.announceInstruction(_steps[0], 0);
      }

// Si TTS non disponible, afficher un message
      if (!TtsService.isAvailable && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.volume_off_rounded, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Guidage vocal non disponible (mode silencieux)'),
                ),
              ],
            ),
            backgroundColor: AppTheme.warning,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _startPositionTracking() {
    _positionStreamSubscription = LocationService.getPositionStream().listen(
          (Position position) {
        setState(() => _currentPosition = position);

        _updateNavigation(position);
      },
      onError: (error) {
        AppLogger.error('❌ [NavigationScreen] Erreur position', error);
      },
    );
  }

  void _updateNavigation(Position position) {
    if (_steps.isEmpty || _hasArrived) return;

    final currentLatLng = LatLng(position.latitude, position.longitude);

    // 1. Calculer distance restante à destination
    final distanceToDestination = InAppNavigationService.calculateDistance(
      currentLatLng,
      widget.destination,
    );

    setState(() {
      _remainingDistance = distanceToDestination;
    });

    // 2. Vérifier si arrivé
    if (distanceToDestination < 20) {
      _onArrival();
      return;
    }

    // 3. Trouver l'étape actuelle
    final newStepIndex = InAppNavigationService.findCurrentStepIndex(
      position,
      _steps,
      _currentStepIndex,
    );

    // 4. Si nouvelle étape, annoncer
    if (newStepIndex != _currentStepIndex && newStepIndex < _steps.length) {
      setState(() => _currentStepIndex = newStepIndex);

      if (!_isMuted) {
        final step = _steps[newStepIndex];
        final distanceToStep = InAppNavigationService.calculateDistance(
          currentLatLng,
          step.startLocation,
        );
        InAppNavigationService.announceInstruction(step, distanceToStep);
      }
    }

    // 5. Calculer bearing et rotation caméra
    if (_currentStepIndex < _steps.length) {
      final nextPoint = _steps[_currentStepIndex].endLocation;
      final bearing = InAppNavigationService.calculateBearing(
        currentLatLng,
        nextPoint,
      );

      setState(() => _currentBearing = bearing);

      // Rotation de la caméra
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

    // 6. Vérifier déviation
    if (InAppNavigationService.hasDeviatedFromRoute(
      position,
      _steps,
      _currentStepIndex,
    )) {
      _recalculateRoute();
    }
  }

  Future<void> _recalculateRoute() async {
    if (_currentPosition == null) return;

    AppLogger.info('🔄 [NavigationScreen] Recalcul itinéraire');

    if (!_isMuted) {
      await TtsService.speak('Recalcul de l\'itinéraire');
    }

    // Réinitialiser et recalculer
    setState(() {
      _isLoading = true;
      _steps.clear();
      _polylines.clear();
      _currentStepIndex = 0;
    });

    await _initializeNavigation();
  }

  void _onArrival() {
    if (_hasArrived) return;

    setState(() => _hasArrived = true);

    _positionStreamSubscription?.cancel();

    if (!_isMuted) {
      TtsService.speak('Vous êtes arrivé à destination');
    }

    // Dialog d'arrivée
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 32),
            SizedBox(width: 12),
            Text('Arrivée !'),
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
              foregroundColor: Colors.white,
            ),
            child: const Text('Terminer'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.error,
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryRed),
            SizedBox(height: 16),
            Text(
              'Calcul de l\'itinéraire...',
              style: TextStyle(color: AppTheme.textGrey),
            ),
          ],
        ),
      )
          : Stack(
        children: [
          // Carte
          GoogleMap(
            onMapCreated: (controller) => _mapController = controller,
            initialCameraPosition: CameraPosition(
              target: _currentPosition != null
                  ? LatLng(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
              )
                  : widget.destination,
              zoom: 18,
              tilt: 45,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
            rotateGesturesEnabled: true,
            scrollGesturesEnabled: true,
            tiltGesturesEnabled: true,
            zoomGesturesEnabled: true,
          ),

          // Instructions en haut
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: _buildInstructionCard(),
          ),

          // Infos en bas
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomInfo(),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionCard() {
    if (_currentStepIndex >= _steps.length) {
      return const SizedBox.shrink();
    }

    final step = _steps[_currentStepIndex];
    final distanceToStep = _currentPosition != null
        ? InAppNavigationService.calculateDistance(
      LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      step.endLocation,
    )
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardLight,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icône de manœuvre
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.primaryRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    step.maneuverIcon,
                    style: const TextStyle(
                      fontSize: 32,
                      color: AppTheme.primaryRed,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Distance
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      InAppNavigationService.formatDistance(distanceToStep),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryRed,
                      ),
                    ),
                    Text(
                      step.distance,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Instruction
          Text(
            step.instruction,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardLight,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Barre de progression
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem(
                  Icons.straighten_rounded,
                  InAppNavigationService.formatDistance(_remainingDistance),
                  'Restant',
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: AppTheme.textGrey.withOpacity(0.3),
                ),
                _buildInfoItem(
                  Icons.access_time_rounded,
                  _estimatedTime,
                  'Arrivée',
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: AppTheme.textGrey.withOpacity(0.3),
                ),
                _buildInfoItem(
                  Icons.navigation_rounded,
                  '${_currentBearing.toInt()}°',
                  'Direction',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Boutons
            Row(
              children: [
                // Mute/Unmute
                IconButton(
                  onPressed: () {
                    setState(() => _isMuted = !_isMuted);
                    if (_isMuted) {
                      TtsService.stop();
                    }
                  },
                  icon: Icon(
                    _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                    color: AppTheme.primaryRed,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.primaryRed.withOpacity(0.1),
                  ),
                ),
                const SizedBox(width: 12),

                // Recalculer
                IconButton(
                  onPressed: _recalculateRoute,
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: AppTheme.info,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.info.withOpacity(0.1),
                  ),
                ),
                const SizedBox(width: 12),

                // Arrêter navigation
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Arrêter la navigation'),
                          content: const Text(
                            'Êtes-vous sûr de vouloir arrêter la navigation ?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Non'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.error,
                              ),
                              child: const Text('Oui'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.stop_rounded),
                    label: const Text('Arrêter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
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

  Widget _buildInfoItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.textGrey, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textGrey,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    TtsService.dispose();
    _mapController?.dispose();
    super.dispose();
  }
}