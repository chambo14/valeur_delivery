import 'assignment.dart';

class AssignmentDetailResponse {
  final Assignment data;

  AssignmentDetailResponse({
    required this.data,
  });

  factory AssignmentDetailResponse.fromJson(Map<String, dynamic> json) {
    return AssignmentDetailResponse(
      data: Assignment.fromJson(json['data'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data.toJson(),
    };
  }

  AssignmentDetailResponse copyWith({
    Assignment? data,
  }) {
    return AssignmentDetailResponse(
      data: data ?? this.data,
    );
  }

  @override
  String toString() => 'AssignmentDetailResponse(assignment: ${data.assignmentUuid})';
}