import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/models/delivery/assignment.dart';
import '../../data/providers/today_orders_provider.dart';
import '../../data/services/location_service.dart';
import '../../data/services/navigation_service.dart';
import '../../network/config/app_logger.dart';
import '../../theme/app_theme.dart';
import '../navigation/navigation_screen.dart';

class MapWithOrdersScreen extends ConsumerStatefulWidget {
  const MapWithOrdersScreen({super.key});

  @override
  ConsumerState<MapWithOrdersScreen> createState() => _MapWithOrdersScreenState();
}

class _MapWithOrdersScreenState extends ConsumerState<MapWithOrdersScreen>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStreamSubscription;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  bool _isTrackingEnabled = true;
  bool _isLoadingPosition = true;
  bool _isLoadingRoute = false;

  String? _selectedOrderId;
  String? _routeDistance;
  String? _routeDuration;
  String? _routeETA;

  // ✅ Bottom Sheet
  late AnimationController _sheetController;
  double _sheetPosition = 0.3; // 0 = minimisé, 0.5 = moyen, 1 = maximisé
  final _sheetMinHeight = 120.0;
  final _sheetMediumHeight = 0.4;
  final _sheetMaxHeight = 0.85;

  // ✅ Filtres
  String? _selectedFilter; // null = toutes, 'assigned', 'accepted', etc.

  @override
  void initState() {
    super.initState();
    _sheetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    await _getCurrentPosition();
    await ref.read(todayOrdersProvider.notifier).loadTodayOrders();
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
    } else {
      setState(() => _isLoadingPosition = false);
    }
  }

  void _startPositionTracking() {
    if (!_isTrackingEnabled) return;

    _positionStreamSubscription = LocationService.getPositionStream().listen(
          (Position position) {
        setState(() => _currentPosition = position);
        _updateMarkers();

        if (_selectedOrderId != null) {
          _calculateRoute(_selectedOrderId!);
        }
      },
    );
  }

  void _stopPositionTracking() {
    _positionStreamSubscription?.cancel();
  }

  void _updateMarkers() {
    final ordersState = ref.read(todayOrdersProvider);
    final orders = _selectedFilter == null
        ? ordersState.orders
        : ordersState.orders.where((o) => o.assignmentStatus == _selectedFilter).toList();

    setState(() {
      _markers.clear();

      // Marker position actuelle
      if (_currentPosition != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('current_position'),
            position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: const InfoWindow(title: '📍 Ma position'),
          ),
        );
      }

      // Markers des courses
      for (var i = 0; i < orders.length; i++) {
        final order = orders[i];

        // ⚠️ Remplacez par les vraies coordonnées depuis order.deliveryLatitude, order.deliveryLongitude
        final lat = 5.3599 + (i * 0.02);
        final lng = -3.9869 + (i * 0.03);

        _markers.add(
          Marker(
            markerId: MarkerId(order.order.uuid),
            position: LatLng(lat, lng),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              _selectedOrderId == order.order.uuid
                  ? BitmapDescriptor.hueGreen
                  : order.isAccepted
                  ? BitmapDescriptor.hueOrange
                  : BitmapDescriptor.hueBlue,
            ),
            infoWindow: InfoWindow(
              title: order.order.isExpress ? '⚡ ${order.order.orderNumber}' : '📦 ${order.order.orderNumber}',
              snippet: order.order.customerName,
            ),
            onTap: () => _selectOrder(order.order.uuid),
          ),
        );
      }
    });
  }

  void _selectOrder(String orderId) {
    setState(() {
      if (_selectedOrderId == orderId) {
        // Désélectionner
        _selectedOrderId = null;
        _polylines.clear();
        _routeDistance = null;
        _routeDuration = null;
        _routeETA = null;
      } else {
        // Sélectionner et calculer itinéraire
        _selectedOrderId = orderId;
        _calculateRoute(orderId);
      }
      _updateMarkers();
    });

    // Ouvrir le bottom sheet en mode moyen
    _animateSheet(_sheetMediumHeight);
  }

  Future<void> _calculateRoute(String orderId) async {
    if (_currentPosition == null) return;

    setState(() => _isLoadingRoute = true);

    final ordersState = ref.read(todayOrdersProvider);
    final order = ordersState.orders.firstWhere((o) => o.order.uuid == orderId);
    final index = ordersState.orders.indexOf(order);

    // ⚠️ Remplacez par les vraies coordonnées
    final lat = 5.3599 + (index * 0.02);
    final lng = -3.9869 + (index * 0.03);

    final origin = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    final destination = LatLng(lat, lng);

    final directions = await NavigationService.getDirections(
      origin: origin,
      destination: destination,
    );

    if (directions != null) {
      final polylinePoints = NavigationService.decodePolyline(directions['polyline']);
      final eta = NavigationService.calculateETA(directions['durationValue']);

      setState(() {
        _routeDistance = directions['distance'];
        _routeDuration = directions['duration'];
        _routeETA = NavigationService.formatETA(eta);
        _isLoadingRoute = false;

        _polylines.clear();
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: polylinePoints,
            color: AppTheme.primaryRed,
            width: 5,
          ),
        );
      });

      _fitMapToRoute(polylinePoints);
    } else {
      setState(() => _isLoadingRoute = false);
    }
  }

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

  void _animateSheet(double target) {
    setState(() => _sheetPosition = target);
  }

  void _centerOnCurrentPosition() {
    if (_currentPosition != null) {
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            zoom: 14,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(todayOrdersProvider);
    final screenHeight = MediaQuery.of(context).size.height;

    // Filtrer les courses
    final filteredOrders = _selectedFilter == null
        ? ordersState.orders
        : ordersState.orders.where((o) => o.assignmentStatus == _selectedFilter).toList();

    return Scaffold(
      body: Stack(
        children: [
          // Carte Google Maps
          _isLoadingPosition
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed))
              : GoogleMap(
            onMapCreated: (controller) => _mapController = controller,
            initialCameraPosition: CameraPosition(
              target: _currentPosition != null
                  ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                  : const LatLng(5.3599, -3.9869),
              zoom: 12,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          // Header stats overlay
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(child: _buildQuickStat('Total', ordersState.totalOrders, AppTheme.info)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildQuickStat('Assignées', ordersState.assignedCount, AppTheme.warning)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildQuickStat('Acceptées', ordersState.acceptedCount, AppTheme.success)),
                ],
              ),
            ),
          ),

          // Boutons d'action
          Positioned(
            right: 16,
            bottom: screenHeight * _sheetPosition + 100,
            child: Column(
              children: [
                _buildActionButton(Icons.my_location_rounded, AppTheme.primaryRed, _centerOnCurrentPosition),
                const SizedBox(height: 12),
                _buildActionButton(Icons.refresh_rounded, AppTheme.info, () {
                  ref.read(todayOrdersProvider.notifier).refreshTodayOrders();
                  _updateMarkers();
                }),
              ],
            ),
          ),

          // ✅ Bottom Sheet avec liste des courses
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left: 0,
            right: 0,
            bottom: 0,
            height: screenHeight * _sheetPosition,
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                setState(() {
                  _sheetPosition = (_sheetPosition - details.delta.dy / screenHeight)
                      .clamp(_sheetMinHeight / screenHeight, _sheetMaxHeight);
                });
              },
              onVerticalDragEnd: (details) {
                if (details.velocity.pixelsPerSecond.dy > 300) {
                  _animateSheet(_sheetMinHeight / screenHeight);
                } else if (details.velocity.pixelsPerSecond.dy < -300) {
                  _animateSheet(_sheetMaxHeight);
                } else if (_sheetPosition < 0.25) {
                  _animateSheet(_sheetMinHeight / screenHeight);
                } else if (_sheetPosition < 0.6) {
                  _animateSheet(_sheetMediumHeight);
                } else {
                  _animateSheet(_sheetMaxHeight);
                }
              },
              child: Container(
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
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Handle
                    GestureDetector(
                      onTap: () {
                        if (_sheetPosition < 0.5) {
                          _animateSheet(_sheetMaxHeight);
                        } else {
                          _animateSheet(_sheetMinHeight / screenHeight);
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppTheme.textGrey.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Titre et filtres
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          const Text(
                            'Courses du jour',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${filteredOrders.length}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryRed,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Filtres
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          _buildFilterChip('Toutes', null),
                          _buildFilterChip('Assignées', 'assigned'),
                          _buildFilterChip('Acceptées', 'accepted'),
                          _buildFilterChip('En transit', 'in_transit'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Liste des courses
                    Expanded(
                      child: _buildOrdersList(filteredOrders),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.textGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onPressed) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
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

  Widget _buildFilterChip(String label, String? value) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedFilter = value;
            _updateMarkers();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(colors: [AppTheme.primaryRed, AppTheme.accentRed])
                : null,
            color: isSelected ? null : AppTheme.backgroundLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Colors.transparent : AppTheme.textGrey.withOpacity(0.2),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.textGrey,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersList(List<Assignment> orders) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 60, color: AppTheme.textGrey.withOpacity(0.3)),
            const SizedBox(height: 12),
            Text(
              'Aucune course',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textGrey.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: orders.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = orders[index];
        final isSelected = _selectedOrderId == order.order.uuid;

        return _buildCompactOrderCard(order, isSelected);
      },
    );
  }

  Widget _buildCompactOrderCard(Assignment order, bool isSelected) {
    return GestureDetector(
      onTap: () => _selectOrder(order.order.uuid),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryRed.withOpacity(0.05) : AppTheme.backgroundLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryRed : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (order.order.isExpress)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryRed,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt_rounded, color: Colors.white, size: 12),
                        SizedBox(width: 2),
                        Text(
                          'EXPRESS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.order.orderNumber,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppTheme.primaryRed : AppTheme.textDark,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: order.isAccepted
                        ? AppTheme.success.withOpacity(0.1)
                        : AppTheme.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    order.statusDisplay,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: order.isAccepted ? AppTheme.success : AppTheme.warning,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person_rounded, size: 14, color: AppTheme.textGrey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    order.order.customerName,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_rounded, size: 14, color: AppTheme.primaryRed),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    order.order.deliveryAddress,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textGrey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // Infos de route si sélectionné
            if (isSelected && _routeDistance != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMiniRouteInfo(Icons.straighten_rounded, _routeDistance!),
                    _buildMiniRouteInfo(Icons.access_time_rounded, _routeDuration!),
                    _buildMiniRouteInfo(Icons.schedule_rounded, _routeETA!),
                  ],
                ),
              ),
            ],

            // Actions
            if (isSelected) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (order.isAssigned) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final success = await ref
                              .read(todayOrdersProvider.notifier)
                              .rejectOrder(order.order.uuid);
                          if (success) {
                            setState(() {
                              _selectedOrderId = null;
                              _polylines.clear();
                            });
                            _updateMarkers();
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.error,
                          side: const BorderSide(color: AppTheme.error),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: const Text('Refuser', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () async {
                          final success = await ref
                              .read(todayOrdersProvider.notifier)
                              .acceptOrder(order.order.uuid);
                          if (success) _updateMarkers();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.success,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: const Text('Accepter', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ] else if (order.isAccepted) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final ordersState = ref.read(todayOrdersProvider);
                          final index = ordersState.orders.indexOf(order);
                          final lat = 5.3599 + (index * 0.02);
                          final lng = -3.9869 + (index * 0.03);

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NavigationScreen(
                                destination: LatLng(lat, lng),
                                destinationName: order.order.customerName,
                                destinationAddress: order.order.deliveryAddress,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.navigation_rounded, size: 16),
                        label: const Text('Démarrer', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryRed,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMiniRouteInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppTheme.info),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.info,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _stopPositionTracking();
    _sheetController.dispose();
    _mapController?.dispose();
    super.dispose();
  }
}