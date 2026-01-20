import 'dart:math';

class Location {
  final double? latitude;
  final double? longitude;

  Location({
    required this.latitude,
    required this.longitude,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    try {
      return Location(
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
      );
    } catch (e, stackTrace) {
      print('❌ [Location] Parse error: $e');
      print('   JSON: $json');
      print('   StackTrace: $stackTrace');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
  };

  /// Vérifie si les coordonnées sont valides
  bool get isValid => latitude != null && longitude != null;

  /// Obtient la coordonnée sous forme de string
  String get coordinatesString {
    if (!isValid) return 'Coordonnées indisponibles';
    return '$latitude, $longitude';
  }

  /// Calcule la distance entre deux locations (approximative en km)
  /// Utilise la formule de Haversine
  double distanceTo(Location other) {
    if (!isValid || !other.isValid) return 0.0;

    const R = 6371; // Rayon de la Terre en km
    final lat1Rad = _degreesToRadians(latitude ?? 0);
    final lat2Rad = _degreesToRadians(other.latitude ?? 0);
    final deltaLat = _degreesToRadians((other.latitude ?? 0) - (latitude ?? 0));
    final deltaLon = _degreesToRadians((other.longitude ?? 0) - (longitude ?? 0));

    final a = (sin(deltaLat / 2) * sin(deltaLat / 2)) +
        cos(lat1Rad) *
            cos(lat2Rad) *
            sin(deltaLon / 2) *
            sin(deltaLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * 3.141592653589793 / 180.0;
  }

  /// Crée une copie avec les champs modifiés
  Location copyWith({
    double? latitude,
    double? longitude,
  }) {
    return Location(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  @override
  String toString() => 'Location($latitude, $longitude)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Location &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;
}