import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:valeur_delivery/network/config/api_end_point.dart';
import '../data/models/login_request.dart';

import '../data/models/login_response.dart';
import 'config/app_logger.dart';
import 'config/dio.dart';
import 'config/token_service.dart';
import 'config/url.dart';


class ApiService {
  final DioService dioService;

  ApiService(this.dioService);

  // 🔐 LOGIN
  Future<Either<String, LoginResponse>> loginUser(
      LoginRequest request,
      ) async {
    try {
      AppLogger.info('🔐 [ApiService] Tentative de connexion...');

      final response = await dioService.post(
        ApiEndPoints.login,
        request.toJson(),
      );

      if (response.statusCode == 200) {
        AppLogger.info('✅ [ApiService] Login réussi');

        final res = LoginResponse.fromJson(response.data);

        // ✅ Sauvegarder le token et les infos utilisateur
        await TokenService.saveToken(
          token: res.token,
          userUuid: res.user.uuid,
          userName: res.user.name,
          userEmail: res.user.email,
          userPhone: res.user.phone,
          userRole: res.user.primaryRole?.displayName,
        );

        // ✅ Le DioService ajoutera automatiquement le token aux prochaines requêtes

        return Right(res);
      } else {
        final message = response.data["message"] ?? "Erreur de connexion";
        AppLogger.error('❌ [ApiService] Login échoué: $message');
        return Left(message);
      }
    } on DioException catch (e) {
      final message = _handleDioError(e);
      AppLogger.error('❌ [ApiService] Erreur Dio: $message');
      return Left(message);
    } catch (e) {
      AppLogger.error('❌ [ApiService] Erreur inattendue: $e');
      return Left("Erreur inattendue: ${e.toString()}");
    }
  }

  // 🚪 LOGOUT
  Future<Either<String, bool>> logoutUser() async {
    try {
      AppLogger.info('🚪 [ApiService] Tentative de déconnexion...');

      final response = await dioService.post(ApiEndPoints.logout, {});

      if (response.statusCode == 200) {
        AppLogger.info('✅ [ApiService] Logout réussi');

        // ✅ Supprimer le token local
        await TokenService.deleteToken();

        return const Right(true);
      } else {
        final message = response.data["message"] ?? "Erreur de déconnexion";
        AppLogger.error('❌ [ApiService] Logout échoué: $message');
        return Left(message);
      }
    } on DioException catch (e) {
      final message = _handleDioError(e);
      return Left(message);
    } catch (e) {
      return Left("Erreur inattendue: ${e.toString()}");
    }
  }

  // 🔑 FORGOT PASSWORD
  Future<Either<String, String>> forgotPassword(String phone) async {
    try {
      AppLogger.info('🔑 [ApiService] Demande de réinitialisation: $phone');

      final response = await dioService.post(
        ApiEndPoints.forgotPassword,
        {"phone": phone},
      );

      if (response.statusCode == 200) {
        final message = response.data["message"] ?? "Code envoyé avec succès";
        AppLogger.info('✅ [ApiService] Code envoyé');
        return Right(message);
      } else {
        final message = response.data["message"] ?? "Erreur d'envoi du code";
        return Left(message);
      }
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left("Erreur inattendue: ${e.toString()}");
    }
  }

  // 🔄 RESET PASSWORD
  Future<Either<String, String>> resetPassword({
    required String phone,
    required String code,
    required String newPassword,
  }) async {
    try {
      AppLogger.info('🔄 [ApiService] Réinitialisation du mot de passe');

      final response = await dioService.post(
        ApiEndPoints.resetPassword,
        {
          "phone": phone,
          "code": code,
          "password": newPassword,
        },
      );

      if (response.statusCode == 200) {
        final message = response.data["message"] ?? "Mot de passe réinitialisé";
        AppLogger.info('✅ [ApiService] Mot de passe réinitialisé');
        return Right(message);
      } else {
        return Left(response.data["message"] ?? "Erreur de réinitialisation");
      }
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left("Erreur inattendue: ${e.toString()}");
    }
  }

  // 🔐 CHANGE PASSWORD
  Future<Either<String, String>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newConfirmPassword,
  }) async {
    try {
      AppLogger.info('🔐 [ApiService] Changement du mot de passe');

      final response = await dioService.post(
        ApiEndPoints.changePassword,
        {
          "current_password": currentPassword,
          "new_password": newPassword,
          "new_password_confirmation": newConfirmPassword,
        },
      );

      if (response.statusCode == 200) {
        final message = response.data["message"] ?? "Mot de passe modifié";
        AppLogger.info('✅ [ApiService] Mot de passe modifié');
        return Right(message);
      } else {
        return Left(response.data["message"] ?? "Erreur de modification");
      }
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left("Erreur inattendue: ${e.toString()}");
    }
  }

  // 🛠️ Gestion des erreurs Dio
  String _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return "Délai de connexion dépassé";
      case DioExceptionType.sendTimeout:
        return "Délai d'envoi dépassé";
      case DioExceptionType.receiveTimeout:
        return "Délai de réception dépassé";
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 401) {
          return "Identifiants incorrects";
        } else if (statusCode == 404) {
          return "Service non trouvé";
        } else if (statusCode == 422) {
          // Erreurs de validation Laravel
          final errors = e.response?.data["errors"];
          if (errors != null && errors is Map) {
            return errors.values.first[0] ?? "Erreur de validation";
          }
          return e.response?.data["message"] ?? "Données invalides";
        } else if (statusCode == 500) {
          return "Erreur serveur";
        }
        return e.response?.data["message"] ?? "Erreur: $statusCode";
      case DioExceptionType.cancel:
        return "Requête annulée";
      case DioExceptionType.connectionError:
        return "Pas de connexion Internet";
      default:
        return e.message ?? "Erreur réseau";
    }
  }
}