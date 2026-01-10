class Role {
  final String uuid;
  final String name;
  final String displayName;
  final int isSuperAdmin;

  Role({
    required this.uuid,
    required this.name,
    required this.displayName,
    required this.isSuperAdmin,
  });

  // Créer depuis JSON
  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      uuid: json['uuid'] as String,
      name: json['name'] as String,
      displayName: json['display_name'] as String,
      isSuperAdmin: json['is_super_admin'] as int,
    );
  }

  // Convertir en JSON
  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'name': name,
      'display_name': displayName,
      'is_super_admin': isSuperAdmin,
    };
  }

  // Helper pour vérifier le rôle
  bool get isCourier => name == 'courier';
  bool get isAdmin => isSuperAdmin == 1;

  // CopyWith
  Role copyWith({
    String? uuid,
    String? name,
    String? displayName,
    int? isSuperAdmin,
  }) {
    return Role(
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      isSuperAdmin: isSuperAdmin ?? this.isSuperAdmin,
    );
  }

  @override
  String toString() {
    return 'Role(uuid: $uuid, name: $name, displayName: $displayName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Role && other.uuid == uuid;
  }

  @override
  int get hashCode => uuid.hashCode;
}