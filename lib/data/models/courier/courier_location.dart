class CourierLocation {
  final double lat;
  final double lng;

  CourierLocation({
    required this.lat,
    required this.lng,
  });

  factory CourierLocation.fromJson(Map<String, dynamic> json) {
    return CourierLocation(
      lat: _toDouble(json['lat']) ?? 0.0,
      lng: _toDouble(json['lng']) ?? 0.0,
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lng': lng,
    };
  }

  @override
  String toString() => 'CourierLocation(lat: $lat, lng: $lng)';
}