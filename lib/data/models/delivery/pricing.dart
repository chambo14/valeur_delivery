class Pricing {
  final String? pricingUuid;
  final String? name;
  final double basePrice;
  final double? expressMultiplier;

  Pricing({
    this.pricingUuid,
    this.name,
    this.basePrice = 0.0,
    this.expressMultiplier,
  });

  // ✅ NOUVEAU : Constructeur par défaut pour les cas où pricing est null
  factory Pricing.empty() {
    return Pricing(
      pricingUuid: 'unknown',
      name: 'Tarif standard',
      basePrice: 0.0,
      expressMultiplier: null,
    );
  }

  factory Pricing.fromJson(Map<String, dynamic> json) {
    try {
      return Pricing(
        pricingUuid: json['pricing_uuid'] as String? ?? json['uuid'] as String?,
        name: json['name'] as String?,
        basePrice: _parseDouble(json['base_price']) ?? 0.0,
        expressMultiplier: _parseDouble(json['express_multiplier']),
      );
    } catch (e, stackTrace) {
      print('❌ [Pricing] Parse error: $e');
      print('   JSON: $json');
      print('   StackTrace: $stackTrace');
      return Pricing.empty(); // ✅ Retourner pricing vide en cas d'erreur
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
      'pricing_uuid': pricingUuid,
      'name': name,
      'base_price': basePrice,
      'express_multiplier': expressMultiplier,
    };
  }

  @override
  String toString() => 'Pricing(name: $name, price: $basePrice)';
}