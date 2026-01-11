import 'assignment.dart';

class TodayOrdersResponse {
  final List<Assignment> data;

  TodayOrdersResponse({
    required this.data,
  });

  factory TodayOrdersResponse.fromJson(Map<String, dynamic> json) {
    try {
      // ✅ Gérer si 'data' est null ou manquant
      final dataList = json['data'] as List? ?? [];

      return TodayOrdersResponse(
        data: dataList
            .map((item) => Assignment.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
    } catch (e, stackTrace) {
      print('❌ [TodayOrdersResponse] Parse error: $e');
      print('   JSON: $json');
      print('   StackTrace: $stackTrace');
      rethrow;
    }
  }

  int get total => data.length;

  List<Assignment> get assignedOrders =>
      data.where((a) => a.isAssigned).toList();

  List<Assignment> get acceptedOrders =>
      data.where((a) => a.isAccepted).toList();

  List<Assignment> get expressOrders =>
      data.where((a) => a.order.isExpress).toList();

  @override
  String toString() => 'TodayOrdersResponse(total: $total)';
}
