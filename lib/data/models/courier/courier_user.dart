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
    try {
      return CourierUser(
        uuid: json['uuid']?.toString() ?? '',
        name: json['name']?.toString() ?? 'Utilisateur',
        email: json['email']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
      );
    } catch (e, stackTrace) {
      print('❌ [CourierUser] Parse error: $e');
      print('   JSON: $json');
      print('   StackTrace: $stackTrace');

      // ✅ Retourner un objet par défaut plutôt que de planter
      return CourierUser(
        uuid: json['uuid']?.toString() ?? 'unknown',
        name: 'Utilisateur',
        email: '',
        phone: '',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'name': name,
      'email': email,
      'phone': phone,
    };
  }

  // ✅ Helper pour vérifier si les données sont valides
  bool get isValid {
    return uuid.isNotEmpty &&
        name.isNotEmpty &&
        email.isNotEmpty &&
        phone.isNotEmpty;
  }

  // ✅ Helper pour obtenir les initiales
  String get initials {
    if (name.isEmpty) return 'U';

    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  // ✅ Helper pour formater le numéro de téléphone
  String get formattedPhone {
    if (phone.isEmpty) return 'Non renseigné';

    // Si le numéro commence par +225 (Côte d'Ivoire)
    if (phone.startsWith('+225')) {
      final number = phone.substring(4).trim();
      if (number.length == 10) {
        return '+225 ${number.substring(0, 2)} ${number.substring(2, 4)} ${number.substring(4, 6)} ${number.substring(6, 8)} ${number.substring(8)}';
      }
    }

    // Sinon retourner le numéro tel quel
    return phone;
  }

  // ✅ CopyWith pour immutabilité
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
  String toString() => 'CourierUser(uuid: $uuid, name: $name, email: $email)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CourierUser && other.uuid == uuid;
  }

  @override
  int get hashCode => uuid.hashCode;
}