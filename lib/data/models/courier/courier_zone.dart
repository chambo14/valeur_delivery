class CourierZone {
  final String uuid;
  final String name;
  final int isPrimary;

  CourierZone({
    required this.uuid,
    required this.name,
    required this.isPrimary,
  });

  factory CourierZone.fromJson(Map<String, dynamic> json) {
    try {
      return CourierZone(
        uuid: json['uuid']?.toString() ?? '',
        name: json['name']?.toString() ?? 'Zone inconnue',
        isPrimary: _parseIsPrimary(json['is_primary']),
      );
    } catch (e, stackTrace) {
      print('❌ [CourierZone] Parse error: $e');
      print('   JSON: $json');
      print('   StackTrace: $stackTrace');

      // ✅ Retourner un objet par défaut plutôt que de planter
      return CourierZone(
        uuid: json['uuid']?.toString() ?? 'unknown',
        name: 'Zone inconnue',
        isPrimary: 0,
      );
    }
  }

  // ✅ HELPER : Parser isPrimary de manière robuste
  static int _parseIsPrimary(dynamic value) {
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

    // Par défaut, non primaire
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'name': name,
      'is_primary': isPrimary,
    };
  }

  // ✅ Helper pour vérifier si c'est une zone primaire
  bool get isPrimaryZone => isPrimary == 1;

  // ✅ Helper pour vérifier si les données sont valides
  bool get isValid => uuid.isNotEmpty && name.isNotEmpty;

  // ✅ Helper pour obtenir un badge de couleur selon le type
  String get displayBadge => isPrimaryZone ? '⭐ Zone principale' : 'Zone secondaire';

  // ✅ Helper pour obtenir les initiales de la zone
  String get initials {
    if (name.isEmpty) return 'Z';

    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  CourierZone copyWith({
    String? uuid,
    String? name,
    int? isPrimary,
  }) {
    return CourierZone(
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }

  @override
  String toString() => 'CourierZone(uuid: $uuid, name: $name, isPrimary: $isPrimaryZone)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CourierZone && other.uuid == uuid;
  }

  @override
  int get hashCode => uuid.hashCode;
}