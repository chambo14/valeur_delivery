// providers/today_orders_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../network/config/app_logger.dart';
import '../../network/repository/delivery_repository.dart';
import '../models/delivery/assignment.dart';
import '../services/notification_service.dart';
import 'api_provider.dart';

/// État pour les courses du jour
class TodayOrdersState {
  final bool isLoading;
  final List<Assignment> orders;
  final String? errorMessage;
  final bool isRefreshing;
  final DateTime? lastUpdated;
  final Assignment? newOrder;

  const TodayOrdersState({
    this.isLoading = false,
    this.orders = const [],
    this.errorMessage,
    this.isRefreshing = false,
    this.lastUpdated,
    this.newOrder,
  });

  TodayOrdersState copyWith({
    bool? isLoading,
    List<Assignment>? orders,
    String? errorMessage,
    bool? isRefreshing,
    DateTime? lastUpdated,
    Assignment? newOrder,
    bool clearNewOrder = false,
    bool clearError = false,
  }) {
    return TodayOrdersState(
      isLoading: isLoading ?? this.isLoading,
      orders: orders ?? this.orders,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isRefreshing: isRefreshing ?? this.isRefreshing,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      newOrder: clearNewOrder ? null : (newOrder ?? this.newOrder),
    );
  }

  // Helpers
  bool get hasData => orders.isNotEmpty;
  bool get hasError => errorMessage != null;
  int get totalOrders => orders.length;

  // Filtres par statut
  List<Assignment> get assignedOrders =>
      orders.where((a) => a.isAssigned).toList();

  List<Assignment> get acceptedOrders =>
      orders.where((a) => a.isAccepted).toList();

  List<Assignment> get pickedOrders =>
      orders.where((a) => a.isPicked).toList();

  List<Assignment> get deliveringOrders =>
      orders.where((a) => a.isDelivering).toList();

  List<Assignment> get completedOrders =>
      orders.where((a) => a.isCompleted).toList();

  List<Assignment> get expressOrders =>
      orders.where((a) => a.order.isExpress).toList();

  // Compteurs
  int get assignedCount => assignedOrders.length;
  int get acceptedCount => acceptedOrders.length;
  int get pickedCount => pickedOrders.length;
  int get deliveringCount => deliveringOrders.length;
  int get completedCount => completedOrders.length;
  int get expressCount => expressOrders.length;

  // Courses en cours (non terminées)
  List<Assignment> get activeOrders => orders
      .where((a) => !a.isCompleted && !a.isCancelled && !a.isFailed)
      .toList();

  int get activeCount => activeOrders.length;
}

/// Notifier pour les courses du jour
class TodayOrdersNotifier extends StateNotifier<TodayOrdersState> {
  final DeliveryRepository _deliveryRepository;
  List<String> _previousOrderIds = [];

  TodayOrdersNotifier(this._deliveryRepository) : super(const TodayOrdersState());

  /// Charger les courses du jour
  Future<void> loadTodayOrders() async {
    AppLogger.info('📅 [TodayOrdersNotifier] Chargement des courses du jour');

    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _deliveryRepository.getTodayOrders();

    result.fold(
          (error) {
        AppLogger.error('❌ [TodayOrdersNotifier] Erreur: $error');
        state = state.copyWith(
          isLoading: false,
          errorMessage: error,
        );
      },
          (todayOrdersResponse) {
        final orders = todayOrdersResponse.data;

        AppLogger.info('✅ [TodayOrdersNotifier] ${orders.length} courses chargées');
        AppLogger.debug('   - Assignées: ${todayOrdersResponse.assignedCount}');
        AppLogger.debug('   - Acceptées: ${todayOrdersResponse.acceptedCount}');
        AppLogger.debug('   - Express: ${todayOrdersResponse.expressCount}');

        _detectNewOrders(orders);

        _previousOrderIds = orders
            .map((o) => o.assignmentUuid ?? '')
            .where((id) => id.isNotEmpty)
            .toList();

        state = state.copyWith(
          isLoading: false,
          orders: orders,
          lastUpdated: DateTime.now(),
          clearError: true,
        );
      },
    );
  }

  /// Rafraîchir les courses du jour
  Future<void> refreshTodayOrders() async {
    AppLogger.info('🔄 [TodayOrdersNotifier] Rafraîchissement des courses');

    state = state.copyWith(isRefreshing: true, clearError: true);

    final result = await _deliveryRepository.getTodayOrders();

    result.fold(
          (error) {
        AppLogger.error('❌ [TodayOrdersNotifier] Erreur refresh: $error');
        state = state.copyWith(
          isRefreshing: false,
          errorMessage: error,
        );
      },
          (todayOrdersResponse) {
        final orders = todayOrdersResponse.data;

        AppLogger.info('✅ [TodayOrdersNotifier] Rafraîchissement réussi: ${orders.length} courses');

        _detectNewOrders(orders);

        _previousOrderIds = orders
            .map((o) => o.assignmentUuid ?? '')
            .where((id) => id.isNotEmpty)
            .toList();

        state = state.copyWith(
          isRefreshing: false,
          orders: orders,
          lastUpdated: DateTime.now(),
          clearError: true,
        );
      },
    );
  }

  void _detectNewOrders(List<Assignment> currentOrders) {
    if (_previousOrderIds.isEmpty) {
      AppLogger.debug('📋 [TodayOrdersNotifier] Premier chargement, pas de notification');
      return;
    }

    for (final order in currentOrders) {
      final orderId = order.assignmentUuid ?? '';

      if (orderId.isEmpty) continue;

      if (!_previousOrderIds.contains(orderId) && order.isAssigned) {
        AppLogger.info('🆕 [TodayOrdersNotifier] Nouvelle course détectée: ${order.order.orderNumber}');

        NotificationService.announceNewOrder(
          orderNumber: order.order.orderNumber ?? 'N/A',
          customerName: order.order.customerName ?? 'Client',
          isExpress: order.order.isExpress,
        );

        state = state.copyWith(newOrder: order);
        break;
      }
    }
  }

  void clearNewOrderNotification() {
    AppLogger.debug('🔕 [TodayOrdersNotifier] Effacement de la notification');
    state = state.copyWith(clearNewOrder: true);
  }

  // today_orders_provider.dart

  Future<bool> acceptOrder(
      String assignmentUuid, {
        String? notes,
        double? latitude,
        double? longitude,
      }) async {
    AppLogger.info('✅ [TodayOrdersNotifier] Acceptation: $assignmentUuid');

    final result = await _deliveryRepository.acceptAssignment(
      assignmentUuid,
      notes: notes,
      latitude: latitude,
      longitude: longitude,
    );

    return result.fold(
          (error) {
        AppLogger.error('❌ [TodayOrdersNotifier] Erreur acceptation: $error');
        state = state.copyWith(errorMessage: error);
        return false;
      },
          (success) {
        AppLogger.info('✅ [TodayOrdersNotifier] Course acceptée');

        NotificationService.announceOrderStatus('accepted');

        final updatedOrders = state.orders.map((assignment) {
          if (assignment.assignmentUuid == assignmentUuid) {
            return assignment.copyWith(
              assignmentStatus: 'accepted',
              acceptedAt: DateTime.now(),
            );
          }
          return assignment;
        }).toList();

        state = state.copyWith(orders: updatedOrders, clearError: true);
        return true;
      },
    );
  }

  Future<bool> rejectOrder(
      String assignmentUuid, {
        String? notes,
        double? latitude,
        double? longitude,
      }) async {
    AppLogger.info('❌ [TodayOrdersNotifier] Refus: $assignmentUuid');

    final result = await _deliveryRepository.rejectAssignment(
      assignmentUuid,
      notes: notes,
      latitude: latitude,
      longitude: longitude,
    );

    return result.fold(
          (error) {
        AppLogger.error('❌ [TodayOrdersNotifier] Erreur refus: $error');
        state = state.copyWith(errorMessage: error);
        return false;
      },
          (success) {
        AppLogger.info('✅ [TodayOrdersNotifier] Course refusée');

        NotificationService.announceOrderStatus('cancelled');

        final updatedOrders = state.orders
            .where((a) => a.assignmentUuid != assignmentUuid)
            .toList();

        state = state.copyWith(orders: updatedOrders, clearError: true);
        return true;
      },
    );
  }
  Assignment? findByUuid(String uuid) {
    try {
      return state.orders.firstWhere(
            (a) => a.assignmentUuid == uuid || a.order.orderUuid == uuid,
      );
    } catch (_) {
      return null;
    }
  }

  void reset() {
    AppLogger.debug('🔄 [TodayOrdersNotifier] Réinitialisation');
    _previousOrderIds = [];
    state = const TodayOrdersState();
  }
}

/// Provider des courses du jour
final todayOrdersProvider =
StateNotifierProvider<TodayOrdersNotifier, TodayOrdersState>((ref) {
  AppLogger.debug('🏗️ [Provider] Initialisation de TodayOrdersProvider');
  final deliveryRepository = ref.read(deliveryRepositoryProvider);
  return TodayOrdersNotifier(deliveryRepository);
});

/// Providers helpers
final todayOrdersCountProvider = Provider<int>((ref) {
  return ref.watch(todayOrdersProvider.select((s) => s.totalOrders));
});

final todayAssignedCountProvider = Provider<int>((ref) {
  return ref.watch(todayOrdersProvider.select((s) => s.assignedCount));
});

final todayAcceptedCountProvider = Provider<int>((ref) {
  return ref.watch(todayOrdersProvider.select((s) => s.acceptedCount));
});

final todayExpressCountProvider = Provider<int>((ref) {
  return ref.watch(todayOrdersProvider.select((s) => s.expressCount));
});

final todayActiveCountProvider = Provider<int>((ref) {
  return ref.watch(todayOrdersProvider.select((s) => s.activeCount));
});

final todayOrderByUuidProvider = Provider.family<Assignment?, String>((ref, uuid) {
  final state = ref.watch(todayOrdersProvider);
  try {
    return state.orders.firstWhere(
          (a) => a.assignmentUuid == uuid || a.order.orderUuid == uuid,
    );
  } catch (_) {
    return null;
  }
});

final newOrderProvider = Provider<Assignment?>((ref) {
  return ref.watch(todayOrdersProvider.select((s) => s.newOrder));
});