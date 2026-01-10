import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../network/config/app_logger.dart';
import '../../network/repository/delivery_repository.dart';
import '../models/delivery/assignment.dart';
import 'api_provider.dart';

/// État pour les courses du jour
class TodayOrdersState {
  final bool isLoading;
  final List<Assignment> orders;
  final String? errorMessage;
  final bool isRefreshing;
  final DateTime? lastUpdated;

  TodayOrdersState({
    this.isLoading = false,
    this.orders = const [],
    this.errorMessage,
    this.isRefreshing = false,
    this.lastUpdated,
  });

  TodayOrdersState copyWith({
    bool? isLoading,
    List<Assignment>? orders,
    String? errorMessage,
    bool? isRefreshing,
    DateTime? lastUpdated,
  }) {
    return TodayOrdersState(
      isLoading: isLoading ?? this.isLoading,
      orders: orders ?? this.orders,
      errorMessage: errorMessage,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  // Helpers
  bool get hasData => orders.isNotEmpty;
  bool get hasError => errorMessage != null;
  int get totalOrders => orders.length;

  // Filtres
  List<Assignment> get assignedOrders =>
      orders.where((a) => a.isAssigned).toList();

  List<Assignment> get acceptedOrders =>
      orders.where((a) => a.isAccepted).toList();

  List<Assignment> get expressOrders =>
      orders.where((a) => a.order.isExpress).toList();

  int get assignedCount => assignedOrders.length;
  int get acceptedCount => acceptedOrders.length;
  int get expressCount => expressOrders.length;
}

/// Notifier pour les courses du jour
class TodayOrdersNotifier extends StateNotifier<TodayOrdersState> {
  final DeliveryRepository _deliveryRepository;

  TodayOrdersNotifier(this._deliveryRepository) : super(TodayOrdersState());

  /// Charger les courses du jour
  Future<void> loadTodayOrders() async {
    AppLogger.info('📅 [TodayOrdersNotifier] Chargement des courses du jour');

    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _deliveryRepository.getTodayOrders();

    result.fold(
          (error) {
        AppLogger.error('❌ [TodayOrdersNotifier] Erreur: $error');
        state = state.copyWith(
          isLoading: false,
          errorMessage: error,
        );
      },
          (response) {
        AppLogger.info('✅ [TodayOrdersNotifier] ${response.total} courses chargées');
        AppLogger.debug('   - Assignées: ${response.assignedOrders.length}');
        AppLogger.debug('   - Acceptées: ${response.acceptedOrders.length}');
        AppLogger.debug('   - Express: ${response.expressOrders.length}');

        state = state.copyWith(
          isLoading: false,
          orders: response.data,
          lastUpdated: DateTime.now(),
          errorMessage: null,
        );
      },
    );
  }

  /// Rafraîchir les courses du jour
  Future<void> refreshTodayOrders() async {
    AppLogger.info('🔄 [TodayOrdersNotifier] Rafraîchissement des courses');

    state = state.copyWith(isRefreshing: true, errorMessage: null);

    final result = await _deliveryRepository.getTodayOrders();

    result.fold(
          (error) {
        AppLogger.error('❌ [TodayOrdersNotifier] Erreur refresh: $error');
        state = state.copyWith(
          isRefreshing: false,
          errorMessage: error,
        );
      },
          (response) {
        AppLogger.info('✅ [TodayOrdersNotifier] Rafraîchissement réussi');

        state = state.copyWith(
          isRefreshing: false,
          orders: response.data,
          lastUpdated: DateTime.now(),
          errorMessage: null,
        );
      },
    );
  }

  /// Accepter une course
  Future<bool> acceptOrder(String orderUuid, {String? notes}) async {
    AppLogger.info('✅ [TodayOrdersNotifier] Acceptation: $orderUuid');

    final result = await _deliveryRepository.acceptAssignment(
      orderUuid,
      notes: notes,
    );

    return result.fold(
          (error) {
        AppLogger.error('❌ [TodayOrdersNotifier] Erreur acceptation: $error');
        state = state.copyWith(errorMessage: error);
        return false;
      },
          (success) {
        AppLogger.info('✅ [TodayOrdersNotifier] Course acceptée');

        // Mettre à jour localement
        final updatedOrders = state.orders.map((assignment) {
          if (assignment.order.uuid == orderUuid) {
            return assignment.copyWith(
              assignmentStatus: 'accepted',
              acceptedAt: DateTime.now(),
            );
          }
          return assignment;
        }).toList();

        state = state.copyWith(orders: updatedOrders);
        return true;
      },
    );
  }

  /// Refuser une course
  Future<bool> rejectOrder(String orderUuid, {String? notes}) async {
    AppLogger.info('❌ [TodayOrdersNotifier] Refus: $orderUuid');

    final result = await _deliveryRepository.rejectAssignment(
      orderUuid,
      notes: notes,
    );

    return result.fold(
          (error) {
        AppLogger.error('❌ [TodayOrdersNotifier] Erreur refus: $error');
        state = state.copyWith(errorMessage: error);
        return false;
      },
          (success) {
        AppLogger.info('✅ [TodayOrdersNotifier] Course refusée');

        // Retirer de la liste
        final updatedOrders = state.orders
            .where((a) => a.order.uuid != orderUuid)
            .toList();

        state = state.copyWith(orders: updatedOrders);
        return true;
      },
    );
  }

  /// Réinitialiser l'état
  void reset() {
    AppLogger.debug('🔄 [TodayOrdersNotifier] Réinitialisation');
    state = TodayOrdersState();
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
  final state = ref.watch(todayOrdersProvider);
  return state.totalOrders;
});

final todayAssignedCountProvider = Provider<int>((ref) {
  final state = ref.watch(todayOrdersProvider);
  return state.assignedCount;
});

final todayAcceptedCountProvider = Provider<int>((ref) {
  final state = ref.watch(todayOrdersProvider);
  return state.acceptedCount;
});

final todayExpressCountProvider = Provider<int>((ref) {
  final state = ref.watch(todayOrdersProvider);
  return state.expressCount;
});