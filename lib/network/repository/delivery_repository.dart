import 'package:dartz/dartz.dart';
import '../../data/models/delivery/assignment_detail_response.dart';
import '../../data/models/delivery/deliveries_response.dart';
import '../../data/models/delivery/today_orders_response.dart';
import '../delivery_service.dart';


class DeliveryRepository {
  final DeliveryService deliveryService;

  DeliveryRepository(this.deliveryService);

  Future<Either<String, TodayOrdersResponse>> getTodayOrders() async {
    return await deliveryService.getTodayOrders();}

  Future<Either<String, DeliveriesResponse>> getMyDeliveries({
    int page = 1,
    int perPage = 50,
    String? status,
  }) async {
    return await deliveryService.getMyDeliveries(
      page: page,
      perPage: perPage,
      status: status,
    );
  }

  Future<Either<String, bool>> acceptAssignment(
      String orderUuid, {
        String? notes,
      }) async {
    return await deliveryService.acceptAssignment(orderUuid, notes: notes);
  }

  Future<Either<String, bool>> rejectAssignment(
      String orderUuid, {
        String? notes,
      }) async {
    return await deliveryService.rejectAssignment(orderUuid, notes: notes);
  }

  Future<Either<String, bool>> updateAssignmentStatus(
      String orderUuid,
      String status, {
        String? notes,
      }) async {
    return await deliveryService.updateAssignmentStatus(
      orderUuid,
      status,
      notes: notes,
    );
  }






  Future<Either<String, AssignmentDetailResponse>> getOrderDetail(String orderUuid) async {
    return await deliveryService.getOrderDetail(orderUuid);}




  Future<Either<String, DeliveriesResponse>> getHistory({
    int page = 1,
    int perPage = 50,
    String? period,
    String? search,
  }) async {
    return await deliveryService.getHistory(
      page: page,
      perPage: perPage,
      period: period,
      search: search,
    );
  }
}