import 'assignment.dart';

class TodayOrdersResponse {
  final List<Assignment> data;

  TodayOrdersResponse({
    required this.data,
  });

  factory TodayOrdersResponse.fromJson(Map<String, dynamic> json) {
    return TodayOrdersResponse(
      data: (json['data'] as List)
          .map((item) => Assignment.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data.map((assignment) => assignment.toJson()).toList(),
    };
  }

  // Helpers
  int get total => data.length;
  bool get isEmpty => data.isEmpty;
  bool get isNotEmpty => data.isNotEmpty;

  List<Assignment> get assignedOrders =>
      data.where((a) => a.isAssigned).toList();

  List<Assignment> get acceptedOrders =>
      data.where((a) => a.isAccepted).toList();

  List<Assignment> get expressOrders =>
      data.where((a) => a.order.isExpress).toList();

  @override
  String toString() => 'TodayOrdersResponse(total: $total)';
}