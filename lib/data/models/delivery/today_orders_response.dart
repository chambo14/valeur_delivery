// models/today_orders_response.dart

import 'assignment.dart';
import 'pagination_meta.dart';

class TodayOrdersResponse {
  final List<Assignment> data;
  final PaginationMeta? meta;

  TodayOrdersResponse({
    required this.data,
    this.meta,
  });

  factory TodayOrdersResponse.fromJson(Map<String, dynamic> json) {
    return TodayOrdersResponse(
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => Assignment.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
      meta: json['meta'] != null
          ? PaginationMeta.fromJson(json['meta'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'data': data.map((e) => e.toJson()).toList(),
    if (meta != null) 'meta': meta!.toJson(),
  };

  // ✅ Helpers de base
  bool get isEmpty => data.isEmpty;
  bool get isNotEmpty => data.isNotEmpty;
  int get total => data.length;

  // ✅ Filtres par statut
  List<Assignment> get assignedOrders =>
      data.where((a) => a.isAssigned).toList();

  List<Assignment> get acceptedOrders =>
      data.where((a) => a.isAccepted).toList();

  List<Assignment> get pickedOrders =>
      data.where((a) => a.isPicked).toList();

  List<Assignment> get deliveringOrders =>
      data.where((a) => a.isDelivering).toList();

  List<Assignment> get completedOrders =>
      data.where((a) => a.isCompleted).toList();

  // ✅ Filtres express
  List<Assignment> get expressOrders =>
      data.where((a) => a.order.isExpress).toList();

  // ✅ Compteurs
  int get assignedCount => assignedOrders.length;
  int get acceptedCount => acceptedOrders.length;
  int get pickedCount => pickedOrders.length;
  int get deliveringCount => deliveringOrders.length;
  int get completedCount => completedOrders.length;
  int get expressCount => expressOrders.length;

  @override
  String toString() => 'TodayOrdersResponse(total: $total, assigned: $assignedCount, accepted: $acceptedCount)';
}