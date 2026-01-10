class Zone {
  final String uuid;
  final String name;

  Zone({
    required this.uuid,
    required this.name,
  });

  factory Zone.fromJson(Map<String, dynamic> json) {
    return Zone(
      uuid: json['uuid'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'name': name,
    };
  }

  Zone copyWith({
    String? uuid,
    String? name,
  }) {
    return Zone(
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
    );
  }

  @override
  String toString() => 'Zone(uuid: $uuid, name: $name)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Zone && other.uuid == uuid;
  }

  @override
  int get hashCode => uuid.hashCode;
}