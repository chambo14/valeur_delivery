class Zone {
  final String? zoneUuid;
  final String? name;
  final String? description;

  Zone({
    this.zoneUuid,
    this.name,
    this.description,
  });

  // ✅ NOUVEAU : Constructeur par défaut pour les cas où zone est null
  factory Zone.empty() {
    return Zone(
      zoneUuid: 'unknown',
      name: 'Zone inconnue',
      description: '',
    );
  }

  factory Zone.fromJson(Map<String, dynamic> json) {
    try {
      return Zone(
        zoneUuid: json['zone_uuid'] as String? ?? json['uuid'] as String?,
        name: json['name'] as String?,
        description: json['description'] as String?,
      );
    } catch (e, stackTrace) {
      print('❌ [Zone] Parse error: $e');
      print('   JSON: $json');
      print('   StackTrace: $stackTrace');
      return Zone.empty(); // ✅ Retourner zone vide en cas d'erreur
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'zone_uuid': zoneUuid,
      'name': name,
      'description': description,
    };
  }

  @override
  String toString() => 'Zone(name: $name)';
}