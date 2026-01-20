class LocationData {
  final double lat;
  final double lng;

  LocationData({
    required this.lat,
    required this.lng,
  });

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lng': lng,
    };
  }

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
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

  @override
  String toString() => 'LocationData(lat: $lat, lng: $lng)';
}