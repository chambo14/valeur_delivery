class LoginRequest {
  final String identifier; // Numéro de téléphone ou email
  final String password;

  LoginRequest({
    required this.identifier,
    required this.password,
  });

  // Convertir en JSON pour l'envoi à l'API
  Map<String, dynamic> toJson() {
    return {
      'identifier': identifier,
      'password': password,
    };
  }

  // Créer depuis un JSON (utile pour les tests)
  factory LoginRequest.fromJson(Map<String, dynamic> json) {
    return LoginRequest(
      identifier: json['identifier'] as String,
      password: json['password'] as String,
    );
  }

  // CopyWith pour modifier une instance
  LoginRequest copyWith({
    String? identifier,
    String? password,
  }) {
    return LoginRequest(
      identifier: identifier ?? this.identifier,
      password: password ?? this.password,
    );
  }

  @override
  String toString() {
    return 'LoginRequest(identifier: $identifier)'; // Ne pas afficher le password !
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LoginRequest &&
        other.identifier == identifier &&
        other.password == password;
  }

  @override
  int get hashCode => identifier.hashCode ^ password.hashCode;
}