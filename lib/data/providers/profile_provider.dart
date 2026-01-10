import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../network/config/app_logger.dart';
import '../../network/repository/courier_repository.dart';
import '../models/courier/courier_profile.dart';
import 'api_provider.dart';

/// État pour le profil
class ProfileState {
  final bool isLoading;
  final CourierProfile? profile;
  final String? errorMessage;
  final bool isRefreshing;

  ProfileState({
    this.isLoading = false,
    this.profile,
    this.errorMessage,
    this.isRefreshing = false,
  });

  ProfileState copyWith({
    bool? isLoading,
    CourierProfile? profile,
    String? errorMessage,
    bool? isRefreshing,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      profile: profile ?? this.profile,
      errorMessage: errorMessage,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  bool get hasData => profile != null;
  bool get hasError => errorMessage != null;
}

/// Notifier pour le profil
class ProfileNotifier extends StateNotifier<ProfileState> {
  final CourierRepository _courierRepository;

  ProfileNotifier(this._courierRepository) : super(ProfileState());

  /// Charger le profil
  Future<void> loadProfile() async {
    AppLogger.info('👤 [ProfileNotifier] Chargement du profil');

    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _courierRepository.getProfile();

    result.fold(
          (error) {
        AppLogger.error('❌ [ProfileNotifier] Erreur: $error');
        state = state.copyWith(
          isLoading: false,
          errorMessage: error,
        );
      },
          (response) {
        AppLogger.info('✅ [ProfileNotifier] Profil chargé');
        AppLogger.debug('   - User: ${response.data.user.name}');

        state = state.copyWith(
          isLoading: false,
          profile: response.data,
        );
      },
    );
  }

  /// Rafraîchir le profil
  Future<void> refreshProfile() async {
    AppLogger.info('🔄 [ProfileNotifier] Rafraîchissement du profil');

    state = state.copyWith(isRefreshing: true, errorMessage: null);

    final result = await _courierRepository.getProfile();

    result.fold(
          (error) {
        AppLogger.error('❌ [ProfileNotifier] Erreur refresh: $error');
        state = state.copyWith(
          isRefreshing: false,
          errorMessage: error,
        );
      },
          (response) {
        AppLogger.info('✅ [ProfileNotifier] Rafraîchissement réussi');

        state = state.copyWith(
          isRefreshing: false,
          profile: response.data,
        );
      },
    );
  }

  /// Réinitialiser l'état
  void reset() {
    AppLogger.debug('🔄 [ProfileNotifier] Réinitialisation');
    state = ProfileState();
  }
}

/// Provider du profil
final profileProvider =
StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  AppLogger.debug('🏗️ [Provider] Initialisation de ProfileProvider');
  final courierRepository = ref.read(courierRepositoryProvider);
  return ProfileNotifier(courierRepository);
});

/// Provider pour l'utilisateur courant
final currentCourierProvider = Provider<CourierProfile?>((ref) {
  final profileState = ref.watch(profileProvider);
  return profileState.profile;
});