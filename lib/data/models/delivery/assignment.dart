import 'order.dart';

class Assignment {
  final String assignmentUuid;
  final String assignmentStatus;
  final DateTime assignedAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;
  final Order order;

  Assignment({
    required this.assignmentUuid,
    required this.assignmentStatus,
    required this.assignedAt,
    this.acceptedAt,
    this.completedAt,
    required this.order,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      assignmentUuid: json['assignment_uuid'] as String,
      assignmentStatus: json['assignment_status'] as String,
      assignedAt: DateTime.parse(json['assigned_at'] as String),
      acceptedAt: json['accepted_at'] != null
          ? DateTime.parse(json['accepted_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      order: Order.fromJson(json['order'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'assignment_uuid': assignmentUuid,
      'assignment_status': assignmentStatus,
      'assigned_at': assignedAt.toIso8601String(),
      'accepted_at': acceptedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'order': order.toJson(),
    };
  }

  // Helpers
  String get statusDisplay {
    switch (assignmentStatus.toLowerCase()) {
      case 'assigned':
        return 'Assignée';
      case 'accepted':
        return 'Acceptée';
      case 'picked_up':
        return 'Récupérée';
      case 'in_transit':
        return 'En transit';
      case 'delivered':
        return 'Livrée';
      case 'completed':
        return 'Terminée';
      case 'failed':
        return 'Échouée';
      default:
        return assignmentStatus;
    }
  }

  bool get isAssigned => assignmentStatus.toLowerCase() == 'assigned';
  bool get isAccepted => assignmentStatus.toLowerCase() == 'accepted';
  bool get isCompleted => assignmentStatus.toLowerCase() == 'completed' ||
      assignmentStatus.toLowerCase() == 'delivered';
  bool get isFailed => assignmentStatus.toLowerCase() == 'failed';

  Assignment copyWith({
    String? assignmentUuid,
    String? assignmentStatus,
    DateTime? assignedAt,
    DateTime? acceptedAt,
    DateTime? completedAt,
    Order? order,
  }) {
    return Assignment(
      assignmentUuid: assignmentUuid ?? this.assignmentUuid,
      assignmentStatus: assignmentStatus ?? this.assignmentStatus,
      assignedAt: assignedAt ?? this.assignedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      completedAt: completedAt ?? this.completedAt,
      order: order ?? this.order,
    );
  }

  @override
  String toString() =>
      'Assignment(uuid: $assignmentUuid, status: $assignmentStatus, order: ${order.orderNumber})';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Assignment && other.assignmentUuid == assignmentUuid;
  }

  @override
  int get hashCode => assignmentUuid.hashCode;
}