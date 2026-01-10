import 'zone.dart';
import 'pricing.dart';
import 'order_item.dart';

class Order {
  final String uuid;
  final String orderNumber;
  final String customerName;
  final String customerPhone;
  final String deliveryAddress;
  final String pickupAddress;
  final String status;
  final bool isExpress;
  final DateTime reservedAt;
  final String barcodeValue;
  final Zone zone;
  final Pricing? pricing;
  final List<OrderItem> items;

  Order({
    required this.uuid,
    required this.orderNumber,
    required this.customerName,
    required this.customerPhone,
    required this.deliveryAddress,
    required this.pickupAddress,
    required this.status,
    required this.isExpress,
    required this.reservedAt,
    required this.barcodeValue,
    required this.zone,
    this.pricing,
    this.items = const [],
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      uuid: json['uuid'] as String,
      orderNumber: json['order_number'] as String,
      customerName: json['customer_name'] as String,
      customerPhone: json['customer_phone'] as String,
      deliveryAddress: json['delivery_address'] as String,
      pickupAddress: json['pickup_address'] as String,
      status: json['status'] as String,
      isExpress: json['is_express'] as bool,
      reservedAt: DateTime.parse(json['reserved_at'] as String),
      barcodeValue: json['barcode_value'] as String,
      zone: Zone.fromJson(json['zone'] as Map<String, dynamic>),
      pricing: json['pricing'] != null
          ? Pricing.fromJson(json['pricing'] as Map<String, dynamic>)
          : null,
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'order_number': orderNumber,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'delivery_address': deliveryAddress,
      'pickup_address': pickupAddress,
      'status': status,
      'is_express': isExpress,
      'reserved_at': reservedAt.toIso8601String(),
      'barcode_value': barcodeValue,
      'zone': zone.toJson(),
      'pricing': pricing?.toJson(),
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  // Helpers
  String get statusDisplay {
    switch (status.toLowerCase()) {
      case 'assigned':
        return 'Assignée';
      case 'accepted':
        return 'Acceptée';
      case 'picked_up':
        return 'Récupérée';
      case 'in_transit':
        return 'En transit';
      case 'delivered':
        return 'Livrée';
      case 'failed':
        return 'Échouée';
      default:
        return status;
    }
  }

  Order copyWith({
    String? uuid,
    String? orderNumber,
    String? customerName,
    String? customerPhone,
    String? deliveryAddress,
    String? pickupAddress,
    String? status,
    bool? isExpress,
    DateTime? reservedAt,
    String? barcodeValue,
    Zone? zone,
    Pricing? pricing,
    List<OrderItem>? items,
  }) {
    return Order(
      uuid: uuid ?? this.uuid,
      orderNumber: orderNumber ?? this.orderNumber,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      status: status ?? this.status,
      isExpress: isExpress ?? this.isExpress,
      reservedAt: reservedAt ?? this.reservedAt,
      barcodeValue: barcodeValue ?? this.barcodeValue,
      zone: zone ?? this.zone,
      pricing: pricing ?? this.pricing,
      items: items ?? this.items,
    );
  }

  @override
  String toString() => 'Order(orderNumber: $orderNumber, status: $status)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Order && other.uuid == uuid;
  }

  @override
  int get hashCode => uuid.hashCode;
}