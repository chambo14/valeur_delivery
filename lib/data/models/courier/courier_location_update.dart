class CourierLocationUpdate {
  final double lat;
  final double lng;

  CourierLocationUpdate({
    required this.lat,
    required this.lng,
  });

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lng': lng,
    };
  }

  @override
  String toString() => 'CourierLocationUpdate(lat: $lat, lng: $lng)';
}