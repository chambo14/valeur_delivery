import 'courier_user.dart';
import 'courier_zone.dart';

class CourierProfile {
  final String uuid;
  final CourierUser user;
  final String vehicleType;
  final int isActive;
  final String status;
  final String? currentLocation;
  final List<CourierZone> zones;
  final CourierZone? primaryZone;
  final DateTime createdAt;
  final DateTime updatedAt;

  CourierProfile({
    required this.uuid,
    required this.user,
    required this.vehicleType,
    required this.isActive,
    required this.status,
    this.currentLocation,
    required this.zones,
    this.primaryZone,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CourierProfile.fromJson(Map<String, dynamic> json) {
    return CourierProfile(
      uuid: json['uuid'] as String,
      user: CourierUser.fromJson(json['user'] as Map<String, dynamic>),
      vehicleType: json['vehicle_type'] as String,
      isActive: json['is_active'] as int,
      status: json['status'] as String,
      currentLocation: json['current_location'] as String?,
      zones: (json['zones'] as List<dynamic>)
          .map((zone) => CourierZone.fromJson(zone as Map<String, dynamic>))
          .toList(),
      primaryZone: json['primary_zone'] != null
          ? CourierZone.fromJson(json['primary_zone'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'user': user.toJson(),
      'vehicle_type': vehicleType,
      'is_active': isActive,
      'status': status,
      'current_location': currentLocation,
      'zones': zones.map((zone) => zone.toJson()).toList(),
      'primary_zone': primaryZone?.toJson(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helpers
  bool get isActiveUser => isActive == 1;

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

  String get statusDisplay {
    switch (status.toLowerCase()) {
      case 'available':
        return 'Disponible';
      case 'busy':
        return 'Occupé';
      case 'offline':
        return 'Hors ligne';
      default:
        return status;
    }
  }

  String get zonesDisplay {
    if (zones.isEmpty) return 'Aucune zone';
    return zones.map((z) => z.name).join(', ');
  }

  CourierProfile copyWith({
    String? uuid,
    CourierUser? user,
    String? vehicleType,
    int? isActive,
    String? status,
    String? currentLocation,
    List<CourierZone>? zones,
    CourierZone? primaryZone,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CourierProfile(
      uuid: uuid ?? this.uuid,
      user: user ?? this.user,
      vehicleType: vehicleType ?? this.vehicleType,
      isActive: isActive ?? this.isActive,
      status: status ?? this.status,
      currentLocation: currentLocation ?? this.currentLocation,
      zones: zones ?? this.zones,
      primaryZone: primaryZone ?? this.primaryZone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'CourierProfile(uuid: $uuid, user: ${user.name}, status: $status)';
}