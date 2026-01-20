import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../network/config/app_logger.dart';
import '../../network/repository/delivery_repository.dart';
import '../models/delivery/assignment.dart';
import '../models/delivery/location_data.dart';
import '../models/delivery/pagination_meta.dart';
import 'api_provider.dart';

/// État pour les livraisons
class DeliveriesState {
  final bool isLoading;
  final List<Assignment> assignments;
  final PaginationMeta? meta;
  final String? errorMessage;
  final bool isRefreshing;
  final bool isLoadingMore;

  DeliveriesState({
    this.isLoading = false,
    this.assignments = const [],
    this.meta,
    this.errorMessage,
    this.isRefreshing = false,
    this.isLoadingMore = false,
  });

  DeliveriesState copyWith({
    bool? isLoading,
    List<Assignment>? assignments,
    PaginationMeta? meta,
    String? errorMessage,
    bool? isRefreshing,
    bool? isLoadingMore,
  }) {
    return DeliveriesState(
      isLoading: isLoading ?? this.isLoading,
      assignments: assignments ?? this.assignments,
      meta: meta ?? this.meta,
      errorMessage: errorMessage,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  // Helpers
  bool get hasData => assignments.isNotEmpty;
  bool get hasError => errorMessage != null;
  bool get hasNextPage => meta?.hasNextPage ?? false;
  int get totalAssignments => meta?.total ?? 0;
  int get currentPage => meta?.currentPage ?? 1;

  // Filtrer par statut
  List<Assignment> get assignedOnly =>
      assignments.where((a) => a.isAssigned).toList();
  List<Assignment> get acceptedOnly =>
      assignments.where((a) => a.isAccepted).toList();
  List<Assignment> get completedOnly =>
      assignments.where((a) => a.isCompleted).toList();
}

/// Notifier pour les livraisons
class DeliveriesNotifier extends StateNotifier<DeliveriesState> {
  final DeliveryRepository _deliveryRepository;

  DeliveriesNotifier(this._deliveryRepository) : super(DeliveriesState());

  /// Charger les livraisons (première page)
  Future<void> loadDeliveries({String? status}) async {
    AppLogger.info('📦 [DeliveriesNotifier] Chargement des livraisons');
    if (status != null) AppLogger.debug('   - Status filter: $status');

    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _deliveryRepository.getMyDeliveries(
      page: 1,
      status: status,
    );

    result.fold(
          (error) {
        AppLogger.error('❌ [DeliveriesNotifier] Erreur: $error');
        state = state.copyWith(
          isLoading: false,
          errorMessage: error,
        );
      },
          (response) {
        AppLogger.info('✅ [DeliveriesNotifier] ${response.data.length} livraisons chargées');
        AppLogger.debug('   - Total: ${response.meta.total}');

        state = state.copyWith(
          isLoading: false,
          assignments: response.data,
          meta: response.meta,
        );
      },
    );
  }

  /// Rafraîchir les livraisons
  Future<void> refreshDeliveries({String? status}) async {
    AppLogger.info('🔄 [DeliveriesNotifier] Rafraîchissement des livraisons');

    state = state.copyWith(isRefreshing: true, errorMessage: null);

    final result = await _deliveryRepository.getMyDeliveries(
      page: 1,
      status: status,
    );

    result.fold(
          (error) {
        AppLogger.error('❌ [DeliveriesNotifier] Erreur refresh: $error');
        state = state.copyWith(
          isRefreshing: false,
          errorMessage: error,
        );
      },
          (response) {
        AppLogger.info('✅ [DeliveriesNotifier] Rafraîchissement réussi');

        state = state.copyWith(
          isRefreshing: false,
          assignments: response.data,
          meta: response.meta,
        );
      },
    );
  }

  /// Charger plus de livraisons (pagination)
  Future<void> loadMoreDeliveries({String? status}) async {
    if (!state.hasNextPage || state.isLoadingMore) return;

    AppLogger.info('📦 [DeliveriesNotifier] Chargement page suivante');
    final nextPage = state.currentPage + 1;
    AppLogger.debug('   - Page: $nextPage');

    state = state.copyWith(isLoadingMore: true);

    final result = await _deliveryRepository.getMyDeliveries(
      page: nextPage,
      status: status,
    );

    result.fold(
          (error) {
        AppLogger.error('❌ [DeliveriesNotifier] Erreur load more: $error');
        state = state.copyWith(isLoadingMore: false);
      },
          (response) {
        AppLogger.info('✅ [DeliveriesNotifier] ${response.data.length} nouvelles livraisons');

        // Fusionner les anciennes et nouvelles assignments
        final updatedAssignments = [...state.assignments, ...response.data];

        state = state.copyWith(
          isLoadingMore: false,
          assignments: updatedAssignments,
          meta: response.meta,
        );
      },
    );
  }

  /// Accepter une livraison (✅ CORRIGÉ)
  Future<bool> acceptAssignment(String orderUuid, {String? notes}) async {
    AppLogger.info('✅ [DeliveriesNotifier] Acceptation: $orderUuid');

    final result = await _deliveryRepository.acceptAssignment(
      orderUuid,
      notes: notes,
    );

    return result.fold(
          (error) {
        AppLogger.error('❌ [DeliveriesNotifier] Erreur acceptation: $error');
        state = state.copyWith(errorMessage: error);
        return false;
      },
          (success) {
        AppLogger.info('✅ [DeliveriesNotifier] Acceptation réussie');

        // Mettre à jour l'assignment localement
        final updatedAssignments = state.assignments.map((assignment) {
          if (assignment.order.uuid == orderUuid) {
            return assignment.copyWith(
              assignmentStatus: 'accepted',
              acceptedAt: DateTime.now(),
            );
          }
          return assignment;
        }).toList();

        state = state.copyWith(assignments: updatedAssignments);
        return true;
      },
    );
  }

  /// Refuser une livraison (✅ CORRIGÉ)
  Future<bool> rejectAssignment(String orderUuid, {String? notes}) async {
    AppLogger.info('❌ [DeliveriesNotifier] Refus: $orderUuid');

    final result = await _deliveryRepository.rejectAssignment(
      orderUuid,
      notes: notes,
    );

    return result.fold(
          (error) {
        AppLogger.error('❌ [DeliveriesNotifier] Erreur refus: $error');
        state = state.copyWith(errorMessage: error);
        return false;
      },
          (success) {
        AppLogger.info('✅ [DeliveriesNotifier] Refus réussi');

        // Retirer l'assignment de la liste
        final updatedAssignments = state.assignments
            .where((a) => a.order.uuid != orderUuid)
            .toList();

        state = state.copyWith(assignments: updatedAssignments);
        return true;
      },
    );
  }


  /// Mettre à jour le statut d'une commande avec localisation
  Future<bool> updateOrderStatus(
      String orderUuid,
      String status, {
        String? notes,
        LocationData? location,
      }) async {
    AppLogger.info('🔄 [DeliveriesNotifier] Mise à jour statut: $orderUuid → $status');

    final result = await _deliveryRepository.updateOrderStatus(
      orderUuid,
      status,
      notes: notes,
      location: location,
    );

    return result.fold(
          (error) {
        AppLogger.error('❌ [DeliveriesNotifier] Erreur MAJ statut: $error');
        state = state.copyWith(errorMessage: error);
        return false;
      },
          (response) {
        AppLogger.info('✅ [DeliveriesNotifier] Statut mis à jour');
        AppLogger.debug('   - Message: ${response.message}');

        // Mettre à jour l'assignment localement
        final updatedAssignments = state.assignments.map((assignment) {
          if (assignment.order.uuid == orderUuid) {
            // Remplacer par les nouvelles données
            return response.data;
          }
          return assignment;
        }).toList();

        state = state.copyWith(assignments: updatedAssignments);
        return true;
      },
    );
  }
  /// Mettre à jour le statut d'une livraison (✅ CORRIGÉ)
  Future<bool> updateAssignmentStatus(
      String orderUuid,
      String status, {
        String? notes,
      }) async {
    AppLogger.info('🔄 [DeliveriesNotifier] Mise à jour statut: $orderUuid → $status');

    final result = await _deliveryRepository.updateAssignmentStatus(
      orderUuid,
      status,
      notes: notes,
    );

    return result.fold(
          (error) {
        AppLogger.error('❌ [DeliveriesNotifier] Erreur MAJ statut: $error');
        state = state.copyWith(errorMessage: error);
        return false;
      },
          (success) {
        AppLogger.info('✅ [DeliveriesNotifier] Statut mis à jour');

        // Mettre à jour l'assignment localement
        final updatedAssignments = state.assignments.map((assignment) {
          if (assignment.order.uuid == orderUuid) {
            return assignment.copyWith(
              assignmentStatus: status,
              completedAt: status == 'completed' || status == 'delivered'
                  ? DateTime.now()
                  : null,
            );
          }
          return assignment;
        }).toList();

        state = state.copyWith(assignments: updatedAssignments);
        return true;
      },
    );
  }

  /// Réinitialiser l'état
  void reset() {
    AppLogger.debug('🔄 [DeliveriesNotifier] Réinitialisation');
    state = DeliveriesState();
  }
}

/// Provider des livraisons
final deliveriesProvider =
StateNotifierProvider<DeliveriesNotifier, DeliveriesState>((ref) {
  AppLogger.debug('🏗️ [Provider] Initialisation de DeliveriesProvider');
  final deliveryRepository = ref.read(deliveryRepositoryProvider);
  return DeliveriesNotifier(deliveryRepository);
});

/// Provider pour les livraisons assignées uniquement
final assignedDeliveriesProvider = Provider<List<Assignment>>((ref) {
  final deliveriesState = ref.watch(deliveriesProvider);
  return deliveriesState.assignedOnly;
});

/// Provider pour les livraisons acceptées uniquement
final acceptedDeliveriesProvider = Provider<List<Assignment>>((ref) {
  final deliveriesState = ref.watch(deliveriesProvider);
  return deliveriesState.acceptedOnly;
});

/// Provider pour le nombre total de livraisons
final totalDeliveriesCountProvider = Provider<int>((ref) {
  final deliveriesState = ref.watch(deliveriesProvider);
  return deliveriesState.totalAssignments;
});