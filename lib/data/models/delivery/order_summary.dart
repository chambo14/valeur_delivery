class OrderSummaryResponse {
  final OrderSummary data;

  OrderSummaryResponse({required this.data});

  factory OrderSummaryResponse.fromJson(Map<String, dynamic> json) {
    return OrderSummaryResponse(
      data: OrderSummary.fromJson(json['data'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data.toJson(),
    };
  }
}

class OrderSummary {
  final int pending;
  final int inProgress;
  final int delivered;
  final int returned;
  final int canceled;

  OrderSummary({
    this.pending = 0,
    this.inProgress = 0,
    this.delivered = 0,
    this.returned = 0,
    this.canceled = 0,
  });

  factory OrderSummary.fromJson(Map<String, dynamic> json) {
    return OrderSummary(
      pending: _toInt(json['pending']),
      inProgress: _toInt(json['in_progress']),
      delivered: _toInt(json['delivered']),
      returned: _toInt(json['returned']),
      canceled: _toInt(json['canceled']),
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'pending': pending,
      'in_progress': inProgress,
      'delivered': delivered,
      'returned': returned,
      'canceled': canceled,
    };
  }

  // Getters utiles
  int get total => pending + inProgress + delivered + returned + canceled;
  int get active => pending + inProgress;
  int get completed => delivered + returned + canceled;

  @override
  String toString() {
    return 'OrderSummary(pending: $pending, inProgress: $inProgress, delivered: $delivered, returned: $returned, canceled: $canceled)';
  }
}