import 'user.dart';

class LoginResponse {
  final String token;
  final User user;

  LoginResponse({
    required this.token,
    required this.user,
  });

  // Créer depuis JSON
  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  // Convertir en JSON
  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'user': user.toJson(),
    };
  }

  // Helper pour extraire le token ID (ex: "13" de "13|BWfkf...")
  String get tokenId {
    if (token.contains('|')) {
      return token.split('|').first;
    }
    return '';
  }

  // Helper pour extraire le token brut (ex: "BWfkf..." de "13|BWfkf...")
  String get tokenValue {
    if (token.contains('|')) {
      return token.split('|').last;
    }
    return token;
  }

  // CopyWith
  LoginResponse copyWith({
    String? token,
    User? user,
  }) {
    return LoginResponse(
      token: token ?? this.token,
      user: user ?? this.user,
    );
  }

  @override
  String toString() {
    return 'LoginResponse(token: ${token.substring(0, 10)}..., user: ${user.name})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LoginResponse &&
        other.token == token &&
        other.user == user;
  }

  @override
  int get hashCode => token.hashCode ^ user.hashCode;
}