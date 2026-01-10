import 'package:intl/intl.dart';

class NotificationModel {
  final String uuid;
  final String userUuid;
  final String title;
  final String message;
  final String type; // system, order, delivery, etc.
  final String status; // sent, delivered, failed
  final bool isRead;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationModel({
    required this.uuid,
    required this.userUuid,
    required this.title,
    required this.message,
    required this.type,
    required this.status,
    required this.isRead,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      uuid: json['uuid'] as String,
      userUuid: json['user_uuid'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      type: json['type'] as String,
      status: json['status'] as String,
      isRead: json['is_read'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'user_uuid': userUuid,
      'title': title,
      'message': message,
      'type': type,
      'status': status,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Copier avec modifications
  NotificationModel copyWith({
    String? uuid,
    String? userUuid,
    String? title,
    String? message,
    String? type,
    String? status,
    bool? isRead,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationModel(
      uuid: uuid ?? this.uuid,
      userUuid: userUuid ?? this.userUuid,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      status: status ?? this.status,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helpers
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays}j';
    } else {
      return DateFormat('dd/MM/yyyy').format(createdAt);
    }
  }

  String get typeDisplay {
    switch (type.toLowerCase()) {
      case 'system':
        return 'Système';
      case 'order':
        return 'Commande';
      case 'delivery':
        return 'Livraison';
      case 'account':
        return 'Compte';
      default:
        return type;
    }
  }

  @override
  String toString() => 'NotificationModel(uuid: $uuid, title: $title, isRead: $isRead)';
}