import 'role.dart';

class User {
  final String uuid;
  final String name;
  final String email;
  final String phone;
  final int isActive;
  final List<Role> roles;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.uuid,
    required this.name,
    required this.email,
    required this.phone,
    required this.isActive,
    required this.roles,
    required this.createdAt,
    required this.updatedAt,
  });

  // Créer depuis JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uuid: json['uuid'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      isActive: json['is_active'] as int,
      roles: (json['roles'] as List<dynamic>)
          .map((role) => Role.fromJson(role as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  // Convertir en JSON
  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'name': name,
      'email': email,
      'phone': phone,
      'is_active': isActive,
      'roles': roles.map((role) => role.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helpers
  bool get isActiveUser => isActive == 1;
  Role? get primaryRole => roles.isNotEmpty ? roles.first : null;
  bool get isCourier => roles.any((role) => role.isCourier);

  String get firstName {
    final parts = name.split(' ');
    return parts.isNotEmpty ? parts.first : name;
  }

  String get lastName {
    final parts = name.split(' ');
    return parts.length > 1 ? parts.sublist(1).join(' ') : '';
  }

  // CopyWith
  User copyWith({
    String? uuid,
    String? name,
    String? email,
    String? phone,
    int? isActive,
    List<Role>? roles,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      isActive: isActive ?? this.isActive,
      roles: roles ?? this.roles,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'User(uuid: $uuid, name: $name, email: $email, phone: $phone)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.uuid == uuid;
  }

  @override
  int get hashCode => uuid.hashCode;
}
