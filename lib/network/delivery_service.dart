import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:valeur_delivery/network/config/api_end_point.dart';
import '../data/models/delivery/assignment_detail_response.dart';
import '../data/models/delivery/deliveries_response.dart';
import '../data/models/delivery/today_orders_response.dart';
import 'config/app_logger.dart';
import 'config/dio.dart';


class DeliveryService {
  final DioService dioService;

  DeliveryService(this.dioService);

  /// Récupérer les livraisons du livreur
  Future<Either<String, DeliveriesResponse>> getMyDeliveries({
    int page = 1,
    int perPage = 50,
    String? status, // assigned, accepted, completed, failed
  }) async {
    try {
      AppLogger.info('📦 [DeliveryService] Récupération des livraisons');
      AppLogger.debug('   - Page: $page');
      AppLogger.debug('   - Per page: $perPage');
      if (status != null) AppLogger.debug('   - Status filter: $status');

      final queryParams = {
        'page': page,
        'per_page': perPage,
        if (status != null) 'status': status,
      };

      final response = await dioService.get(
        ApiEndPoints.myDeliveries,
        queryParams: queryParams,
      );

      if (response.statusCode == 200) {
        AppLogger.info('✅ [DeliveryService] Livraisons récupérées');
        final deliveriesResponse = DeliveriesResponse.fromJson(response.data);
        AppLogger.debug('   - Total: ${deliveriesResponse.meta.total}');
        AppLogger.debug('   - Current page: ${deliveriesResponse.meta.currentPage}');

        return Right(deliveriesResponse);
      } else {
        final message = response.data["message"] ?? "Erreur de récupération";
        AppLogger.error('❌ [DeliveryService] Erreur: $message');
        return Left(message);
      }
    } on DioException catch (e) {
      final message = _handleDioError(e);
      AppLogger.error('❌ [DeliveryService] Erreur Dio: $message');
      return Left(message);
    } catch (e) {
      AppLogger.error('❌ [DeliveryService] Erreur inattendue: $e');
      return Left("Erreur inattendue: ${e.toString()}");
    }
  }

  Future<Either<String, bool>> acceptAssignment(
      String orderUuid, {
        String? notes,
      }) async {
    try {
      AppLogger.info('✅ [DeliveryService] Acceptation de la livraison');
      AppLogger.debug('   - Order UUID: $orderUuid');
      if (notes != null) AppLogger.debug('   - Notes: $notes');

      final response = await dioService.post(
        '${ApiEndPoints.acceptOrRejectOrder}/$orderUuid/status',
        {
          'status': 'accepted',
          'notes': notes ?? '',
        },
      );

      if (response.statusCode == 200) {
        AppLogger.info('✅ [DeliveryService] Livraison acceptée');
        return const Right(true);
      } else {
        return Left(response.data["message"] ?? "Erreur d'acceptation");
      }
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left("Erreur inattendue: ${e.toString()}");
    }
  }

  /// Refuser une livraison
  Future<Either<String, bool>> rejectAssignment(
      String orderUuid, {
        String? notes,
      }) async {
    try {
      AppLogger.info('❌ [DeliveryService] Refus de la livraison');
      AppLogger.debug('   - Order UUID: $orderUuid');
      if (notes != null) AppLogger.debug('   - Notes: $notes');

      final response = await dioService.post(
        '${ApiEndPoints.acceptOrRejectOrder}/$orderUuid/status',
        {
          'status': 'cancelled',
          'notes': notes ?? '',
        },
      );

      if (response.statusCode == 200) {
        AppLogger.info('✅ [DeliveryService] Livraison refusée');
        return const Right(true);
      } else {
        return Left(response.data["message"] ?? "Erreur de refus");
      }
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left("Erreur inattendue: ${e.toString()}");
    }
  }

  /// Mettre à jour le statut d'une livraison
  Future<Either<String, bool>> updateAssignmentStatus(
      String orderUuid,
      String status, {
        String? notes,
      }) async {
    try {
      AppLogger.info('🔄 [DeliveryService] Mise à jour du statut');
      AppLogger.debug('   - Order UUID: $orderUuid');
      AppLogger.debug('   - Status: $status');
      if (notes != null) AppLogger.debug('   - Notes: $notes');

      final response = await dioService.post(
        '${ApiEndPoints.acceptOrRejectOrder}/$orderUuid/status',
        {
          'status': status,
          'notes': notes ?? '',
        },
      );

      if (response.statusCode == 200) {
        AppLogger.info('✅ [DeliveryService] Statut mis à jour');
        return const Right(true);
      } else {
        return Left(response.data["message"] ?? "Erreur de mise à jour");
      }
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
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
          return "Livraison non trouvée";
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

  /// Récupérer l'historique des livraisons (terminées/échouées)
  Future<Either<String, DeliveriesResponse>> getHistory({
    int page = 1,
    int perPage = 50,
    String? period, // today, week, month, all
    String? search,
  }) async {
    try {
      AppLogger.info('📜 [DeliveryService] Récupération de l\'historique');
      AppLogger.debug('   - Page: $page');
      AppLogger.debug('   - Per page: $perPage');
      if (period != null) AppLogger.debug('   - Period: $period');
      if (search != null) AppLogger.debug('   - Search: $search');

      final queryParams = {
        'page': page,
        'per_page': perPage,
        'status': 'completed,delivered,failed', // Filtrer les statuts terminés
        if (period != null) 'period': period,
        if (search != null && search.isNotEmpty) 'search': search,
      };

      final response = await dioService.get(
        ApiEndPoints.history, // ou Url.history si endpoint différent
        queryParams: queryParams,
      );

      if (response.statusCode == 200) {
        AppLogger.info('✅ [DeliveryService] Historique récupéré');
        final deliveriesResponse = DeliveriesResponse.fromJson(response.data);
        AppLogger.debug('   - Total: ${deliveriesResponse.meta.total}');

        return Right(deliveriesResponse);
      } else {
        final message = response.data["message"] ?? "Erreur de récupération";
        AppLogger.error('❌ [DeliveryService] Erreur: $message');
        return Left(message);
      }
    } on DioException catch (e) {
      final message = _handleDioError(e);
      AppLogger.error('❌ [DeliveryService] Erreur Dio: $message');
      return Left(message);
    } catch (e) {
      AppLogger.error('❌ [DeliveryService] Erreur inattendue: $e');
      return Left("Erreur inattendue: ${e.toString()}");
    }
  }

  Future<Either<String, AssignmentDetailResponse>> getOrderDetail(String orderUuid) async {
    try {
      AppLogger.info('📋 [DeliveryService] Récupération du détail de la commande');
      AppLogger.debug('   - Order UUID: $orderUuid');

      final response = await dioService.get(
        '${ApiEndPoints.orderDetail}/$orderUuid',
      );

      if (response.statusCode == 200) {
        AppLogger.info('✅ [DeliveryService] Détail de commande récupéré');
        final detailResponse = AssignmentDetailResponse.fromJson(response.data);
        AppLogger.debug('   - Order: ${detailResponse.data.order.orderNumber}');
        AppLogger.debug('   - Status: ${detailResponse.data.assignmentStatus}');

        return Right(detailResponse);
      } else {
        final message = response.data["message"] ?? "Erreur de récupération";
        AppLogger.error('❌ [DeliveryService] Erreur: $message');
        return Left(message);
      }
    } on DioException catch (e) {
      final message = _handleDioError(e);
      AppLogger.error('❌ [DeliveryService] Erreur Dio: $message');
      return Left(message);
    } catch (e) {
      AppLogger.error('❌ [DeliveryService] Erreur inattendue: $e');
      return Left("Erreur inattendue: ${e.toString()}");
    }
  }

  /// Récupérer les courses du jour
  /// Récupérer les courses du jour
  Future<Either<String, TodayOrdersResponse>> getTodayOrders() async {
    try {
      AppLogger.info('📅 [DeliveryService] Récupération des courses du jour');

      final response = await dioService.get(
        ApiEndPoints.deliveriesToday,
      );

      if (response.statusCode == 200) {
        AppLogger.info('✅ [DeliveryService] Courses du jour récupérées');

        try {
          // ✅ LOG LE JSON BRUT
          AppLogger.debug('📄 JSON RAW: ${response.data}');

          final todayOrdersResponse = TodayOrdersResponse.fromJson(response.data);

          AppLogger.debug('   - Total: ${todayOrdersResponse.total}');
          AppLogger.debug('   - Assignées: ${todayOrdersResponse.assignedOrders.length}');
          AppLogger.debug('   - Acceptées: ${todayOrdersResponse.acceptedOrders.length}');
          AppLogger.debug('   - Express: ${todayOrdersResponse.expressOrders.length}');

          return Right(todayOrdersResponse);
        } catch (parseError, stackTrace) {
          AppLogger.error('❌ [DeliveryService] Erreur parsing', parseError);
          AppLogger.debug('   - JSON: ${response.data}');
          AppLogger.debug('   - StackTrace: $stackTrace');
          return Left('Erreur de parsing: ${parseError.toString()}');
        }
      } else {
        final message = response.data["message"] ?? "Erreur de récupération";
        AppLogger.error('❌ [DeliveryService] Erreur: $message');
        return Left(message);
      }
    } on DioException catch (e) {
      final message = _handleDioError(e);
      AppLogger.error('❌ [DeliveryService] Erreur Dio: $message');
      return Left(message);
    } catch (e, stackTrace) {
      AppLogger.error('❌ [DeliveryService] Erreur inattendue: $e');
      AppLogger.debug('   - StackTrace: $stackTrace');
      return Left("Erreur inattendue: ${e.toString()}");
    }
  }
}