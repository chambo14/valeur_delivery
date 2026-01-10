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
      uuid: json['uuid'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
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

  CourierUser copyWith({
    String? uuid,
    String? name,
    String? email,
    String? phone,
  }) {
    return CourierUser(
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
    );
  }

  @override
  String toString() => 'CourierUser(uuid: $uuid, name: $name)';
}