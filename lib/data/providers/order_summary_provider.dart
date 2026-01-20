import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../network/config/app_logger.dart';
import '../../network/repository/delivery_repository.dart';
import '../models/delivery/order_summary.dart';
import 'api_provider.dart';

/// État pour le résumé des commandes
class OrderSummaryState {
  final bool isLoading;
  final OrderSummary? summary;
  final String? errorMessage;

  OrderSummaryState({
    this.isLoading = false,
    this.summary,
    this.errorMessage,
  });

  OrderSummaryState copyWith({
    bool? isLoading,
    OrderSummary? summary,
    String? errorMessage,
  }) {
    return OrderSummaryState(
      isLoading: isLoading ?? this.isLoading,
      summary: summary ?? this.summary,
      errorMessage: errorMessage,
    );
  }

  bool get hasData => summary != null;
  bool get hasError => errorMessage != null;
}

/// Notifier pour le résumé
class OrderSummaryNotifier extends StateNotifier<OrderSummaryState> {
  final DeliveryRepository _deliveryRepository;

  OrderSummaryNotifier(this._deliveryRepository) : super(OrderSummaryState());

  /// Charger le résumé
  Future<void> loadSummary() async {
    AppLogger.info('📊 [OrderSummaryNotifier] Chargement du résumé');

    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _deliveryRepository.getOrdersSummary();

    result.fold(
          (error) {
        AppLogger.error('❌ [OrderSummaryNotifier] Erreur: $error');
        state = state.copyWith(
          isLoading: false,
          errorMessage: error,
        );
      },
          (response) {
        AppLogger.info('✅ [OrderSummaryNotifier] Résumé chargé');
        AppLogger.debug('   - Total: ${response.data.total}');

        state = state.copyWith(
          isLoading: false,
          summary: response.data,
        );
      },
    );
  }

  /// Réinitialiser
  void reset() {
    AppLogger.debug('🔄 [OrderSummaryNotifier] Réinitialisation');
    state = OrderSummaryState();
  }
}

/// Provider principal
final orderSummaryProvider =
StateNotifierProvider<OrderSummaryNotifier, OrderSummaryState>((ref) {
  AppLogger.debug('🏗️ [Provider] Initialisation de OrderSummaryProvider');
  final deliveryRepository = ref.read(deliveryRepositoryProvider);
  return OrderSummaryNotifier(deliveryRepository);
});

/// Provider pour les stats individuelles
final summaryStatsProvider = Provider<Map<String, int>>((ref) {
  final summaryState = ref.watch(orderSummaryProvider);
  final summary = summaryState.summary;

  if (summary == null) {
    return {
      'pending': 0,
      'inProgress': 0,
      'delivered': 0,
      'returned': 0,
      'canceled': 0,
      'total': 0,
      'active': 0,
      'completed': 0,
    };
  }

  return {
    'pending': summary.pending,
    'inProgress': summary.inProgress,
    'delivered': summary.delivered,
    'returned': summary.returned,
    'canceled': summary.canceled,
    'total': summary.total,
    'active': summary.active,
    'completed': summary.completed,
  };
});