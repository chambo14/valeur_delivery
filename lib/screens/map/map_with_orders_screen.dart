// screens/map_with_orders_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/models/delivery/assignment.dart';
import '../../data/providers/courier_location_provider.dart';
import '../../data/providers/today_orders_provider.dart';
import '../../data/services/geocoding_service.dart';
import '../../data/services/location_service.dart';
import '../../data/services/navigation_service.dart';
import '../../data/services/notification_service.dart';
import '../../network/config/app_logger.dart';
import '../../theme/app_theme.dart';
import '../navigation/navigation_screen.dart';
import '../widget/new_order_notification.dart';

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
  bool _isRefreshing = false;

  String? _selectedOrderId;
  String? _routeDistance;
  String? _routeDuration;
  String? _routeETA;

  late AnimationController _sheetController;
  double _sheetPosition = 0.3;
  final _sheetMinHeight = 120.0;
  final _sheetMediumHeight = 0.4;
  final _sheetMaxHeight = 0.85;

  String? _selectedFilter;

  Timer? _autoRefreshTimer;
  DateTime? _lastRefreshTime;

  @override
  void initState() {
    super.initState();
    _sheetController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _initializeNotificationService();
    _initializeMap();
    _startAutoRefresh();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(courierLocationProvider.notifier).startLocationSharing(
        intervalSeconds: 30,
      );
    });
  }

  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(
      const Duration(minutes: 2),
          (timer) {
        if (mounted && !_isRefreshing) {
          AppLogger.info('🔄 [MapWithOrdersScreen] Rafraîchissement automatique');
          _refreshOrders(showSnackbar: false);
        }
      },
    );
  }

  Future<void> _initializeNotificationService() async {
    try {
      await NotificationService.initialize();
      AppLogger.info('✅ [MapWithOrdersScreen] NotificationService initialisé');
    } catch (e) {
      AppLogger.error('❌ [MapWithOrdersScreen] Erreur init NotificationService', e);
    }
  }

  Future<void> _initializeMap() async {
    await _getCurrentPosition();
    await ref.read(todayOrdersProvider.notifier).loadTodayOrders();
    _startPositionTracking();
    await _updateMarkers();
    _lastRefreshTime = DateTime.now();
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

  Future<void> _refreshOrders({bool showSnackbar = true}) async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);

    AppLogger.info('🔄 [MapWithOrdersScreen] Rafraîchissement des courses...');

    try {
      await ref.read(todayOrdersProvider.notifier).refreshTodayOrders();
      await _updateMarkers();
      await _getCurrentPosition();

      setState(() {
        _lastRefreshTime = DateTime.now();
        _isRefreshing = false;
      });

      AppLogger.info('✅ [MapWithOrdersScreen] Rafraîchissement réussi');

      if (showSnackbar && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 12),
                Text('Courses actualisées'),
              ],
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      AppLogger.error('❌ [MapWithOrdersScreen] Erreur rafraîchissement', e);

      setState(() => _isRefreshing = false);

      if (showSnackbar && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Erreur: $e')),
              ],
            ),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _updateMarkers() async {
    final ordersState = ref.read(todayOrdersProvider);

    // ✅ CORRIGÉ : Utiliser orders au lieu de assignments
    final filteredAssignments = _selectedFilter == null
        ? ordersState.orders
        : ordersState.orders
        .where((a) => a.assignmentStatus?.toLowerCase() == _selectedFilter)
        .toList();

    setState(() {
      _markers.clear();

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
            infoWindow: const InfoWindow(title: '📍 Ma position'),
          ),
        );
      }
    });

    for (final assignment in filteredAssignments) {
      final order = assignment.order;
      LatLng? coordinates;

      // ✅ CORRIGÉ : Utiliser hasDeliveryCoordinates et les champs plats
      if (order.hasDeliveryCoordinates) {
        coordinates = LatLng(
          order.deliveryLatitude!,
          order.deliveryLongitude!,
        );
      } else if ((order.deliveryAddress ?? '').isNotEmpty) {
        coordinates = await GeocodingService.getCoordinatesFromAddress(
          order.deliveryAddress!,
        );

        if (coordinates == null) continue;
      } else {
        continue;
      }

      setState(() {
        _markers.add(
          Marker(
            markerId: MarkerId(order.uuid),
            position: coordinates!,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              _selectedOrderId == order.uuid
                  ? BitmapDescriptor.hueGreen
                  : assignment.isAccepted
                  ? BitmapDescriptor.hueOrange
                  : BitmapDescriptor.hueBlue,
            ),
            infoWindow: InfoWindow(
              title: order.isExpress
                  ? '⚡ ${order.orderNumber}'
                  : '📦 ${order.orderNumber}',
              snippet: order.customerName,
            ),
            onTap: () => _selectOrder(order.uuid),
          ),
        );
      });
    }
  }

  void _selectOrder(String? orderId) {
    if (orderId == null || orderId.isEmpty) return;

    setState(() {
      if (_selectedOrderId == orderId) {
        _selectedOrderId = null;
        _polylines.clear();
        _routeDistance = null;
        _routeDuration = null;
        _routeETA = null;
      } else {
        _selectedOrderId = orderId;
        _calculateRoute(orderId);
      }
      _updateMarkers();
    });

    _animateSheet(_sheetMediumHeight);
  }

  Future<void> _calculateRoute(String? orderId) async {
    if (_currentPosition == null || orderId == null) return;

    setState(() => _isLoadingRoute = true);

    final ordersState = ref.read(todayOrdersProvider);

    // ✅ CORRIGÉ : Utiliser orders et order.uuid
    final assignment = ordersState.orders.firstWhereOrNull(
          (a) => a.order.uuid == orderId,
    );

    if (assignment == null) {
      setState(() => _isLoadingRoute = false);
      return;
    }

    final order = assignment.order;
    LatLng? destination;

    // ✅ CORRIGÉ : Utiliser hasDeliveryCoordinates
    if (order.hasDeliveryCoordinates) {
      destination = LatLng(
        order.deliveryLatitude!,
        order.deliveryLongitude!,
      );
    } else if ((order.deliveryAddress ?? '').isNotEmpty) {
      destination = await GeocodingService.getCoordinatesFromAddress(
        order.deliveryAddress!,
      );

      if (destination == null) {
        setState(() => _isLoadingRoute = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_rounded, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Impossible de localiser: ${order.deliveryAddress}',
                    ),
                  ),
                ],
              ),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
    } else {
      setState(() => _isLoadingRoute = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_rounded, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Adresse de livraison manquante')),
              ],
            ),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final origin = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);

    final directions = await NavigationService.getDirections(
      origin: origin,
      destination: destination,
    );

    if (directions != null) {
      final polylinePoints =
      NavigationService.decodePolyline(directions['polyline']);
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_rounded, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Impossible de calculer l\'itinéraire')),
              ],
            ),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
            target: LatLng(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
            ),
            zoom: 14,
          ),
        ),
      );
    }
  }

  Future<void> _testNotifications() async {
    try {
      AppLogger.info('🧪 [MapWithOrdersScreen] Test notifications');

      await NotificationService.playNotificationSound();
      await NotificationService.vibrate();

      await Future.delayed(const Duration(milliseconds: 800));
      await NotificationService.speak(
        'Ceci est un test de notification vocale pour Valeur Delivery',
      );

      await Future.delayed(const Duration(seconds: 2));
      await NotificationService.announceNewOrder(
        orderNumber: 'TEST-001',
        customerName: 'Client de Test',
        isExpress: true,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 12),
                Text('Test de notification terminé'),
              ],
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      AppLogger.error('❌ [MapWithOrdersScreen] Erreur test notifications', e);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Erreur test: $e')),
              ],
            ),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _formatRefreshTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inSeconds < 60) {
      return 'il y a ${difference.inSeconds}s';
    } else if (difference.inMinutes < 60) {
      return 'il y a ${difference.inMinutes}min';
    } else {
      return 'il y a ${difference.inHours}h';
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(todayOrdersProvider);
    final screenHeight = MediaQuery.of(context).size.height;

    // Écouter les nouvelles courses
    ref.listen<TodayOrdersState>(todayOrdersProvider, (previous, next) {
      if (next.newOrder != null && mounted) {
        AppLogger.info(
          '🔔 [MapWithOrdersScreen] Affichage notification nouvelle course',
        );

        showNewOrderNotification(context, next.newOrder!);

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            ref.read(todayOrdersProvider.notifier).clearNewOrderNotification();
          }
        });

        _updateMarkers();
      }
    });

    // ✅ CORRIGÉ : Utiliser orders
    final filteredAssignments = _selectedFilter == null
        ? ordersState.orders
        : ordersState.orders
        .where((a) => a.assignmentStatus?.toLowerCase() == _selectedFilter)
        .toList();

    return Scaffold(
      body: Stack(
        children: [
          // Map
          _isLoadingPosition
              ? const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryRed),
          )
              : GoogleMap(
            onMapCreated: (controller) => _mapController = controller,
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
            polylines: _polylines,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          // Indicateur de rafraîchissement
          if (_isRefreshing)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.cardLight,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primaryRed,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Actualisation...',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Stats en haut
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickStat(
                          'Total',
                          ordersState.totalOrders, // ✅ CORRIGÉ
                          AppTheme.info,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildQuickStat(
                          'Assignées',
                          ordersState.assignedCount,
                          AppTheme.warning,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildQuickStat(
                          'Acceptées',
                          ordersState.acceptedCount,
                          AppTheme.success,
                        ),
                      ),
                    ],
                  ),
                  if (_lastRefreshTime != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Actualisation: ${_formatRefreshTime(_lastRefreshTime!)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.textGrey.withOpacity(0.7),
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
            bottom: screenHeight * _sheetPosition + 100,
            child: Column(
              children: [
                _buildActionButton(
                  Icons.my_location_rounded,
                  AppTheme.primaryRed,
                  _centerOnCurrentPosition,
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  _isRefreshing
                      ? Icons.hourglass_bottom_rounded
                      : Icons.refresh_rounded,
                  AppTheme.info,
                  _isRefreshing ? null : () => _refreshOrders(),
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  Icons.volume_up,
                  AppTheme.warning,
                  _testNotifications,
                ),
              ],
            ),
          ),

          // Bottom Sheet
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
                  _sheetPosition =
                      (_sheetPosition - details.delta.dy / screenHeight).clamp(
                        _sheetMinHeight / screenHeight,
                        _sheetMaxHeight,
                      );
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
                  mainAxisSize: MainAxisSize.min,
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

                    // Titre
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
                            '${filteredAssignments.length}',
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
                          _buildFilterChip('En transit', 'delivering'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Liste des commandes
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => _refreshOrders(showSnackbar: false),
                        color: AppTheme.primaryRed,
                        child: _buildOrdersList(filteredAssignments),
                      ),
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

  Widget _buildActionButton(
      IconData icon,
      Color color,
      VoidCallback? onPressed,
      ) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: onPressed != null
            ? LinearGradient(
          colors: [color, color.withOpacity(0.8)],
        )
            : null,
        color: onPressed == null ? AppTheme.textGrey.withOpacity(0.3) : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: onPressed != null
            ? [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ]
            : null,
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
                ? const LinearGradient(
              colors: [AppTheme.primaryRed, AppTheme.accentRed],
            )
                : null,
            color: isSelected ? null : AppTheme.backgroundLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : AppTheme.textGrey.withOpacity(0.2),
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

  Widget _buildOrdersList(List<Assignment> assignments) {
    if (assignments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_rounded,
              size: 60,
              color: AppTheme.textGrey.withOpacity(0.3),
            ),
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
      itemCount: assignments.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final assignment = assignments[index];
        final isSelected = _selectedOrderId == assignment.order.uuid;

        return _buildCompactOrderCard(assignment, isSelected);
      },
    );
  }

  Widget _buildCompactOrderCard(Assignment assignment, bool isSelected) {
    final order = assignment.order;

    return GestureDetector(
      onTap: () => _selectOrder(order.uuid),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryRed.withOpacity(0.05)
              : AppTheme.backgroundLight,
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
                // ✅ CORRIGÉ : isExpress n'est pas nullable
                if (order.isExpress)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
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
                    order.orderNumber ?? 'N/A',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppTheme.primaryRed : AppTheme.textDark,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: assignment.isAccepted
                        ? AppTheme.success.withOpacity(0.1)
                        : AppTheme.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    assignment.statusDisplay,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: assignment.isAccepted
                          ? AppTheme.success
                          : AppTheme.warning,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.person_rounded,
                  size: 14,
                  color: AppTheme.textGrey,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    order.customerName ?? 'Client',
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
                const Icon(
                  Icons.location_on_rounded,
                  size: 14,
                  color: AppTheme.primaryRed,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    order.deliveryAddress ?? 'Adresse inconnue',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textGrey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // Route info
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

            // Action buttons
            if (isSelected) ...[
              const SizedBox(height: 12),
              // Dans _buildCompactOrderCard - section des boutons d'action

              if (isSelected) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (assignment.isAssigned) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final success = await ref
                                .read(todayOrdersProvider.notifier)
                                .rejectOrder(
                              assignment.assignmentUuid ?? '',
                              latitude: _currentPosition?.latitude,
                              longitude: _currentPosition?.longitude,
                            );
                            if (success) {
                              setState(() {
                                _selectedOrderId = null;
                                _polylines.clear();
                                _routeDistance = null;
                                _routeDuration = null;
                                _routeETA = null;
                              });
                              _updateMarkers();
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.error,
                            side: const BorderSide(color: AppTheme.error),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: const Text(
                            'Refuser',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () async {
                            final success = await ref
                                .read(todayOrdersProvider.notifier)
                                .acceptOrder(
                              assignment.assignmentUuid ?? '',
                              latitude: _currentPosition?.latitude,
                              longitude: _currentPosition?.longitude,
                            );
                            if (success) _updateMarkers();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.success,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: const Text(
                            'Accepter',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ] else if (assignment.isAccepted) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (!order.hasDeliveryCoordinates) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Coordonnées de livraison manquantes'),
                                  backgroundColor: AppTheme.error,
                                ),
                              );
                              return;
                            }

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => NavigationScreen(
                                  destination: LatLng(
                                    order.deliveryLatitude!,
                                    order.deliveryLongitude!,
                                  ),
                                  destinationName: order.customerName ?? 'Destination',
                                  destinationAddress: order.deliveryAddress ?? '',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.navigation_rounded, size: 16),
                          label: const Text(
                            'Démarrer',
                            style: TextStyle(fontSize: 12),
                          ),
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
    _autoRefreshTimer?.cancel();
    _sheetController.dispose();
    _mapController?.dispose();
    ref.read(courierLocationProvider.notifier).stopLocationSharing();
    NotificationService.dispose();
    super.dispose();
  }
}

// Extension pour firstWhereOrNull
extension FirstWhereOrNullExtension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}