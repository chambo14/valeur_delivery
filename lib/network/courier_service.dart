import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:valeur_delivery/network/config/api_end_point.dart';
import '../../data/models/courier/courier_profile_response.dart';
import 'config/app_logger.dart';
import 'config/dio.dart';

class CourierService {
  final DioService dioService;

  CourierService(this.dioService);

  /// Récupérer le profil du livreur
  Future<Either<String, CourierProfileResponse>> getProfile() async {
    try {
      AppLogger.info('👤 [CourierService] Récupération du profil');

      final response = await dioService.get(ApiEndPoints.courierProfile);

      if (response.statusCode == 200) {
        AppLogger.info('✅ [CourierService] Profil récupéré');
        final profileResponse = CourierProfileResponse.fromJson(response.data);
        AppLogger.debug('   - User: ${profileResponse.data.user.name}');
        AppLogger.debug('   - Status: ${profileResponse.data.status}');

        return Right(profileResponse);
      } else {
        final message = response.data["message"] ?? "Erreur de récupération";
        AppLogger.error('❌ [CourierService] Erreur: $message');
        return Left(message);
      }
    } on DioException catch (e) {
      final message = _handleDioError(e);
      AppLogger.error('❌ [CourierService] Erreur Dio: $message');
      return Left(message);
    } catch (e) {
      AppLogger.error('❌ [CourierService] Erreur inattendue: $e');
      return Left("Erreur inattendue: ${e.toString()}");
    }
  }

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
          return "Non autorisé";
        } else if (statusCode == 404) {
          return "Profil non trouvé";
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