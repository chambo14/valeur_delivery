import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/login_provider.dart';
import '../../network/config/token_service.dart';
import '../../network/config/app_logger.dart';
import '../../theme/app_theme.dart';
import '../home/home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _rotateAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();

    // ✅ Vérifier l'authentification après les animations
    _checkAuthAndNavigate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// ✅ Vérifier l'authentification et naviguer
  Future<void> _checkAuthAndNavigate() async {
    // Attendre que les animations se terminent (minimum 2.5 secondes)
    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;

    try {
      AppLogger.info('🔐 [SplashScreen] Vérification de l\'authentification');

      // 1. Vérifier si le token existe
      final isLoggedIn = await TokenService.isLoggedIn();
      AppLogger.debug('   - Token présent: $isLoggedIn');

      if (!isLoggedIn) {
        // Pas de token → Rediriger vers Login
        AppLogger.info('❌ [SplashScreen] Aucun token → Redirection vers Login');
        _navigateToLogin();
        return;
      }

      // 2. Récupérer les infos utilisateur stockées
      final userInfo = await TokenService.getUserInfo();
      AppLogger.debug('   - User info: $userInfo');

      if (userInfo == null) {
        // Token présent mais pas d'infos utilisateur → Rediriger vers Login
        AppLogger.info('⚠️ [SplashScreen] Token sans infos user → Redirection vers Login');
        await TokenService.deleteToken(); // Nettoyer le token invalide
        _navigateToLogin();
        return;
      }

      // 3. Optionnel : Vérifier la validité du token avec l'API
      final isValid = await _validateTokenWithAPI();

      if (!isValid) {
        // Token invalide → Rediriger vers Login
        AppLogger.info('❌ [SplashScreen] Token invalide → Redirection vers Login');
        await TokenService.deleteToken();
        _navigateToLogin();
        return;
      }

      // 4. Token valide → Charger les données utilisateur dans le provider
      AppLogger.info('✅ [SplashScreen] Utilisateur authentifié → Redirection vers Home');
      await ref.read(loginProvider.notifier).loadUserFromCache();

      _navigateToHome();

    } catch (e) {
      AppLogger.error('❌ [SplashScreen] Erreur lors de la vérification', e);
      // En cas d'erreur, rediriger vers Login par sécurité
      _navigateToLogin();
    }
  }

  /// ✅ Valider le token avec l'API (optionnel mais recommandé)
  Future<bool> _validateTokenWithAPI() async {
    try {
      // Essayer de charger le profil depuis l'API
      // Si ça échoue (401), le token est invalide
      AppLogger.debug('🔍 [SplashScreen] Validation du token via API');

      // Note: Vous pouvez utiliser le profileProvider pour valider
      // await ref.read(profileProvider.notifier).loadProfile();
      // final profileState = ref.read(profileProvider);
      // return !profileState.hasError;

      // Pour l'instant, on fait confiance au token local
      // Dans une vraie app, vous devriez faire un appel API ici
      return true;

    } catch (e) {
      AppLogger.error('❌ [SplashScreen] Erreur validation API', e);
      return false;
    }
  }

  /// ✅ Navigation vers Login
  void _navigateToLogin() {
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
        const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.1),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  /// ✅ Navigation vers Home
  void _navigateToHome() {
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
        const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.1),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.backgroundLight,
              AppTheme.cardGrey.withOpacity(0.5),
            ],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo avec effet moderne
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Cercle de fond animé
                          Transform.rotate(
                            angle: _rotateAnimation.value * 2 * 3.14159,
                            child: Container(
                              width: 240,
                              height: 240,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppTheme.primaryRed.withOpacity(0.1),
                                    AppTheme.accentRed.withOpacity(0.05),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Logo principal
                          Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              color: AppTheme.cardLight,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryRed.withOpacity(0.2),
                                  blurRadius: 40,
                                  spreadRadius: 5,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: Image.asset(
                                'assets/images/valeur.png',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  // Fallback moderne
                                  return Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          AppTheme.primaryRed.withOpacity(0.1),
                                          AppTheme.accentRed.withOpacity(0.05),
                                        ],
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.delivery_dining_rounded,
                                      size: 100,
                                      color: AppTheme.primaryRed,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 50),

                      // Loader animé moderne
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryRed.withOpacity(0.1),
                              AppTheme.accentRed.withOpacity(0.05),
                            ],
                          ),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            strokeWidth: 3.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.primaryRed,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Titre principal
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            AppTheme.primaryRed,
                            AppTheme.accentRed,
                          ],
                        ).createShader(bounds),
                        child: Text(
                          'Valeur Delivery',
                          style: Theme.of(context)
                              .textTheme
                              .displayMedium
                              ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Slogan
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.primaryRed.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'EASY SOLUTION',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                            color: AppTheme.primaryRed,
                            letterSpacing: 3,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),

                      const SizedBox(height: 60),

                      // Version
                      Text(
                        'Version 1.0.0',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textGrey.withOpacity(0.6),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}