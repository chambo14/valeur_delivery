import 'zone.dart';
import 'pricing.dart';

class Order {
  final String? orderUuid;
  final String? orderNumber;
  final String? customerName;
  final String? customerPhone;
  final String? customerEmail;
  final String? pickupAddress;
  final String? deliveryAddress;
  final bool isExpress;
  final String? orderStatus;
  final DateTime createdAt;
  final Zone zone;
  final Pricing pricing;

  Order({
    this.orderUuid,
    this.orderNumber,
    this.customerName,
    this.customerPhone,
    this.customerEmail,
    this.pickupAddress,
    this.deliveryAddress,
    this.isExpress = false,
    this.orderStatus,
    required this.createdAt,
    required this.zone,
    required this.pricing,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    try {
      // ✅ CRITICAL : Gérer zone et pricing null
      final zoneData = json['zone'];
      final pricingData = json['pricing'];

      return Order(
        orderUuid: json['order_uuid'] as String? ?? json['uuid'] as String?,
        orderNumber: json['order_number'] as String?,
        customerName: json['customer_name'] as String?,
        customerPhone: json['customer_phone'] as String?,
        customerEmail: json['customer_email'] as String?,
        pickupAddress: json['pickup_address'] as String?,
        deliveryAddress: json['delivery_address'] as String?,
        isExpress: json['is_express'] == true ||
            json['is_express'] == 1 ||
            json['is_express'] == '1',
        orderStatus: json['order_status'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
        // ✅ Si zone est null, créer un objet par défaut
        zone: zoneData != null && zoneData is Map<String, dynamic>
            ? Zone.fromJson(zoneData)
            : Zone.empty(),
        // ✅ Si pricing est null, créer un objet par défaut
        pricing: pricingData != null && pricingData is Map<String, dynamic>
            ? Pricing.fromJson(pricingData)
            : Pricing.empty(),
      );
    } catch (e, stackTrace) {
      print('❌ [Order] Parse error: $e');
      print('   JSON: $json');
      print('   StackTrace: $stackTrace');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'order_uuid': orderUuid,
      'order_number': orderNumber,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_email': customerEmail,
      'pickup_address': pickupAddress,
      'delivery_address': deliveryAddress,
      'is_express': isExpress,
      'order_status': orderStatus,
      'created_at': createdAt.toIso8601String(),
      'zone': zone.toJson(),
      'pricing': pricing.toJson(),
    };
  }

  Order copyWith({
    String? orderUuid,
    String? orderNumber,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    String? pickupAddress,
    String? deliveryAddress,
    bool? isExpress,
    String? orderStatus,
    DateTime? createdAt,
    Zone? zone,
    Pricing? pricing,
  }) {
    return Order(
      orderUuid: orderUuid ?? this.orderUuid,
      orderNumber: orderNumber ?? this.orderNumber,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      isExpress: isExpress ?? this.isExpress,
      orderStatus: orderStatus ?? this.orderStatus,
      createdAt: createdAt ?? this.createdAt,
      zone: zone ?? this.zone,
      pricing: pricing ?? this.pricing,
    );
  }

  String get uuid => orderUuid ?? '';

  @override
  String toString() => 'Order(number: $orderNumber, customer: $customerName)';
}