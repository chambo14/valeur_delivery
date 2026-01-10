class DeliveryDriver {
  final String id;
  final String fullName;
  final String phone;
  final String email;
  final String? photoUrl;
  final String? vehicleType;
  final String? vehiclePlate;
  final bool isActive;
  final DateTime createdAt;
  final int totalDeliveries;
  final int successfulDeliveries;
  final double rating;

  DeliveryDriver({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    this.photoUrl,
    this.vehicleType,
    this.vehiclePlate,
    this.isActive = true,
    required this.createdAt,
    this.totalDeliveries = 0,
    this.successfulDeliveries = 0,
    this.rating = 0.0,
  });

  double get successRate {
    if (totalDeliveries == 0) return 0.0;
    return (successfulDeliveries / totalDeliveries) * 100;
  }

  DeliveryDriver copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? email,
    String? photoUrl,
    String? vehicleType,
    String? vehiclePlate,
    bool? isActive,
    DateTime? createdAt,
    int? totalDeliveries,
    int? successfulDeliveries,
    double? rating,
  }) {
    return DeliveryDriver(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      vehicleType: vehicleType ?? this.vehicleType,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
      successfulDeliveries: successfulDeliveries ?? this.successfulDeliveries,
      rating: rating ?? this.rating,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'phone': phone,
      'email': email,
      'photoUrl': photoUrl,
      'vehicleType': vehicleType,
      'vehiclePlate': vehiclePlate,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'totalDeliveries': totalDeliveries,
      'successfulDeliveries': successfulDeliveries,
      'rating': rating,
    };
  }

  factory DeliveryDriver.fromJson(Map<String, dynamic> json) {
    return DeliveryDriver(
      id: json['id'],
      fullName: json['fullName'],
      phone: json['phone'],
      email: json['email'],
      photoUrl: json['photoUrl'],
      vehicleType: json['vehicleType'],
      vehiclePlate: json['vehiclePlate'],
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      totalDeliveries: json['totalDeliveries'] ?? 0,
      successfulDeliveries: json['successfulDeliveries'] ?? 0,
      rating: json['rating']?.toDouble() ?? 0.0,
    );
  }
}