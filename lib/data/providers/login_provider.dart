import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../network/config/app_logger.dart';
import '../../network/config/token_service.dart';
import '../../network/repository/auth_repository.dart';
import '../models/login_response.dart';
import '../models/user.dart';
import 'api_provider.dart';

/// État pour la connexion
class LoginState {
  final bool isLoading;
  final LoginResponse? loginResponse;
  final String? errorMessage;

  LoginState({
    this.isLoading = false,
    this.loginResponse,
    this.errorMessage,
  });

  LoginState copyWith({
    bool? isLoading,
    LoginResponse? loginResponse,
    String? errorMessage,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      loginResponse: loginResponse ?? this.loginResponse,
      errorMessage: errorMessage,
    );
  }

  // Helpers
  bool get isAuthenticated => loginResponse?.token != null;
  String? get accessToken => loginResponse?.token;
  User? get user => loginResponse?.user;
  String? get userName => user?.name;
  String? get userEmail => user?.email;
  String? get userPhone => user?.phone;
  String? get userRole => user?.primaryRole?.displayName;
  bool get isCourier => user?.isCourier ?? false;
}

/// Notifier pour la connexion
class LoginNotifier extends StateNotifier<LoginState> {
  final AuthRepository _authRepository;

  LoginNotifier(this._authRepository) : super(LoginState());

  /// Charger l'utilisateur depuis le cache (au démarrage)
  Future<void> loadUserFromCache() async {
    AppLogger.info('📦 [LoginNotifier] Chargement depuis le cache');

    try {
      final userInfo = await TokenService.getUserInfo();
      final token = await TokenService.getToken();

      if (userInfo != null && token != null) {
        // Reconstruire un LoginResponse depuis le cache
        final cachedUser = User(
          uuid: userInfo['user_uuid'] as String,
          name: userInfo['user_name'] as String,
          email: userInfo['user_email'] as String? ?? '',
          phone: userInfo['user_phone'] as String? ?? '',
          isActive: 1,
          roles: [], // Les rôles ne sont pas stockés en cache
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final cachedResponse = LoginResponse(
          token: token,
          user: cachedUser,
        );

        state = state.copyWith(
          loginResponse: cachedResponse,
          isLoading: false,
        );

        AppLogger.info('✅ [LoginNotifier] Utilisateur chargé depuis le cache');
        AppLogger.debug('   - User: ${cachedUser.name}');
      } else {
        AppLogger.debug('⚠️ [LoginNotifier] Aucune donnée en cache');
      }
    } catch (e) {
      AppLogger.error('❌ [LoginNotifier] Erreur chargement cache', e);
    }
  }

  /// Connexion avec identifiant (email/téléphone) et mot de passe
  Future<bool> login({
    required String identifier,
    required String password,
  }) async {
    AppLogger.info('🔐 [LoginNotifier] Tentative de connexion');
    AppLogger.debug('   - Identifier: $identifier');
    AppLogger.debug('   - Password: ${password.replaceAll(RegExp(r'.'), '*')}');

    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _authRepository.login(
      identifier: identifier,
      password: password,
    );

    return result.fold(
      // ❌ Erreur
          (error) {
        AppLogger.error('❌ [LoginNotifier] Erreur de connexion', error);

        state = state.copyWith(
          isLoading: false,
          errorMessage: error,
        );
        return false;
      },
      // ✅ Succès
          (response) {
        AppLogger.info('✅ [LoginNotifier] Connexion réussie');
        AppLogger.debug('   - User: ${response.user.name}');
        AppLogger.debug('   - UUID: ${response.user.uuid}');
        AppLogger.debug('   - Email: ${response.user.email}');
        AppLogger.debug('   - Phone: ${response.user.phone}');
        AppLogger.debug('   - Token ID: ${response.tokenId}');

        if (response.user.primaryRole != null) {
          AppLogger.debug('   - Role: ${response.user.primaryRole!.displayName}');
        }

        state = state.copyWith(
          isLoading: false,
          loginResponse: response,
        );
        return true;
      },
    );
  }

  /// Déconnexion (✅ CORRIGÉ)
  Future<void> logout() async {
    AppLogger.info('👋 [LoginNotifier] Déconnexion en cours...');

    // 1. Appeler l'API de logout
    final result = await _authRepository.logout();

    result.fold(
          (error) {
        AppLogger.warning('⚠️ [LoginNotifier] Erreur lors du logout API: $error');
        // Continuer quand même avec le logout local
      },
          (success) {
        AppLogger.info('✅ [LoginNotifier] Logout API réussi');
      },
    );

    // 2. ✅ AJOUTÉ : Supprimer le token et les données utilisateur
    await TokenService.deleteToken();
    AppLogger.info('✅ [LoginNotifier] Token et données utilisateur supprimés');

    // 3. Réinitialiser l'état local
    state = LoginState();
    AppLogger.info('✅ [LoginNotifier] État local réinitialisé');
  }

  /// Réinitialiser l'état (sans appeler l'API)
  void reset() {
    AppLogger.debug('🔄 [LoginNotifier] Réinitialisation de l\'état');
    state = LoginState();
  }

  /// Vérifier si l'utilisateur est toujours connecté (au démarrage de l'app)
  Future<bool> checkAuthStatus() async {
    AppLogger.info('🔍 [LoginNotifier] Vérification du statut d\'authentification');

    final isLoggedIn = await TokenService.isLoggedIn();

    if (!isLoggedIn) {
      AppLogger.debug('   - Aucun token trouvé');
      return false;
    }

    // Récupérer les infos utilisateur sauvegardées
    final userInfo = await TokenService.getUserInfo();
    if (userInfo == null) {
      AppLogger.warning('   - Token trouvé mais infos user manquantes');
      await TokenService.deleteToken();
      return false;
    }

    AppLogger.info('✅ [LoginNotifier] Utilisateur déjà connecté');
    AppLogger.debug('   - User: ${userInfo['user_name']}');

    return true;
  }
}

/// Provider de connexion
final loginProvider = StateNotifierProvider<LoginNotifier, LoginState>((ref) {
  AppLogger.debug('🏗️ [Provider] Initialisation de LoginProvider');
  final authRepository = ref.read(authRepositoryProvider);
  return LoginNotifier(authRepository);
});

/// Provider pour vérifier si l'utilisateur est authentifié
final isAuthenticatedProvider = Provider<bool>((ref) {
  final loginState = ref.watch(loginProvider);
  return loginState.isAuthenticated;
});

/// Provider pour récupérer l'utilisateur actuel
final currentUserProvider = Provider<User?>((ref) {
  final loginState = ref.watch(loginProvider);
  return loginState.user;
});

/// Provider pour récupérer le token
final accessTokenProvider = Provider<String?>((ref) {
  final loginState = ref.watch(loginProvider);
  return loginState.accessToken;
});