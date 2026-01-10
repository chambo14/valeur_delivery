import '../delivery/pagination_meta.dart';
import 'notification_model.dart';

class NotificationsResponse {
  final List<NotificationModel> notifications;
  final PaginationMeta meta;

  NotificationsResponse({
    required this.notifications,
    required this.meta,
  });

  factory NotificationsResponse.fromJson(Map<String, dynamic> json) {
    return NotificationsResponse(
      notifications: (json['data'] as List)
          .map((item) => NotificationModel.fromJson(item))
          .toList(),
      meta: PaginationMeta.fromJson(json['meta']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': notifications.map((n) => n.toJson()).toList(),
      'meta': meta.toJson(),
    };
  }

  @override
  String toString() => 'NotificationsResponse(count: ${notifications.length}, page: ${meta.currentPage})';
}