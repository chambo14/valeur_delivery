import 'courier_profile.dart';

class CourierProfileResponse {
  final CourierProfile data;

  CourierProfileResponse({
    required this.data,
  });

  factory CourierProfileResponse.fromJson(Map<String, dynamic> json) {
    return CourierProfileResponse(
      data: CourierProfile.fromJson(json['data'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data.toJson(),
    };
  }

  CourierProfileResponse copyWith({
    CourierProfile? data,
  }) {
    return CourierProfileResponse(
      data: data ?? this.data,
    );
  }

  @override
  String toString() => 'CourierProfileResponse(profile: ${data.user.name})';
}