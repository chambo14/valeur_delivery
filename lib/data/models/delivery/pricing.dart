class Pricing {
  final String? pricingUuid;
  final String? name;
  final double basePrice;
  final double? expressMultiplier;

  // ✅ NOUVEAUX CHAMPS pour correspondre à la réponse API
  final double? distanceKm;
  final String? vehicleType;
  final double price;
  final int? estimatedTimeMinutes;

  Pricing({
    this.pricingUuid,
    this.name,
    this.basePrice = 0.0,
    this.expressMultiplier,
    this.distanceKm,
    this.vehicleType,
    this.price = 0.0,
    this.estimatedTimeMinutes,
  });

  factory Pricing.empty() {
    return Pricing(
      pricingUuid: 'unknown',
      name: 'Tarif standard',
      basePrice: 0.0,
      expressMultiplier: null,
      distanceKm: null,
      vehicleType: null,
      price: 0.0,
      estimatedTimeMinutes: null,
    );
  }

  factory Pricing.fromJson(Map<String, dynamic> json) {
    try {
      // ✅ Vérifier si c'est le format de création (avec pricing_uuid, base_price)
      // ou le format de réponse (avec distance_km, vehicle_type, price)
      final bool isCreationFormat = json.containsKey('base_price') ||
          json.containsKey('pricing_uuid');

      if (isCreationFormat) {
        // Format classique avec pricing_uuid, base_price, etc.
        return Pricing(
          pricingUuid: json['pricing_uuid'] as String? ?? json['uuid'] as String?,
          name: json['name'] as String?,
          basePrice: _parseDouble(json['base_price']) ?? 0.0,
          expressMultiplier: _parseDouble(json['express_multiplier']),
        );
      } else {
        // ✅ Format de réponse API avec distance_km, vehicle_type, price
        final double calculatedPrice = _parseDouble(json['price']) ?? 0.0;

        return Pricing(
          pricingUuid: null,
          name: 'Tarif ${json['vehicle_type'] ?? 'standard'}',
          basePrice: calculatedPrice,
          expressMultiplier: null,
          distanceKm: _parseDouble(json['distance_km']),
          vehicleType: json['vehicle_type'] as String?,
          price: calculatedPrice,
          estimatedTimeMinutes: json['estimated_time_minutes'] as int?,
        );
      }
    } catch (e, stackTrace) {
      print('❌ [Pricing] Parse error: $e');
      print('   JSON: $json');
      print('   StackTrace: $stackTrace');
      return Pricing.empty();
    }
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      if (pricingUuid != null) 'pricing_uuid': pricingUuid,
      if (name != null) 'name': name,
      'base_price': basePrice,
      if (expressMultiplier != null) 'express_multiplier': expressMultiplier,
      if (distanceKm != null) 'distance_km': distanceKm,
      if (vehicleType != null) 'vehicle_type': vehicleType,
      if (price != null) 'price': price,
      if (estimatedTimeMinutes != null) 'estimated_time_minutes': estimatedTimeMinutes,
    };
  }

  // ✅ Méthode utilitaire pour obtenir le prix final
  double get finalPrice => price ?? basePrice;

  // ✅ Méthode pour formater le prix en FCFA
  String get formattedPrice => '${finalPrice.toStringAsFixed(0)} FCFA';

  @override
  String toString() =>
      'Pricing(name: $name, price: $finalPrice, distance: ${distanceKm ?? 'N/A'}km, vehicle: ${vehicleType ?? 'N/A'})';
}