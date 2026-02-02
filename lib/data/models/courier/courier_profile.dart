import 'courier_location.dart';
import 'courier_user.dart';
import 'courier_zone.dart';

class CourierProfile {
  final String uuid;
  final CourierUser user;
  final String vehicleType;
  final int isActive;
  final String status;
  final CourierLocation? currentLocation;
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
    try {
      return CourierProfile(
        uuid: json['uuid']?.toString() ?? '',
        user: CourierUser.fromJson(json['user'] as Map<String, dynamic>),
        vehicleType: json['vehicle_type']?.toString() ?? 'moto',
        // ✅ CORRECTION : Gérer le cas où isActive peut être null, String, bool ou int
        isActive: _parseIsActive(json['is_active']),
        status: json['status']?.toString() ?? 'offline',
        currentLocation: json['current_location'] != null
            ? CourierLocation.fromJson(
            json['current_location'] as Map<String, dynamic>)
            : null,
        zones: json['zones'] != null
            ? (json['zones'] as List<dynamic>)
            .map((zone) => CourierZone.fromJson(zone as Map<String, dynamic>))
            .toList()
            : [],
        primaryZone: json['primary_zone'] != null
            ? CourierZone.fromJson(
            json['primary_zone'] as Map<String, dynamic>)
            : null,
        // ✅ CORRECTION : Gérer les dates qui peuvent être null ou mal formatées
        createdAt: _parseDateTime(json['created_at']) ?? DateTime.now(),
        updatedAt: _parseDateTime(json['updated_at']) ?? DateTime.now(),
      );
    } catch (e, stackTrace) {
      print('❌ [CourierProfile] Parse error: $e');
      print('   JSON: $json');
      print('   StackTrace: $stackTrace');
      rethrow;
    }
  }

  // ✅ HELPER : Parser isActive de manière robuste
  static int _parseIsActive(dynamic value) {
    if (value == null) return 0;

    // Si c'est déjà un int
    if (value is int) return value;

    // Si c'est un bool
    if (value is bool) return value ? 1 : 0;

    // Si c'est un String
    if (value is String) {
      // Gérer "true"/"false"
      if (value.toLowerCase() == 'true') return 1;
      if (value.toLowerCase() == 'false') return 0;

      // Essayer de parser en int
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }

    // Par défaut, inactif
    return 0;
  }

  // ✅ HELPER : Parser les dates de manière robuste
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;

    if (value is DateTime) return value;

    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        print('⚠️ Impossible de parser la date: $value');
        return null;
      }
    }

    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'user': user.toJson(),
      'vehicle_type': vehicleType,
      'is_active': isActive,
      'status': status,
      'current_location': currentLocation?.toJson(),
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
      case 'vélo':
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

  String get locationDisplay {
    if (currentLocation == null) return 'Position non disponible';
    return '${currentLocation!.lat.toStringAsFixed(6)}, ${currentLocation!.lng.toStringAsFixed(6)}';
  }

  CourierProfile copyWith({
    String? uuid,
    CourierUser? user,
    String? vehicleType,
    int? isActive,
    String? status,
    CourierLocation? currentLocation,
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
  String toString() =>
      'CourierProfile(uuid: $uuid, user: ${user.name}, status: $status)';
}