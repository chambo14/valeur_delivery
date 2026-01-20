import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/login_provider.dart';
import '../../theme/app_theme.dart';
import '../home/home_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final loginNotifier = ref.read(loginProvider.notifier);

    final success = await loginNotifier.login(
      identifier: _phoneController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      // Récupérer les infos de l'utilisateur connecté
      final user = ref.read(loginProvider).user;

      _showSuccess('Bienvenue ${user?.name ?? ''} !');

      // Navigation vers HomeScreen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      // Récupérer le message d'erreur depuis le state
      final errorMessage = ref.read(loginProvider).errorMessage;
      _showError(errorMessage ?? 'Erreur de connexion');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(
              message,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Écouter l'état de login pour le loading
    final loginState = ref.watch(loginProvider);
    final isLoading = loginState.isLoading;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),

                // Logo
                Center(
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryRed.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.transparent,
                            child:  Image.asset("assets/images/valeur.png")
                          );
                        },
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Titre
                Text(
                  'Bienvenue !',
                  style: Theme.of(context).textTheme.displayMedium,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                Text(
                  'Connectez-vous pour commencer vos livraisons',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // Formulaire
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Champ téléphone/email
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          labelText: 'Téléphone ou Email',
                          hintText: '0566111514 ou email@example.com',
                          prefixIcon: Container(
                            padding: const EdgeInsets.all(12),
                            child: const Icon(
                              Icons.phone_android,
                              color: AppTheme.primaryRed,
                            ),
                          ),
                          labelStyle: const TextStyle(color: AppTheme.textGrey),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer votre téléphone ou email';
                          }
                          // Valider soit téléphone soit email
                          final isPhone = RegExp(r'^\d{10}$').hasMatch(value);
                          final isEmail = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value);

                          if (!isPhone && !isEmail) {
                            return 'Téléphone ou email invalide';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Champ mot de passe
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Mot de passe',
                          hintText: '••••••••',
                          prefixIcon: Container(
                            padding: const EdgeInsets.all(12),
                            child: const Icon(
                              Icons.lock_outline,
                              color: AppTheme.primaryRed,
                            ),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppTheme.textGrey,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          labelStyle: const TextStyle(color: AppTheme.textGrey),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer votre mot de passe';
                          }
                          if (value.length < 6) {
                            return 'Le mot de passe doit contenir au moins 6 caractères';
                          }
                          return null;
                        },
                      ),

                      // const SizedBox(height: 12),
                      //
                      // // Mot de passe oublié
                      // Align(
                      //   alignment: Alignment.centerRight,
                      //   child: TextButton(
                      //     onPressed: isLoading
                      //         ? null
                      //         : () {
                      //       Navigator.push(
                      //         context,
                      //         MaterialPageRoute(
                      //           builder: (context) =>
                      //           const ForgotPasswordScreen(),
                      //         ),
                      //       );
                      //     },
                      //     child: const Text('Mot de passe oublié ?'),
                      //   ),
                      // ),

                      const SizedBox(height: 30),

                      // Bouton de connexion
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _handleLogin,
                          child: isLoading
                              ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                              : const Text('Se connecter'),
                        ),
                      ),

                      // ✅ Affichage du message d'erreur sous le bouton (optionnel)
                      if (loginState.errorMessage != null && !isLoading) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.error.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: AppTheme.error,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  loginState.errorMessage!,
                                  style: const TextStyle(
                                    color: AppTheme.error,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Footer
                Text(
                  'En vous connectant, vous acceptez nos conditions d\'utilisation',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textGrey,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}