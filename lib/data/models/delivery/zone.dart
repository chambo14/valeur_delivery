// models/zone.dart

class Zone {
  final String? uuid;
  final String? name;
  final String? description;
  final bool isActive;

  Zone({
    this.uuid,
    this.name,
    this.description,
    this.isActive = true,
  });

  factory Zone.fromJson(Map<String, dynamic> json) {
    return Zone(
      uuid: json['uuid'] as String?,
      name: json['name'] as String?,
      description: json['description'] as String?,
      isActive: json['is_active'] == true ||
          json['is_active'] == 1 ||
          json['is_active'] == '1' ||
          json['is_active'] == null,
    );
  }

  factory Zone.empty() {
    return Zone(
      uuid: null,
      name: 'Non définie',
      description: null,
      isActive: false,
    );
  }

  Map<String, dynamic> toJson() => {
    'uuid': uuid,
    'name': name,
    'description': description,
    'is_active': isActive,
  };

  Zone copyWith({
    String? uuid,
    String? name,
    String? description,
    bool? isActive,
  }) {
    return Zone(
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }

  bool get isEmpty => uuid == null && name == 'Non définie';
  bool get isNotEmpty => !isEmpty;

  String get displayName => name ?? 'Zone inconnue';

  @override
  String toString() => 'Zone(name: $name)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Zone && other.uuid == uuid;
  }

  @override
  int get hashCode => uuid.hashCode;
}