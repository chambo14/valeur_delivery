import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/providers/deliveries_provider.dart';
import '../../data/services/location_service.dart';
import '../../data/services/navigation_service.dart';
import '../../network/config/app_logger.dart';
import '../../theme/app_theme.dart';
import '../navigation/navigation_screen.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStreamSubscription;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {}; // ✅ Pour afficher l'itinéraire

  bool _isTrackingEnabled = true;
  bool _isOnline = true;
  bool _isLoadingPosition = true;
  bool _isLoadingRoute = false; // ✅ Loader pour calcul itinéraire

  // ✅ Infos de navigation
  String? _selectedDeliveryId;
  String? _routeDistance;
  String? _routeDuration;
  String? _routeETA;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    await _getCurrentPosition();
    await ref.read(deliveriesProvider.notifier).loadDeliveries();
    _startPositionTracking();
    _updateMarkers();
  }

  Future<void> _getCurrentPosition() async {
    setState(() => _isLoadingPosition = true);

    final position = await LocationService.getCurrentPosition();

    if (position != null) {
      setState(() {
        _currentPosition = position;
        _isLoadingPosition = false;
      });

      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 14,
          ),
        ),
      );

      AppLogger.info('✅ [MapScreen] Position GPS obtenue');
    } else {
      setState(() => _isLoadingPosition = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.location_off_rounded, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Impossible d\'obtenir votre position'),
                ),
              ],
            ),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _startPositionTracking() {
    if (!_isTrackingEnabled) return;

    _positionStreamSubscription = LocationService.getPositionStream().listen(
          (Position position) {
        setState(() {
          _currentPosition = position;
        });
        _updateMarkers();

        // ✅ Recalculer l'itinéraire si une destination est sélectionnée
        if (_selectedDeliveryId != null) {
          _calculateRoute(_selectedDeliveryId!);
        }
      },
      onError: (error) {
        AppLogger.error('❌ [MapScreen] Erreur suivi position', error);
      },
    );
  }

  void _stopPositionTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  void _updateMarkers() {
    final deliveriesState = ref.read(deliveriesProvider);
    final assignments = deliveriesState.acceptedOnly;

    setState(() {
      _markers.clear();

      // Marker position actuelle
      if (_currentPosition != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('current_position'),
            position: LatLng(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
            infoWindow: const InfoWindow(
              title: '📍 Ma position',
              snippet: 'Vous êtes ici',
            ),
          ),
        );
      }

      // Markers des livraisons
      for (var i = 0; i < assignments.length; i++) {
        final assignment = assignments[i];

        // ⚠️ Coordonnées fictives - Remplacez par les vraies
        final deliveryLat = 5.3599 + (i * 0.02);
        final deliveryLng = -3.9869 + (i * 0.03);

        _markers.add(
          Marker(
            markerId: MarkerId(assignment.order.uuid.toString()),
            position: LatLng(deliveryLat, deliveryLng),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              _selectedDeliveryId == assignment.order.uuid
                  ? BitmapDescriptor.hueGreen // Destination sélectionnée
                  : (assignment.isAccepted
                  ? BitmapDescriptor.hueOrange
                  : BitmapDescriptor.hueBlue),
            ),
            infoWindow: InfoWindow(
              title: '📦 ${assignment.order.orderNumber}',
              snippet: '${assignment.order.customerName} - ${assignment.order.zone?.name.toString()}',
            ),
            onTap: () => _showDeliveryDetails(assignment),
          ),
        );
      }
    });
  }

  /// ✅ Calculer l'itinéraire vers une livraison
  Future<void> _calculateRoute(String deliveryId) async {
    if (_currentPosition == null) return;

    setState(() {
      _isLoadingRoute = true;
      _selectedDeliveryId = deliveryId;
    });

    final deliveriesState = ref.read(deliveriesProvider);
    final assignment = deliveriesState.assignments.firstWhere(
          (a) => a.order.uuid == deliveryId,
    );

    // ⚠️ Coordonnées fictives - Remplacez par les vraies
    final index = deliveriesState.assignments.indexOf(assignment);
    final deliveryLat = 5.3599 + (index * 0.02);
    final deliveryLng = -3.9869 + (index * 0.03);

    final origin = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    final destination = LatLng(deliveryLat, deliveryLng);

    final directions = await NavigationService.getDirections(
      origin: origin,
      destination: destination,
    );

    if (directions != null) {
      // Décoder la polyline
      final polylinePoints = NavigationService.decodePolyline(
        directions['polyline'],
      );

      // Calculer l'heure d'arrivée
      final eta = NavigationService.calculateETA(
        directions['durationValue'],
      );

      setState(() {
        _routeDistance = directions['distance'];
        _routeDuration = directions['duration'];
        _routeETA = NavigationService.formatETA(eta);
        _isLoadingRoute = false;

        // Afficher la polyline sur la carte
        _polylines.clear();
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: polylinePoints,
            color: AppTheme.primaryRed,
            width: 5,
            patterns: [
              PatternItem.dash(20),
              PatternItem.gap(10),
            ],
          ),
        );
      });

      // Ajuster la caméra pour voir l'itinéraire complet
      _fitMapToRoute(polylinePoints);

      AppLogger.info('✅ [MapScreen] Itinéraire calculé');
    } else {
      setState(() => _isLoadingRoute = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de calculer l\'itinéraire'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  /// Ajuster la caméra pour afficher tout l'itinéraire
  void _fitMapToRoute(List<LatLng> points) {
    if (points.isEmpty) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }

  /// ✅ Démarrer la navigation avec Google Maps
  Future<void> _startNavigation(String deliveryId) async {
    final deliveriesState = ref.read(deliveriesProvider);
    final assignment = deliveriesState.assignments.firstWhere(
          (a) => a.order.uuid == deliveryId,
    );

    // Coordonnées (remplacez par les vraies)
    final index = deliveriesState.assignments.indexOf(assignment);
    final deliveryLat = 5.3599 + (index * 0.02);
    final deliveryLng = -3.9869 + (index * 0.03);

    final destination = LatLng(deliveryLat, deliveryLng);

    // ✅ Lancer l'écran de navigation in-app
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NavigationScreen(
          destination: destination,
          destinationName: assignment.order.customerName.toString(),
          destinationAddress: assignment.order.deliveryAddress.toString(),
        ),
      ),
    );
  }

  /// ✅ Afficher choix navigation (Google Maps ou Waze)
  Future<void> _showNavigationOptions(String deliveryId) async {
    final deliveriesState = ref.read(deliveriesProvider);
    final assignment = deliveriesState.assignments.firstWhere(
          (a) => a.order.uuid == deliveryId,
    );

    final index = deliveriesState.assignments.indexOf(assignment);
    final deliveryLat = 5.3599 + (index * 0.02);
    final deliveryLng = -3.9869 + (index * 0.03);
    final destination = LatLng(deliveryLat, deliveryLng);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppTheme.cardLight,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choisir une application',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 20),

            // Google Maps
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.map_rounded, color: AppTheme.info),
              ),
              title: const Text('Google Maps'),
              subtitle: const Text('Navigation avec guidage vocal'),
              onTap: () {
                Navigator.pop(context);
                _startNavigation(deliveryId);
              },
            ),

            const SizedBox(height: 8),

            // Waze
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.directions_car_rounded, color: AppTheme.warning),
              ),
              title: const Text('Waze'),
              subtitle: const Text('Navigation alternative'),
              onTap: () async {
                Navigator.pop(context);
                await NavigationService.launchWazeNavigation(
                  destination: destination,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeliveryDetails(assignment) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppTheme.cardLight,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Indicateur
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textGrey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Numéro de commande
            Text(
              assignment.order.orderNumber,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 16),

            // Infos client
            _buildInfoRow(
              Icons.person_rounded,
              'Client',
              assignment.order.customerName,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.phone_rounded,
              'Téléphone',
              assignment.order.customerPhone,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.location_on_rounded,
              'Livraison',
              assignment.order.deliveryAddress,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.map_rounded,
              'Zone',
              assignment.order.zone.name,
            ),

            // Infos d'itinéraire si calculé
            if (_selectedDeliveryId == assignment.order.uuid && _routeDistance != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.info.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildRouteInfo(
                          Icons.straighten_rounded,
                          'Distance',
                          _routeDistance!,
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: AppTheme.textGrey.withOpacity(0.3),
                        ),
                        _buildRouteInfo(
                          Icons.access_time_rounded,
                          'Durée',
                          _routeDuration!,
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: AppTheme.textGrey.withOpacity(0.3),
                        ),
                        _buildRouteInfo(
                          Icons.schedule_rounded,
                          'Arrivée',
                          _routeETA!,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // ✅ Boutons d'action (MODIFIÉ)
            Row(
              children: [
                // Calculer l'itinéraire
                if (_selectedDeliveryId != assignment.order.uuid)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoadingRoute
                          ? null
                          : () {
                        Navigator.pop(context);
                        _calculateRoute(assignment.order.uuid);
                      },
                      icon: _isLoadingRoute
                          ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Icon(Icons.route_rounded),
                      label: const Text('Itinéraire'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.info,
                        side: const BorderSide(color: AppTheme.info),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),

                if (_selectedDeliveryId == assignment.order.uuid) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedDeliveryId = null;
                          _polylines.clear();
                          _routeDistance = null;
                          _routeDuration = null;
                          _routeETA = null;
                        });
                        Navigator.pop(context);
                        _updateMarkers();
                      },
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Annuler'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.error,
                        side: const BorderSide(color: AppTheme.error),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],

                // ✅ MODIFIÉ : Appel direct de _startNavigation
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _startNavigation(assignment.order.uuid); // ✅ Direct
                    },
                    icon: const Icon(Icons.navigation_rounded),
                    label: const Text('Démarrer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryRed,
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

  Widget _buildRouteInfo(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppTheme.info),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryRed.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppTheme.primaryRed),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textGrey,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _centerOnCurrentPosition() {
    if (_currentPosition != null) {
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
            ),
            zoom: 14,
          ),
        ),
      );
    } else {
      _getCurrentPosition();
    }
  }

  void _toggleTracking() {
    setState(() {
      _isTrackingEnabled = !_isTrackingEnabled;
    });

    if (_isTrackingEnabled) {
      _startPositionTracking();
    } else {
      _stopPositionTracking();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _isTrackingEnabled
                  ? Icons.gps_fixed_rounded
                  : Icons.gps_off_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Text(_isTrackingEnabled
                ? 'Suivi de position activé'
                : 'Suivi de position désactivé'),
          ],
        ),
        backgroundColor: _isTrackingEnabled ? AppTheme.success : AppTheme.textGrey,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _toggleOnlineStatus() {
    setState(() {
      _isOnline = !_isOnline;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Text(_isOnline ? 'Vous êtes en ligne' : 'Vous êtes hors ligne'),
          ],
        ),
        backgroundColor: _isOnline ? AppTheme.success : AppTheme.textGrey,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(deliveriesProvider, (previous, next) {
      if (next.hasData) {
        _updateMarkers();
      }
    });

    final deliveriesState = ref.watch(deliveriesProvider);
    final activeDeliveries = deliveriesState.acceptedOnly.length;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Carte'),
        backgroundColor: AppTheme.cardLight,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _isOnline
                      ? AppTheme.success.withOpacity(0.12)
                      : AppTheme.textGrey.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isOnline
                        ? AppTheme.success.withOpacity(0.3)
                        : AppTheme.textGrey.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _isOnline ? AppTheme.success : AppTheme.textGrey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isOnline ? 'En ligne' : 'Hors ligne',
                      style: TextStyle(
                        color: _isOnline ? AppTheme.success : AppTheme.textGrey,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoadingPosition
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryRed),
            SizedBox(height: 16),
            Text(
              'Récupération de votre position...',
              style: TextStyle(color: AppTheme.textGrey),
            ),
          ],
        ),
      )
          : Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _currentPosition != null
                  ? LatLng(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
              )
                  : const LatLng(5.3599, -3.9869),
              zoom: 12,
            ),
            markers: _markers,
            polylines: _polylines, // ✅ Afficher l'itinéraire
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
          ),

          // Card overlay avec infos navigation
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.cardLight,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
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
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryRed.withOpacity(0.15),
                              AppTheme.accentRed.withOpacity(0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.local_shipping_rounded,
                          color: AppTheme.primaryRed,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Livraisons actives',
                              style: TextStyle(
                                color: AppTheme.textGrey,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '$activeDeliveries en cours',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Transform.scale(
                        scale: 0.9,
                        child: Switch(
                          value: _isTrackingEnabled,
                          onChanged: (value) => _toggleTracking(),
                          activeColor: AppTheme.primaryRed,
                        ),
                      ),
                    ],
                  ),

                  // ✅ Infos d'itinéraire si navigation active
                  if (_selectedDeliveryId != null && _routeDistance != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.info.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.info.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildQuickInfo(Icons.straighten_rounded, _routeDistance!),
                          _buildQuickInfo(Icons.access_time_rounded, _routeDuration!),
                          _buildQuickInfo(Icons.schedule_rounded, 'ETA $_routeETA'),
                        ],
                      ),
                    ),
                  ] else if (_isTrackingEnabled) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.success.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.gps_fixed_rounded,
                            size: 16,
                            color: AppTheme.success,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Position partagée en temps réel',
                              style: TextStyle(
                                color: AppTheme.success,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Boutons d'action
          Positioned(
            right: 16,
            bottom: 100,
            child: Column(
              children: [
                _buildActionButton(
                  Icons.my_location_rounded,
                  AppTheme.primaryRed,
                  _centerOnCurrentPosition,
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  Icons.refresh_rounded,
                  AppTheme.info,
                      () {
                    ref.read(deliveriesProvider.notifier).refreshDeliveries();
                    _updateMarkers();
                  },
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  _isOnline
                      ? Icons.power_settings_new_rounded
                      : Icons.power_off_rounded,
                  _isOnline ? AppTheme.success : AppTheme.textGrey,
                  _toggleOnlineStatus,
                ),
              ],
            ),
          ),

          // Légende
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardLight,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Légende',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildLegendItem(Colors.red, 'Ma position'),
                  const SizedBox(height: 8),
                  _buildLegendItem(Colors.green, 'Destination'),
                  const SizedBox(height: 8),
                  _buildLegendItem(Colors.orange, 'En cours'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.info),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.info,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onPressed) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            color.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.textDark,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _stopPositionTracking();
    _mapController?.dispose();
    super.dispose();
  }
}