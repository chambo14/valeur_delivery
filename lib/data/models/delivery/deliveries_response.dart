import 'assignment.dart';
import 'pagination_meta.dart';

class DeliveriesResponse {
  final List<Assignment> data;
  final PaginationMeta meta;

  DeliveriesResponse({
    required this.data,
    required this.meta,
  });

  factory DeliveriesResponse.fromJson(Map<String, dynamic> json) {
    return DeliveriesResponse(
      data: (json['data'] as List<dynamic>)
          .map((item) => Assignment.fromJson(item as Map<String, dynamic>))
          .toList(),
      meta: PaginationMeta.fromJson(json['meta'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data.map((item) => item.toJson()).toList(),
      'meta': meta.toJson(),
    };
  }

  DeliveriesResponse copyWith({
    List<Assignment>? data,
    PaginationMeta? meta,
  }) {
    return DeliveriesResponse(
      data: data ?? this.data,
      meta: meta ?? this.meta,
    );
  }

  @override
  String toString() =>
      'DeliveriesResponse(assignments: ${data.length}, page: ${meta.currentPage})';
}