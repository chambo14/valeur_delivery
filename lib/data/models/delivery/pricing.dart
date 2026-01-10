class Pricing {
  final String distanceKm;
  final String vehicleType;
  final String price;
  final int? estimatedTimeMinutes;

  Pricing({
    required this.distanceKm,
    required this.vehicleType,
    required this.price,
    this.estimatedTimeMinutes,
  });

  factory Pricing.fromJson(Map<String, dynamic> json) {
    return Pricing(
      distanceKm: json['distance_km'] as String,
      vehicleType: json['vehicle_type'] as String,
      price: json['price'] as String,
      estimatedTimeMinutes: json['estimated_time_minutes'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'distance_km': distanceKm,
      'vehicle_type': vehicleType,
      'price': price,
      'estimated_time_minutes': estimatedTimeMinutes,
    };
  }

  // Helpers
  double get distanceKmDouble => double.tryParse(distanceKm) ?? 0.0;
  double get priceDouble => double.tryParse(price) ?? 0.0;
  int get priceInt => priceDouble.toInt();

  String get vehicleTypeDisplay {
    switch (vehicleType.toLowerCase()) {
      case 'voiture':
        return 'Voiture';
      case 'moto':
        return 'Moto';
      case 'velo':
        return 'Vélo';
      default:
        return vehicleType;
    }
  }

  Pricing copyWith({
    String? distanceKm,
    String? vehicleType,
    String? price,
    int? estimatedTimeMinutes,
  }) {
    return Pricing(
      distanceKm: distanceKm ?? this.distanceKm,
      vehicleType: vehicleType ?? this.vehicleType,
      price: price ?? this.price,
      estimatedTimeMinutes: estimatedTimeMinutes ?? this.estimatedTimeMinutes,
    );
  }

  @override
  String toString() =>
      'Pricing(distance: $distanceKm km, vehicle: $vehicleType, price: $price FCFA)';
}