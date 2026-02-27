// models/delivery/assignment.dart

import 'order.dart';

class Assignment {
  final String? assignmentUuid;
  final String? assignmentStatus;
  final DateTime assignedAt;
  final DateTime? acceptedAt;
  final DateTime? pickedAt;
  final DateTime? deliveredAt;
  final DateTime? completedAt;
  final Order order;

  Assignment({
    required this.assignmentUuid,
    required this.assignmentStatus,
    required this.assignedAt,
    this.acceptedAt,
    this.pickedAt,
    this.deliveredAt,
    this.completedAt,
    required this.order,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    try {
      // ✅ AJOUT : Logger le statut reçu
      final status = json['assignment_status'] as String?;
      print('📥 Assignment ${json['order']?['order_number']}: assignment_status="$status"');

      return Assignment(
        assignmentUuid: json['assignment_uuid'] as String?,
        assignmentStatus: status,
        assignedAt: json['assigned_at'] != null
            ? DateTime.parse(json['assigned_at'] as String)
            : DateTime.now(),
        acceptedAt: json['accepted_at'] != null
            ? DateTime.parse(json['accepted_at'] as String)
            : null,
        pickedAt: json['picked_at'] != null
            ? DateTime.parse(json['picked_at'] as String)
            : null,
        deliveredAt: json['delivered_at'] != null
            ? DateTime.parse(json['delivered_at'] as String)
            : null,
        completedAt: json['completed_at'] != null
            ? DateTime.parse(json['completed_at'] as String)
            : null,
        order: Order.fromJson(json['order'] as Map<String, dynamic>),
      );
    } catch (e, stackTrace) {
      print('❌ [Assignment] Parse error: $e');
      print('   JSON: $json');
      print('   StackTrace: $stackTrace');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'assignment_uuid': assignmentUuid,
      'assignment_status': assignmentStatus,
      'assigned_at': assignedAt.toIso8601String(),
      'accepted_at': acceptedAt?.toIso8601String(),
      'picked_at': pickedAt?.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'order': order.toJson(),
    };
  }

  String get statusDisplay {
    switch (assignmentStatus?.toLowerCase()) {
      case 'assigned':
        return 'Assignée';
      case 'accepted':
        return 'Acceptée';
      case 'picked':
        return 'Récupérée';
      case 'delivering':
        return 'En transit';
      case 'delivered':
        return 'Livrée';
      case 'stocked':
        return 'En stock';
      case 'completed':
        return 'Terminée';
      case 'returned':
        return 'Retournée';
      case 'cancelled':
        return 'Annulée';
      case 'failed':
        return 'Échouée';
      default:
        return assignmentStatus ?? 'Inconnu';
    }
  }

  // ✅ Getters avec logs de débogage
  bool get isAssigned {
    final status = assignmentStatus?.toLowerCase();
    return status == 'assigned';
  }

  bool get isAccepted {
    final status = assignmentStatus?.toLowerCase();
    final result = status == 'accepted';

    // ✅ AJOUT : Logger pour déboguer
    if (status == 'accepted' || result) {
      print('🔍 Assignment ${order.orderNumber}: status="$status" -> isAccepted=$result');
    }

    return result;
  }

  bool get isPicked => assignmentStatus?.toLowerCase() == 'picked';
  bool get isDelivering => assignmentStatus?.toLowerCase() == 'delivering';
  bool get isDelivered => assignmentStatus?.toLowerCase() == 'delivered';
  bool get isStocked => assignmentStatus?.toLowerCase() == 'stocked';
  bool get isReturned => assignmentStatus?.toLowerCase() == 'returned';
  bool get isCancelled => assignmentStatus?.toLowerCase() == 'cancelled';
  bool get isFailed => assignmentStatus?.toLowerCase() == 'failed';

  bool get isCompleted =>
      assignmentStatus?.toLowerCase() == 'completed' ||
          assignmentStatus?.toLowerCase() == 'delivered' ||
          assignmentStatus?.toLowerCase() == 'returned' ||
          assignmentStatus?.toLowerCase() == 'cancelled' ||
          assignmentStatus?.toLowerCase() == 'failed';

  bool get isActive =>
      isAssigned ||
          isAccepted ||
          isPicked ||
          isDelivering;

  Assignment copyWith({
    String? assignmentUuid,
    String? assignmentStatus,
    DateTime? assignedAt,
    DateTime? acceptedAt,
    DateTime? pickedAt,
    DateTime? deliveredAt,
    DateTime? completedAt,
    Order? order,
  }) {
    return Assignment(
      assignmentUuid: assignmentUuid ?? this.assignmentUuid,
      assignmentStatus: assignmentStatus ?? this.assignmentStatus,
      assignedAt: assignedAt ?? this.assignedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      pickedAt: pickedAt ?? this.pickedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
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
