import 'package:shared_preferences/shared_preferences.dart';
import 'app_logger.dart';

class TokenService {
  static const String _tokenKey = 'access_token';
  static const String _userUuidKey = 'user_uuid';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';
  static const String _userPhoneKey = 'user_phone';
  static const String _userRoleKey = 'user_role';

  // ✅ Instance statique pour accès synchrone
  static SharedPreferences? _prefs;
  static bool _isInitialized = false;

  /// ✅ Initialiser le service (à appeler au démarrage de l'app)
  static Future<void> init() async {
    try {
      AppLogger.info('🔧 [TokenService] Initialisation');
      _prefs = await SharedPreferences.getInstance();
      _isInitialized = true;
      AppLogger.info('✅ [TokenService] Initialisé avec succès');

      // Debug : afficher les infos stockées
      final uuid = _prefs?.getString(_userUuidKey);
      final name = _prefs?.getString(_userNameKey);
      AppLogger.debug('   - User UUID: $uuid');
      AppLogger.debug('   - User Name: $name');
    } catch (e) {
      AppLogger.error('❌ [TokenService] Erreur initialisation', e);
      _isInitialized = false;
    }
  }

  /// ✅ Vérifier l'initialisation
  static Future<void> _ensureInitialized() async {
    if (!_isInitialized || _prefs == null) {
      await init();
    }
  }

  /// Sauvegarder le token et les infos utilisateur
  static Future<void> saveToken({
    required String token,
    required String userUuid,
    required String userName,
    String? userEmail,
    String? userPhone,
    String? userRole,
  }) async {
    try {
      await _ensureInitialized();

      AppLogger.info('💾 [TokenService] Sauvegarde du token');
      AppLogger.debug('   - User UUID: $userUuid');
      AppLogger.debug('   - User: $userName');
      AppLogger.debug('   - Email: $userEmail');
      AppLogger.debug('   - Phone: $userPhone');
      AppLogger.debug('   - Role: $userRole');

      await _prefs!.setString(_tokenKey, token);
      await _prefs!.setString(_userUuidKey, userUuid);
      await _prefs!.setString(_userNameKey, userName);

      if (userEmail != null) await _prefs!.setString(_userEmailKey, userEmail);
      if (userPhone != null) await _prefs!.setString(_userPhoneKey, userPhone);
      if (userRole != null) await _prefs!.setString(_userRoleKey, userRole);

      AppLogger.info('✅ [TokenService] Token et infos sauvegardés');
    } catch (e) {
      AppLogger.error('❌ [TokenService] Erreur lors de la sauvegarde', e);
      rethrow;
    }
  }

  /// Récupérer le token (async)
  static Future<String?> getToken() async {
    try {
      await _ensureInitialized();
      final token = _prefs!.getString(_tokenKey);

      if (token != null) {
        AppLogger.debug('✅ [TokenService] Token récupéré');
      } else {
        AppLogger.debug('⚠️ [TokenService] Aucun token trouvé');
      }

      return token;
    } catch (e) {
      AppLogger.error('❌ [TokenService] Erreur récupération token', e);
      return null;
    }
  }

  /// ✅ Récupérer le token (synchrone)
  static String? getTokenSync() {
    if (!_isInitialized || _prefs == null) {
      AppLogger.warning('⚠️ [TokenService] Non initialisé (getTokenSync)');
      return null;
    }
    return _prefs!.getString(_tokenKey);
  }

  /// Vérifier si l'utilisateur est connecté
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// ✅ Vérifier si l'utilisateur est connecté (synchrone)
  static bool isLoggedInSync() {
    final token = getTokenSync();
    return token != null && token.isNotEmpty;
  }

  /// Supprimer le token (déconnexion)
  static Future<void> deleteToken() async {
    try {
      await _ensureInitialized();

      AppLogger.info('🗑️ [TokenService] Suppression du token');

      await _prefs!.remove(_tokenKey);
      await _prefs!.remove(_userUuidKey);
      await _prefs!.remove(_userNameKey);
      await _prefs!.remove(_userEmailKey);
      await _prefs!.remove(_userPhoneKey);
      await _prefs!.remove(_userRoleKey);

      AppLogger.info('✅ [TokenService] Token et données supprimés');
    } catch (e) {
      AppLogger.error('❌ [TokenService] Erreur lors de la suppression', e);
    }
  }

  /// Récupérer les infos utilisateur
  static Future<Map<String, dynamic>?> getUserInfo() async {
    try {
      await _ensureInitialized();

      final userUuid = _prefs!.getString(_userUuidKey);
      final userName = _prefs!.getString(_userNameKey);
      final userEmail = _prefs!.getString(_userEmailKey);
      final userPhone = _prefs!.getString(_userPhoneKey);
      final userRole = _prefs!.getString(_userRoleKey);

      if (userUuid != null && userName != null) {
        return {
          'user_uuid': userUuid,
          'user_name': userName,
          'user_email': userEmail,
          'user_phone': userPhone,
          'user_role': userRole,
        };
      }
      return null;
    } catch (e) {
      AppLogger.error('❌ [TokenService] Erreur récupération infos user', e);
      return null;
    }
  }

  /// ✅ Récupérer les infos utilisateur (synchrone)
  static Map<String, dynamic>? getUserInfoSync() {
    if (!_isInitialized || _prefs == null) {
      AppLogger.warning('⚠️ [TokenService] Non initialisé (getUserInfoSync)');
      return null;
    }

    final userUuid = _prefs!.getString(_userUuidKey);
    final userName = _prefs!.getString(_userNameKey);
    final userEmail = _prefs!.getString(_userEmailKey);
    final userPhone = _prefs!.getString(_userPhoneKey);
    final userRole = _prefs!.getString(_userRoleKey);

    if (userUuid != null && userName != null) {
      return {
        'user_uuid': userUuid,
        'user_name': userName,
        'user_email': userEmail,
        'user_phone': userPhone,
        'user_role': userRole,
      };
    }
    return null;
  }

  /// ✅ Getters individuels ASYNCHRONES
  static Future<String?> getUserUuid() async {
    await _ensureInitialized();
    final uuid = _prefs!.getString(_userUuidKey);
    AppLogger.debug('🔑 [TokenService] getUserUuid: $uuid');
    return uuid;
  }

  static Future<String?> getUserName() async {
    await _ensureInitialized();
    return _prefs!.getString(_userNameKey);
  }

  static Future<String?> getUserEmail() async {
    await _ensureInitialized();
    return _prefs!.getString(_userEmailKey);
  }

  static Future<String?> getUserPhone() async {
    await _ensureInitialized();
    return _prefs!.getString(_userPhoneKey);
  }

  static Future<String?> getUserRole() async {
    await _ensureInitialized();
    return _prefs!.getString(_userRoleKey);
  }

  /// ✅ Getters individuels SYNCHRONES
  static String? getUserUuidSync() {
    if (!_isInitialized || _prefs == null) {
      AppLogger.warning('⚠️ [TokenService] Non initialisé (getUserUuidSync)');
      return null;
    }
    final uuid = _prefs!.getString(_userUuidKey);
    AppLogger.debug('🔑 [TokenService] getUserUuidSync: $uuid');
    return uuid;
  }

  static String? getUserNameSync() {
    if (!_isInitialized || _prefs == null) return null;
    return _prefs!.getString(_userNameKey);
  }

  static String? getUserEmailSync() {
    if (!_isInitialized || _prefs == null) return null;
    return _prefs!.getString(_userEmailKey);
  }

  static String? getUserPhoneSync() {
    if (!_isInitialized || _prefs == null) return null;
    return _prefs!.getString(_userPhoneKey);
  }

  static String? getUserRoleSync() {
    if (!_isInitialized || _prefs == null) return null;
    return _prefs!.getString(_userRoleKey);
  }

  /// ✅ Debug : afficher toutes les données stockées
  static void debugPrintAll() {
    if (!_isInitialized || _prefs == null) {
      AppLogger.warning('⚠️ [TokenService] Non initialisé');
      return;
    }

    AppLogger.info('═══════════════════════════════════');
    AppLogger.info('📊 [TokenService] État actuel');
    AppLogger.info('═══════════════════════════════════');
    AppLogger.info('Token: ${_prefs!.getString(_tokenKey)?.substring(0, 20)}...');
    AppLogger.info('UUID: ${_prefs!.getString(_userUuidKey)}');
    AppLogger.info('Name: ${_prefs!.getString(_userNameKey)}');
    AppLogger.info('Email: ${_prefs!.getString(_userEmailKey)}');
    AppLogger.info('Phone: ${_prefs!.getString(_userPhoneKey)}');
    AppLogger.info('Role: ${_prefs!.getString(_userRoleKey)}');
    AppLogger.info('═══════════════════════════════════');
  }

  /// ✅ Vérifier la validité des données
  static bool isValid() {
    if (!_isInitialized || _prefs == null) return false;

    final token = _prefs!.getString(_tokenKey);
    final uuid = _prefs!.getString(_userUuidKey);

    return token != null &&
        token.isNotEmpty &&
        uuid != null &&
        uuid.isNotEmpty;
  }
}