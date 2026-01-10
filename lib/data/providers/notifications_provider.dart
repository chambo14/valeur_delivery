import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../network/config/token_service.dart';
import '../../network/config/app_logger.dart';

import '../models/delivery/pagination_meta.dart';
import '../models/notifications/notification_model.dart';
import 'api_provider.dart';

// State
class NotificationsState {
  final bool isLoading;
  final List<NotificationModel> notifications;
  final PaginationMeta? meta;
  final String? errorMessage;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool isMarkingAsRead;

  NotificationsState({
    this.isLoading = false,
    this.notifications = const [],
    this.meta,
    this.errorMessage,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.isMarkingAsRead = false,
  });

  NotificationsState copyWith({
    bool? isLoading,
    List<NotificationModel>? notifications,
    PaginationMeta? meta,
    String? errorMessage,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? isMarkingAsRead,
  }) {
    return NotificationsState(
      isLoading: isLoading ?? this.isLoading,
      notifications: notifications ?? this.notifications,
      meta: meta ?? this.meta,
      errorMessage: errorMessage,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isMarkingAsRead: isMarkingAsRead ?? this.isMarkingAsRead,
    );
  }

  // Helpers
  bool get hasData => notifications.isNotEmpty;
  bool get hasError => errorMessage != null;
  int get unreadCount => notifications.where((n) => !n.isRead).length;
  List<NotificationModel> get unreadNotifications =>
      notifications.where((n) => !n.isRead).toList();
  List<NotificationModel> get readNotifications =>
      notifications.where((n) => n.isRead).toList();
}

// Notifier
class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final Ref ref;

  NotificationsNotifier(this.ref) : super(NotificationsState());

  /// Charger les notifications
  Future<void> loadNotifications({int page = 1}) async {
    if (page == 1) {
      state = state.copyWith(isLoading: true, errorMessage: null);
    } else {
      state = state.copyWith(isLoadingMore: true, errorMessage: null);
    }

    try {
      // ✅ Utilisation SYNCHRONE (plus rapide et fiable)
      final userUuid = TokenService.getUserUuidSync();

      AppLogger.debug('🔑 [NotificationsNotifier] User UUID: $userUuid');

      if (userUuid == null || userUuid.isEmpty) {
        AppLogger.error('❌ [NotificationsNotifier] UUID null ou vide');
        state = state.copyWith(
          isLoading: false,
          isLoadingMore: false,
          errorMessage: 'Session expirée - Veuillez vous reconnecter',
        );
        return;
      }

      final notificationService = ref.read(notificationServiceProvider);
      final result = await notificationService.getNotifications(
        userUuid: userUuid,
      );

      result.fold(
            (error) {
          AppLogger.error('❌ [NotificationsNotifier] Erreur: $error');
          state = state.copyWith(
            isLoading: false,
            isLoadingMore: false,
            errorMessage: error,
          );
        },
            (response) {
          if (page == 1) {
            state = state.copyWith(
              isLoading: false,
              notifications: response.notifications,
              meta: response.meta,
              errorMessage: null,
            );
          } else {
            state = state.copyWith(
              isLoadingMore: false,
              notifications: [...state.notifications, ...response.notifications],
              meta: response.meta,
              errorMessage: null,
            );
          }
        },
      );
    } catch (e) {
      AppLogger.error('❌ [NotificationsNotifier] Erreur chargement', e);
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        errorMessage: 'Erreur lors du chargement',
      );
    }
  }

  /// Rafraîchir les notifications
  Future<void> refreshNotifications() async {
    state = state.copyWith(isRefreshing: true);
    await loadNotifications(page: 1);
    state = state.copyWith(isRefreshing: false);
  }

  /// Charger plus de notifications
  Future<void> loadMoreNotifications() async {
    if (state.meta == null || state.isLoadingMore) return;

    final currentPage = state.meta!.currentPage;
     final lastPage = state.meta!.lastPage;

    if (currentPage < lastPage) {
      await loadNotifications(page: currentPage + 1);
    }
  }

  /// Marquer une notification comme lue
  Future<void> markAsRead(String notificationUuid) async {
    state = state.copyWith(isMarkingAsRead: true);

    try {
      final notificationService = ref.read(notificationServiceProvider);
      final result = await notificationService.markAsRead(notificationUuid);

      result.fold(
            (error) {
          state = state.copyWith(
            isMarkingAsRead: false,
            errorMessage: error,
          );
        },
            (updatedNotification) {
          // Mettre à jour localement
          final updatedList = state.notifications.map((n) {
            if (n.uuid == notificationUuid) {
              return n.copyWith(isRead: true);
            }
            return n;
          }).toList();

          state = state.copyWith(
            isMarkingAsRead: false,
            notifications: updatedList,
            errorMessage: null,
          );
        },
      );
    } catch (e) {
      AppLogger.error('❌ [NotificationsNotifier] Erreur marquage lecture', e);
      state = state.copyWith(
        isMarkingAsRead: false,
        errorMessage: 'Erreur lors du marquage',
      );
    }
  }

  /// Marquer toutes les notifications comme lues
  Future<void> markAllAsRead() async {
    state = state.copyWith(isMarkingAsRead: true);

    try {
      final userUuid = TokenService.getUserUuid();
      if (userUuid == null) return;

      final notificationService = ref.read(notificationServiceProvider);
      final result = await notificationService.markAllAsRead(userUuid.toString());

      result.fold(
            (error) {
          state = state.copyWith(
            isMarkingAsRead: false,
            errorMessage: error,
          );
        },
            (_) {
          // Marquer toutes localement
          final updatedList = state.notifications
              .map((n) => n.copyWith(isRead: true))
              .toList();

          state = state.copyWith(
            isMarkingAsRead: false,
            notifications: updatedList,
            errorMessage: null,
          );
        },
      );
    } catch (e) {
      AppLogger.error('❌ [NotificationsNotifier] Erreur marquage tout', e);
      state = state.copyWith(
        isMarkingAsRead: false,
        errorMessage: 'Erreur lors du marquage',
      );
    }
  }

  /// Supprimer une notification
  Future<void> deleteNotification(String notificationUuid) async {
    try {
      final notificationService = ref.read(notificationServiceProvider);
      final result = await notificationService.deleteNotification(notificationUuid);

      result.fold(
            (error) {
          state = state.copyWith(errorMessage: error);
        },
            (_) {
          // Retirer localement
          final updatedList = state.notifications
              .where((n) => n.uuid != notificationUuid)
              .toList();

          state = state.copyWith(
            notifications: updatedList,
            errorMessage: null,
          );
        },
      );
    } catch (e) {
      AppLogger.error('❌ [NotificationsNotifier] Erreur suppression', e);
      state = state.copyWith(
        errorMessage: 'Erreur lors de la suppression',
      );
    }
  }

  /// Réinitialiser l'état
  void reset() {
    state = NotificationsState();
  }
}

// Providers
final notificationsProvider = StateNotifierProvider<NotificationsNotifier, NotificationsState>(
      (ref) => NotificationsNotifier(ref),
);

// Helpers
final unreadCountProvider = Provider<int>((ref) {
  final state = ref.watch(notificationsProvider);
  return state.unreadCount;
});

final hasUnreadNotificationsProvider = Provider<bool>((ref) {
  final count = ref.watch(unreadCountProvider);
  return count > 0;
});