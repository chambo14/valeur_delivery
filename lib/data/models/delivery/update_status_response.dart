import 'assignment.dart';

class UpdateStatusResponse {
  final Assignment data;
  final String message;

  UpdateStatusResponse({
    required this.data,
    required this.message,
  });

  factory UpdateStatusResponse.fromJson(Map<String, dynamic> json) {
    try {
      return UpdateStatusResponse(
        data: Assignment.fromJson(json['data'] as Map<String, dynamic>),
        message: json['message']?.toString() ?? 'Statut mis à jour',
      );
    } catch (e, stackTrace) {
      print('❌ [UpdateStatusResponse] Parse error: $e');
      print('   JSON: $json');
      print('   StackTrace: $stackTrace');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data.toJson(),
      'message': message,
    };
  }

  @override
  String toString() => 'UpdateStatusResponse(message: $message)';
}