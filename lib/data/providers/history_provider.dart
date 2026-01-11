import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../network/config/app_logger.dart';
import '../../network/repository/delivery_repository.dart';
import '../models/delivery/assignment.dart';
import '../models/delivery/pagination_meta.dart';
import 'api_provider.dart';

/// État pour l'historique
class HistoryState {
  final bool isLoading;
  final List<Assignment> assignments;
  final PaginationMeta? meta;
  final String? errorMessage;
  final bool isRefreshing;
  final String? selectedPeriod; // today, week, month, all
  final String searchQuery;

  HistoryState({
    this.isLoading = false,
    this.assignments = const [],
    this.meta,
    this.errorMessage,
    this.isRefreshing = false,
    this.selectedPeriod = 'today',
    this.searchQuery = '',
  });

  HistoryState copyWith({
    bool? isLoading,
    List<Assignment>? assignments,
    PaginationMeta? meta,
    String? errorMessage,
    bool? isRefreshing,
    String? selectedPeriod,
    String? searchQuery,
  }) {
    return HistoryState(
      isLoading: isLoading ?? this.isLoading,
      assignments: assignments ?? this.assignments,
      meta: meta ?? this.meta,
      errorMessage: errorMessage,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  // Helpers
  bool get hasData => assignments.isNotEmpty;
  bool get hasError => errorMessage != null;
  int get totalAssignments => meta?.total ?? 0;

  // Stats
  int get deliveredCount => assignments
      .where((a) =>
  a.assignmentStatus?.toLowerCase() == 'delivered' ||
      a.assignmentStatus?.toLowerCase() == 'completed')
      .length;

  int get failedCount =>
      assignments
          .where((a) => a.assignmentStatus?.toLowerCase() == 'failed')
          .length;

  // ✅ CORRIGÉ : Utiliser basePrice au lieu de priceDouble
  double get totalAmount {
    return assignments
        .where((a) =>
    a.assignmentStatus?.toLowerCase() == 'delivered' ||
        a.assignmentStatus?.toLowerCase() == 'completed')
        .fold<double>(0, (sum, a) => sum + (a.order.pricing.basePrice));
  }
}

/// Notifier pour l'historique
class HistoryNotifier extends StateNotifier<HistoryState> {
  final DeliveryRepository _deliveryRepository;

  HistoryNotifier(this._deliveryRepository) : super(HistoryState());

  /// Charger l'historique
  Future<void> loadHistory() async {
    AppLogger.info('📜 [HistoryNotifier] Chargement de l\'historique');
    AppLogger.debug('   - Period: ${state.selectedPeriod}');
    if (state.searchQuery.isNotEmpty) {
      AppLogger.debug('   - Search: ${state.searchQuery}');
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _deliveryRepository.getHistory(
      page: 1,
      period: state.selectedPeriod,
      search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
    );

    result.fold(
          (error) {
        AppLogger.error('❌ [HistoryNotifier] Erreur: $error');
        state = state.copyWith(
          isLoading: false,
          errorMessage: error,
        );
      },
          (response) {
        AppLogger.info('✅ [HistoryNotifier] ${response.data.length} éléments chargés');
        AppLogger.debug('   - Total: ${response.meta.total}');

        state = state.copyWith(
          isLoading: false,
          assignments: response.data,
          meta: response.meta,
        );
      },
    );
  }

  /// Rafraîchir l'historique
  Future<void> refreshHistory() async {
    AppLogger.info('🔄 [HistoryNotifier] Rafraîchissement de l\'historique');

    state = state.copyWith(isRefreshing: true, errorMessage: null);

    final result = await _deliveryRepository.getHistory(
      page: 1,
      period: state.selectedPeriod,
      search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
    );

    result.fold(
          (error) {
        AppLogger.error('❌ [HistoryNotifier] Erreur refresh: $error');
        state = state.copyWith(
          isRefreshing: false,
          errorMessage: error,
        );
      },
          (response) {
        AppLogger.info('✅ [HistoryNotifier] Rafraîchissement réussi');

        state = state.copyWith(
          isRefreshing: false,
          assignments: response.data,
          meta: response.meta,
        );
      },
    );
  }

  /// Changer la période de filtrage
  void setPeriod(String period) {
    AppLogger.debug('📅 [HistoryNotifier] Période changée: $period');
    state = state.copyWith(selectedPeriod: period);
    loadHistory();
  }

  /// Mettre à jour la recherche
  void setSearchQuery(String query) {
    AppLogger.debug('🔍 [HistoryNotifier] Recherche: $query');
    state = state.copyWith(searchQuery: query);
    loadHistory();
  }

  /// Réinitialiser l'état
  void reset() {
    AppLogger.debug('🔄 [HistoryNotifier] Réinitialisation');
    state = HistoryState();
  }
}

/// Provider de l'historique
final historyProvider =
StateNotifierProvider<HistoryNotifier, HistoryState>((ref) {
  AppLogger.debug('🏗️ [Provider] Initialisation de HistoryProvider');
  final deliveryRepository = ref.read(deliveryRepositoryProvider);
  return HistoryNotifier(deliveryRepository);
});

/// Provider pour les stats
final historyStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final historyState = ref.watch(historyProvider);
  return {
    'delivered': historyState.deliveredCount,
    'failed': historyState.failedCount,
    'total': historyState.totalAssignments,
    'amount': historyState.totalAmount.toInt(),
  };
});