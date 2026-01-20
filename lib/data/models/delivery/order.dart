// models/order.dart

import 'order_item.dart';
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
  final double? deliveryLatitude;
  final double? deliveryLongitude;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final bool isExpress;
  final String? orderStatus;
  final DateTime createdAt;
  final String? barcodeValue;
  final DateTime? reservedAt;
  final String? orderAmount;
  final String? packageWeightKg;
  final Zone zone;
  final Pricing pricing;
  final List<OrderItem> items;

  Order({
    this.orderUuid,
    this.orderNumber,
    this.customerName,
    this.customerPhone,
    this.customerEmail,
    this.pickupAddress,
    this.deliveryAddress,
    this.deliveryLatitude,
    this.deliveryLongitude,
    this.pickupLatitude,
    this.pickupLongitude,
    this.isExpress = false,
    this.orderStatus,
    required this.createdAt,
    this.barcodeValue,
    this.reservedAt,
    this.orderAmount,
    this.packageWeightKg,
    required this.zone,
    required this.pricing,
    this.items = const [],
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    try {
      final zoneData = json['zone'];
      final pricingData = json['pricing'];
      final itemsData = json['items'];

      // Support des deux formats de coordonnées
      double? deliveryLat;
      double? deliveryLng;
      double? pickupLat;
      double? pickupLng;

      // Format objet : delivery_location: {latitude, longitude}
      if (json['delivery_location'] is Map<String, dynamic>) {
        final loc = json['delivery_location'] as Map<String, dynamic>;
        deliveryLat = (loc['latitude'] as num?)?.toDouble();
        deliveryLng = (loc['longitude'] as num?)?.toDouble();
      } else {
        // Format plat : delivery_latitude, delivery_longitude
        deliveryLat = _parseDouble(json['delivery_latitude']);
        deliveryLng = _parseDouble(json['delivery_longitude']);
      }

      if (json['pickup_location'] is Map<String, dynamic>) {
        final loc = json['pickup_location'] as Map<String, dynamic>;
        pickupLat = (loc['latitude'] as num?)?.toDouble();
        pickupLng = (loc['longitude'] as num?)?.toDouble();
      } else {
        pickupLat = _parseDouble(json['pickup_latitude']);
        pickupLng = _parseDouble(json['pickup_longitude']);
      }

      return Order(
        orderUuid: json['order_uuid'] as String? ?? json['uuid'] as String?,
        orderNumber: json['order_number'] as String?,
        customerName: json['customer_name'] as String?,
        customerPhone: json['customer_phone'] as String?,
        customerEmail: json['customer_email'] as String?,
        pickupAddress: json['pickup_address'] as String?,
        deliveryAddress: json['delivery_address'] as String?,
        deliveryLatitude: deliveryLat,
        deliveryLongitude: deliveryLng,
        pickupLatitude: pickupLat,
        pickupLongitude: pickupLng,
        isExpress: json['is_express'] == true ||
            json['is_express'] == 1 ||
            json['is_express'] == '1',
        orderStatus: json['order_status'] as String? ?? json['status'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
        barcodeValue: json['barcode_value'] as String?,
        reservedAt: _parseDateTime(json['reserved_at']),
        orderAmount: json['order_amount'] as String?,
        packageWeightKg: json['package_weight_kg'] as String?,
        zone: zoneData != null && zoneData is Map<String, dynamic>
            ? Zone.fromJson(zoneData)
            : Zone.fromJson(json),
        pricing: pricingData != null && pricingData is Map<String, dynamic>
            ? Pricing.fromJson(pricingData)
            : Pricing.empty(),
        items: itemsData != null && itemsData is List
            ? itemsData
            .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
            .toList()
            : [],
      );
    } catch (e, stackTrace) {
      print('❌ [Order] Parse error: $e');
      print('   JSON: $json');
      print('   StackTrace: $stackTrace');
      rethrow;
    }
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        print('❌ Error parsing date: $value - $e');
        return null;
      }
    }
    return null;
  }

  // Vérifier si les coordonnées de livraison existent
  bool get hasDeliveryCoordinates =>
      deliveryLatitude != null && deliveryLongitude != null;

  // Vérifier si les coordonnées de pickup existent
  bool get hasPickupCoordinates =>
      pickupLatitude != null && pickupLongitude != null;

  // Montant formaté
  String get formattedAmount {
    if (orderAmount == null) return '0 FCFA';
    final amount = double.tryParse(orderAmount!) ?? 0;
    return '${amount.toStringAsFixed(0)} FCFA';
  }

  // Poids formaté
  String get formattedWeight {
    if (packageWeightKg == null) return '';
    return '$packageWeightKg kg';
  }

  // UUID raccourci
  String get uuid => orderUuid ?? '';

  Map<String, dynamic> toJson() {
    return {
      'order_uuid': orderUuid,
      'order_number': orderNumber,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_email': customerEmail,
      'pickup_address': pickupAddress,
      'delivery_address': deliveryAddress,
      'delivery_latitude': deliveryLatitude,
      'delivery_longitude': deliveryLongitude,
      'pickup_latitude': pickupLatitude,
      'pickup_longitude': pickupLongitude,
      'is_express': isExpress,
      'order_status': orderStatus,
      'created_at': createdAt.toIso8601String(),
      'barcode_value': barcodeValue,
      'reserved_at': reservedAt?.toIso8601String(),
      'order_amount': orderAmount,
      'package_weight_kg': packageWeightKg,
      'zone': zone.toJson(),
      'pricing': pricing.toJson(),
      'items': items.map((e) => e.toJson()).toList(),
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
    double? deliveryLatitude,
    double? deliveryLongitude,
    double? pickupLatitude,
    double? pickupLongitude,
    bool? isExpress,
    String? orderStatus,
    DateTime? createdAt,
    String? barcodeValue,
    DateTime? reservedAt,
    String? orderAmount,
    String? packageWeightKg,
    Zone? zone,
    Pricing? pricing,
    List<OrderItem>? items,
  }) {
    return Order(
      orderUuid: orderUuid ?? this.orderUuid,
      orderNumber: orderNumber ?? this.orderNumber,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryLatitude: deliveryLatitude ?? this.deliveryLatitude,
      deliveryLongitude: deliveryLongitude ?? this.deliveryLongitude,
      pickupLatitude: pickupLatitude ?? this.pickupLatitude,
      pickupLongitude: pickupLongitude ?? this.pickupLongitude,
      isExpress: isExpress ?? this.isExpress,
      orderStatus: orderStatus ?? this.orderStatus,
      createdAt: createdAt ?? this.createdAt,
      barcodeValue: barcodeValue ?? this.barcodeValue,
      reservedAt: reservedAt ?? this.reservedAt,
      orderAmount: orderAmount ?? this.orderAmount,
      packageWeightKg: packageWeightKg ?? this.packageWeightKg,
      zone: zone ?? this.zone,
      pricing: pricing ?? this.pricing,
      items: items ?? this.items,
    );
  }

  @override
  String toString() => 'Order(number: $orderNumber, customer: $customerName)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Order && other.orderUuid == orderUuid;
  }

  @override
  int get hashCode => orderUuid.hashCode;
}

