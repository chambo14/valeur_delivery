import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../network/config/app_logger.dart';
import '../../network/repository/delivery_repository.dart';
import '../models/delivery/assignment.dart';
import 'api_provider.dart';

/// État pour le détail d'une livraison
class DeliveryDetailState {
  final bool isLoading;
  final Assignment? assignment;
  final String? errorMessage;
  final bool isAccepting;
  final bool isRejecting;
  final bool isUpdatingStatus;

  DeliveryDetailState({
    this.isLoading = false,
    this.assignment,
    this.errorMessage,
    this.isAccepting = false,
    this.isRejecting = false,
    this.isUpdatingStatus = false,
  });

  DeliveryDetailState copyWith({
    bool? isLoading,
    Assignment? assignment,
    String? errorMessage,
    bool? isAccepting,
    bool? isRejecting,
    bool? isUpdatingStatus,
  }) {
    return DeliveryDetailState(
      isLoading: isLoading ?? this.isLoading,
      assignment: assignment ?? this.assignment,
      errorMessage: errorMessage,
      isAccepting: isAccepting ?? this.isAccepting,
      isRejecting: isRejecting ?? this.isRejecting,
      isUpdatingStatus: isUpdatingStatus ?? this.isUpdatingStatus,
    );
  }

  bool get hasData => assignment != null;
  bool get hasError => errorMessage != null;
  bool get canAccept => assignment?.isAssigned ?? false;
  bool get canUpdateStatus => assignment?.isAccepted ?? false;
}

/// Notifier pour le détail d'une livraison
class DeliveryDetailNotifier extends StateNotifier<DeliveryDetailState> {
  final DeliveryRepository _deliveryRepository;

  DeliveryDetailNotifier(this._deliveryRepository) : super(DeliveryDetailState());

  /// Charger le détail d'une commande
  Future<void> loadOrderDetail(String orderUuid) async {
    AppLogger.info('📋 [DeliveryDetailNotifier] Chargement du détail');
    AppLogger.debug('   - Order UUID: $orderUuid');

    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _deliveryRepository.getOrderDetail(orderUuid);

    result.fold(
          (error) {
        AppLogger.error('❌ [DeliveryDetailNotifier] Erreur: $error');
        state = state.copyWith(
          isLoading: false,
          errorMessage: error,
        );
      },
          (response) {
        AppLogger.info('✅ [DeliveryDetailNotifier] Détail chargé');
        AppLogger.debug('   - Order: ${response.data.order.orderNumber}');

        state = state.copyWith(
          isLoading: false,
          assignment: response.data,
        );
      },
    );
  }

  /// Accepter la livraison
  Future<bool> acceptAssignment({String? notes}) async {
    if (state.assignment == null) return false;

    AppLogger.info('✅ [DeliveryDetailNotifier] Acceptation de la livraison');
    if (notes != null) AppLogger.debug('   - Notes: $notes');

    state = state.copyWith(isAccepting: true, errorMessage: null);

    final result = await _deliveryRepository.acceptAssignment(
      state.assignment!.order.uuid, // ✅ Utiliser order.uuid
      notes: notes,
    );

    return result.fold(
          (error) {
        AppLogger.error('❌ [DeliveryDetailNotifier] Erreur acceptation: $error');
        state = state.copyWith(
          isAccepting: false,
          errorMessage: error,
        );
        return false;
      },
          (success) {
        AppLogger.info('✅ [DeliveryDetailNotifier] Acceptation réussie');

        // Mettre à jour l'assignment localement
        final updatedAssignment = state.assignment!.copyWith(
          assignmentStatus: 'accepted',
          acceptedAt: DateTime.now(),
        );

        state = state.copyWith(
          isAccepting: false,
          assignment: updatedAssignment,
        );
        return true;
      },
    );
  }

  /// Refuser la livraison
  Future<bool> rejectAssignment({String? notes}) async {
    if (state.assignment == null) return false;

    AppLogger.info('❌ [DeliveryDetailNotifier] Refus de la livraison');
    if (notes != null) AppLogger.debug('   - Notes: $notes');

    state = state.copyWith(isRejecting: true, errorMessage: null);

    final result = await _deliveryRepository.rejectAssignment(
      state.assignment!.order.uuid, // ✅ Utiliser order.uuid
      notes: notes,
    );

    return result.fold(
          (error) {
        AppLogger.error('❌ [DeliveryDetailNotifier] Erreur refus: $error');
        state = state.copyWith(
          isRejecting: false,
          errorMessage: error,
        );
        return false;
      },
          (success) {
        AppLogger.info('✅ [DeliveryDetailNotifier] Refus réussi');
        state = state.copyWith(isRejecting: false);
        return true;
      },
    );
  }

  /// Mettre à jour le statut
  Future<bool> updateStatus(String newStatus, {String? notes}) async {
    if (state.assignment == null) return false;

    AppLogger.info('🔄 [DeliveryDetailNotifier] Mise à jour du statut: $newStatus');
    if (notes != null) AppLogger.debug('   - Notes: $notes');

    state = state.copyWith(isUpdatingStatus: true, errorMessage: null);

    final result = await _deliveryRepository.updateAssignmentStatus(
      state.assignment!.order.uuid, // ✅ Utiliser order.uuid
      newStatus,
      notes: notes,
    );

    return result.fold(
          (error) {
        AppLogger.error('❌ [DeliveryDetailNotifier] Erreur MAJ statut: $error');
        state = state.copyWith(
          isUpdatingStatus: false,
          errorMessage: error,
        );
        return false;
      },
          (success) {
        AppLogger.info('✅ [DeliveryDetailNotifier] Statut mis à jour');

        // Mettre à jour l'assignment localement
        final updatedAssignment = state.assignment!.copyWith(
          assignmentStatus: newStatus,
          completedAt: newStatus == 'completed' || newStatus == 'delivered'
              ? DateTime.now()
              : null,
        );

        state = state.copyWith(
          isUpdatingStatus: false,
          assignment: updatedAssignment,
        );
        return true;
      },
    );
  }



  /// Rafraîchir le détail
  Future<void> refreshDetail() async {
    if (state.assignment == null) return;
    await loadOrderDetail(state.assignment!.order.uuid);
  }

  /// Réinitialiser l'état
  void reset() {
    AppLogger.debug('🔄 [DeliveryDetailNotifier] Réinitialisation');
    state = DeliveryDetailState();
  }
}

/// Provider pour le détail d'une livraison
final deliveryDetailProvider =
StateNotifierProvider<DeliveryDetailNotifier, DeliveryDetailState>((ref) {
  AppLogger.debug('🏗️ [Provider] Initialisation de DeliveryDetailProvider');
  final deliveryRepository = ref.read(deliveryRepositoryProvider);
  return DeliveryDetailNotifier(deliveryRepository);
});