import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../network/api_service.dart';
import '../../network/config/app_logger.dart';
import 'api_provider.dart';

/// État pour le changement de mot de passe
class ChangePasswordState {
  final bool isLoading;
  final String? successMessage;
  final String? errorMessage;

  ChangePasswordState({
    this.isLoading = false,
    this.successMessage,
    this.errorMessage,
  });

  ChangePasswordState copyWith({
    bool? isLoading,
    String? successMessage,
    String? errorMessage,
  }) {
    return ChangePasswordState(
      isLoading: isLoading ?? this.isLoading,
      successMessage: successMessage,
      errorMessage: errorMessage,
    );
  }
}

/// Notifier pour le changement de mot de passe
class ChangePasswordNotifier extends StateNotifier<ChangePasswordState> {
  final ApiService _apiService;

  ChangePasswordNotifier(this._apiService) : super(ChangePasswordState());

  /// Changer le mot de passe
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    AppLogger.info('🔐 [ChangePasswordNotifier] Changement de mot de passe');

    state = state.copyWith(
      isLoading: true,
      successMessage: null,
      errorMessage: null,
    );

    final result = await _apiService.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
      newConfirmPassword: confirmPassword,
    );

    return result.fold(
          (error) {
        AppLogger.error('❌ [ChangePasswordNotifier] Erreur: $error');
        state = state.copyWith(
          isLoading: false,
          errorMessage: error,
        );
        return false;
      },
          (message) {
        AppLogger.info('✅ [ChangePasswordNotifier] Succès: $message');
        state = state.copyWith(
          isLoading: false,
          successMessage: message,
        );
        return true;
      },
    );
  }

  /// Réinitialiser l'état
  void reset() {
    state = ChangePasswordState();
  }
}

/// Provider principal
final changePasswordProvider =
StateNotifierProvider<ChangePasswordNotifier, ChangePasswordState>((ref) {
  final apiService = ref.read(apiServiceProvider);
  return ChangePasswordNotifier(apiService);
});