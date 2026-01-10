import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:valeur_delivery/network/config/api_end_point.dart';
import 'package:valeur_delivery/network/config/dio.dart';
import '../data/models/notifications/notification_model.dart';
import '../data/models/notifications/notifications_response.dart';
import 'config/app_logger.dart';

class NotificationService {
  final DioService _dioService;

  NotificationService(this._dioService);

  /// Récupérer les notifications de l'utilisateur
  Future<Either<String, NotificationsResponse>> getNotifications({
    required String userUuid,
  }) async {
    try {
      AppLogger.info('📬 [NotificationService] Récupération notifications');
      AppLogger.debug('   - User UUID: $userUuid');

      if (userUuid.isEmpty) {
        AppLogger.error('❌ [NotificationService] UUID vide');
        return const Left('UUID utilisateur invalide');
      }

      // ✅ Endpoint : /notifications/user/{userUuid}
      final url = '${ApiEndPoints.notifications}/$userUuid';
      AppLogger.debug('   - URL: $url');

      final response = await _dioService.get(url);

      if (response.statusCode == 200) {
        AppLogger.info('✅ [NotificationService] Notifications récupérées');

        try {
          final notificationsResponse = NotificationsResponse.fromJson(response.data);
          AppLogger.debug('   - Total: ${notificationsResponse.meta.total}');
          AppLogger.debug('   - Non lues: ${notificationsResponse.notifications.where((n) => !n.isRead).length}');

          return Right(notificationsResponse);
        } catch (parseError) {
          AppLogger.error('❌ [NotificationService] Erreur parsing', parseError);
          return Left('Erreur de parsing: ${parseError.toString()}');
        }
      } else {
        final message = response.data["message"] ?? "Erreur de récupération";
        AppLogger.error('❌ [NotificationService] Erreur: $message');
        return Left(message);
      }
    } on DioException catch (e) {
      final message = _handleDioError(e);
      AppLogger.error('❌ [NotificationService] Erreur Dio: $message');
      return Left(message);
    } catch (e) {
      AppLogger.error('❌ [NotificationService] Erreur inattendue: $e');
      return Left("Erreur inattendue: ${e.toString()}");
    }
  }

  /// Marquer une notification comme lue
  Future<Either<String, NotificationModel>> markAsRead(String notificationUuid) async {
    try {
      AppLogger.info('📖 [NotificationService] Marquer comme lue');
      AppLogger.debug('   - Notification UUID: $notificationUuid');

      // ✅ Endpoint : /notifications/{notificationUuid}/read
      final url = '${ApiEndPoints.readNotfication}/$notificationUuid/read';
      AppLogger.debug('   - URL: $url');

      final response = await _dioService.post(url, {});

      if (response.statusCode == 200) {
        AppLogger.info('✅ [NotificationService] Notification marquée comme lue');
        final notification = NotificationModel.fromJson(response.data['data']);
        return Right(notification);
      } else {
        final message = response.data["message"] ?? "Erreur de marquage";
        AppLogger.error('❌ [NotificationService] Erreur: $message');
        return Left(message);
      }
    } on DioException catch (e) {
      final message = _handleDioError(e);
      AppLogger.error('❌ [NotificationService] Erreur Dio: $message');
      return Left(message);
    } catch (e) {
      AppLogger.error('❌ [NotificationService] Erreur inattendue: $e');
      return Left("Erreur inattendue: ${e.toString()}");
    }
  }

  /// Marquer toutes les notifications comme lues
  Future<Either<String, bool>> markAllAsRead(String userUuid) async {
    try {
      AppLogger.info('📖 [NotificationService] Tout marquer comme lu');
      AppLogger.debug('   - User UUID: $userUuid');

      // ✅ Endpoint : /notifications/user/{userUuid}/read-all
      // OU si l'API attend : /notifications/read-all (avec token JWT)
      final url = '${ApiEndPoints.readNotfication}/$userUuid/read-all';
      AppLogger.debug('   - URL: $url');

      final response = await _dioService.post(url, {});

      if (response.statusCode == 200) {
        AppLogger.info('✅ [NotificationService] Toutes marquées comme lues');
        return const Right(true);
      } else {
        final message = response.data["message"] ?? "Erreur de marquage";
        AppLogger.error('❌ [NotificationService] Erreur: $message');
        return Left(message);
      }
    } on DioException catch (e) {
      final message = _handleDioError(e);
      AppLogger.error('❌ [NotificationService] Erreur Dio: $message');
      return Left(message);
    } catch (e) {
      AppLogger.error('❌ [NotificationService] Erreur inattendue: $e');
      return Left("Erreur inattendue: ${e.toString()}");
    }
  }

  /// Supprimer une notification
  Future<Either<String, bool>> deleteNotification(String notificationUuid) async {
    try {
      AppLogger.info('🗑️ [NotificationService] Suppression notification');
      AppLogger.debug('   - Notification UUID: $notificationUuid');

      // ✅ Endpoint : /notifications/{notificationUuid}
      final url = '${ApiEndPoints.notifications}/$notificationUuid';
      AppLogger.debug('   - URL: $url');

      final response = await _dioService.delete(url);

      if (response.statusCode == 200) {
        AppLogger.info('✅ [NotificationService] Notification supprimée');
        return const Right(true);
      } else {
        final message = response.data["message"] ?? "Erreur de suppression";
        AppLogger.error('❌ [NotificationService] Erreur: $message');
        return Left(message);
      }
    } on DioException catch (e) {
      final message = _handleDioError(e);
      AppLogger.error('❌ [NotificationService] Erreur Dio: $message');
      return Left(message);
    } catch (e) {
      AppLogger.error('❌ [NotificationService] Erreur inattendue: $e');
      return Left("Erreur inattendue: ${e.toString()}");
    }
  }

  /// Gestion des erreurs Dio
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
          return "Non autorisé - Veuillez vous reconnecter";
        } else if (statusCode == 404) {
          final message = e.response?.data?["message"] as String?;
          if (message != null && message.contains("No query results")) {
            return "Utilisateur non trouvé - Veuillez vous reconnecter";
          }
          return "Notification non trouvée";
        } else if (statusCode == 422) {
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