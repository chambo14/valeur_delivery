class Delivery {
  final String id;
  final String orderNumber;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final double latitude;
  final double longitude;
  final String pickupAddress;
  final double pickupLatitude;
  final double pickupLongitude;
  final String partnerName;
  final DeliveryStatus status;
  final DateTime scheduledDate;
  final DateTime? pickupTime;
  final DateTime? deliveryTime;
  final String? notes;
  final List<DeliveryItem> items;
  final double totalAmount;
  final String? photoUrl;

  Delivery({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    required this.latitude,
    required this.longitude,
    required this.pickupAddress,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.partnerName,
    required this.status,
    required this.scheduledDate,
    this.pickupTime,
    this.deliveryTime,
    this.notes,
    required this.items,
    required this.totalAmount,
    this.photoUrl,
  });

  Delivery copyWith({
    String? id,
    String? orderNumber,
    String? customerName,
    String? customerPhone,
    String? customerAddress,
    double? latitude,
    double? longitude,
    String? pickupAddress,
    double? pickupLatitude,
    double? pickupLongitude,
    String? partnerName,
    DeliveryStatus? status,
    DateTime? scheduledDate,
    DateTime? pickupTime,
    DateTime? deliveryTime,
    String? notes,
    List<DeliveryItem>? items,
    double? totalAmount,
    String? photoUrl,
  }) {
    return Delivery(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerAddress: customerAddress ?? this.customerAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      pickupLatitude: pickupLatitude ?? this.pickupLatitude,
      pickupLongitude: pickupLongitude ?? this.pickupLongitude,
      partnerName: partnerName ?? this.partnerName,
      status: status ?? this.status,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      pickupTime: pickupTime ?? this.pickupTime,
      deliveryTime: deliveryTime ?? this.deliveryTime,
      notes: notes ?? this.notes,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerAddress': customerAddress,
      'latitude': latitude,
      'longitude': longitude,
      'pickupAddress': pickupAddress,
      'pickupLatitude': pickupLatitude,
      'pickupLongitude': pickupLongitude,
      'partnerName': partnerName,
      'status': status.name,
      'scheduledDate': scheduledDate.toIso8601String(),
      'pickupTime': pickupTime?.toIso8601String(),
      'deliveryTime': deliveryTime?.toIso8601String(),
      'notes': notes,
      'items': items.map((item) => item.toJson()).toList(),
      'totalAmount': totalAmount,
      'photoUrl': photoUrl,
    };
  }

  factory Delivery.fromJson(Map<String, dynamic> json) {
    return Delivery(
      id: json['id'],
      orderNumber: json['orderNumber'],
      customerName: json['customerName'],
      customerPhone: json['customerPhone'],
      customerAddress: json['customerAddress'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      pickupAddress: json['pickupAddress'],
      pickupLatitude: json['pickupLatitude'],
      pickupLongitude: json['pickupLongitude'],
      partnerName: json['partnerName'],
      status: DeliveryStatus.values.firstWhere(
            (e) => e.name == json['status'],
        orElse: () => DeliveryStatus.pending,
      ),
      scheduledDate: DateTime.parse(json['scheduledDate']),
      pickupTime: json['pickupTime'] != null
          ? DateTime.parse(json['pickupTime'])
          : null,
      deliveryTime: json['deliveryTime'] != null
          ? DateTime.parse(json['deliveryTime'])
          : null,
      notes: json['notes'],
      items: (json['items'] as List)
          .map((item) => DeliveryItem.fromJson(item))
          .toList(),
      totalAmount: json['totalAmount'].toDouble(),
      photoUrl: json['photoUrl'],
    );
  }
}

enum DeliveryStatus {
  pending,
  assigned,
  pickedUp,
  inTransit,
  delivered,
  failed,
  cancelled
}

class DeliveryItem {
  final String name;
  final int quantity;
  final String? description;

  DeliveryItem({
    required this.name,
    required this.quantity,
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'description': description,
    };
  }

  factory DeliveryItem.fromJson(Map<String, dynamic> json) {
    return DeliveryItem(
      name: json['name'],
      quantity: json['quantity'],
      description: json['description'],
    );
  }
}

extension DeliveryStatusExtension on DeliveryStatus {
  String get displayName {
    switch (this) {
      case DeliveryStatus.pending:
        return 'En attente';
      case DeliveryStatus.assigned:
        return 'Attribuée';
      case DeliveryStatus.pickedUp:
        return 'Récupérée';
      case DeliveryStatus.inTransit:
        return 'En cours';
      case DeliveryStatus.delivered:
        return 'Livrée';
      case DeliveryStatus.failed:
        return 'Non livrée';
      case DeliveryStatus.cancelled:
        return 'Annulée';
    }
  }

  String get icon {
    switch (this) {
      case DeliveryStatus.pending:
        return '⏳';
      case DeliveryStatus.assigned:
        return '📋';
      case DeliveryStatus.pickedUp:
        return '📦';
      case DeliveryStatus.inTransit:
        return '🏍️';
      case DeliveryStatus.delivered:
        return '✅';
      case DeliveryStatus.failed:
        return '❌';
      case DeliveryStatus.cancelled:
        return '🚫';
    }
  }
}