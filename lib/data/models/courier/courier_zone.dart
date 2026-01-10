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
    return CourierZone(
      uuid: json['uuid'] as String,
      name: json['name'] as String,
      isPrimary: json['is_primary'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'name': name,
      'is_primary': isPrimary,
    };
  }

  bool get isPrimaryZone => isPrimary == 1;

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
}