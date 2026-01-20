class CourierLocationResponse {
  final CourierData data;
  final String message;

  CourierLocationResponse({
    required this.data,
    required this.message,
  });

  factory CourierLocationResponse.fromJson(Map<String, dynamic> json) {
    try {
      return CourierLocationResponse(
        data: CourierData.fromJson(json['data'] as Map<String, dynamic>),
        message: json['message']?.toString() ?? 'Position mise à jour',
      );
    } catch (e, stackTrace) {
      print('❌ [CourierLocationResponse] Parse error: $e');
      print('   JSON: $json');
      print('   StackTrace: $stackTrace');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data.toJson(),
      'message': message,
    };
  }
}

class CourierData {
  final String uuid;
  final String userUuid;
  final String vehicleType;
  final bool isActive;
  final String status;
  final CurrentLocation? currentLocation;
  final CourierUser user;
  final DateTime createdAt;
  final DateTime updatedAt;

  CourierData({
    required this.uuid,
    required this.userUuid,
    required this.vehicleType,
    required this.isActive,
    required this.status,
    this.currentLocation,
    required this.user,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CourierData.fromJson(Map<String, dynamic> json) {
    return CourierData(
      uuid: json['uuid'] as String? ?? json['id'] as String? ?? '',
      userUuid: json['user_uuid'] as String? ?? '',
      vehicleType: json['vehicle_type'] as String? ?? 'moto',
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      status: json['status'] as String? ?? 'available',
      currentLocation: json['current_location'] != null
          ? CurrentLocation.fromJson(json['current_location'] as Map<String, dynamic>)
          : null,
      user: CourierUser.fromJson(json['user'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'user_uuid': userUuid,
      'vehicle_type': vehicleType,
      'is_active': isActive ? 1 : 0,
      'status': status,
      'current_location': currentLocation?.toJson(),
      'user': user.toJson(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class CurrentLocation {
  final double lat;
  final double lng;

  CurrentLocation({
    required this.lat,
    required this.lng,
  });

  factory CurrentLocation.fromJson(Map<String, dynamic> json) {
    return CurrentLocation(
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
  String toString() => 'CurrentLocation(lat: $lat, lng: $lng)';
}

class CourierUser {
  final String uuid;
  final String name;
  final String email;
  final String phone;

  CourierUser({
    required this.uuid,
    required this.name,
    required this.email,
    required this.phone,
  });

  factory CourierUser.fromJson(Map<String, dynamic> json) {
    return CourierUser(
      uuid: json['uuid'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'name': name,
      'email': email,
      'phone': phone,
    };
  }
}