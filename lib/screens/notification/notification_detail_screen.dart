import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/notifications/notification_model.dart';
import '../../data/providers/notifications_provider.dart';
import '../../theme/app_theme.dart';

class NotificationDetailScreen extends ConsumerWidget {
  final NotificationModel notification;

  const NotificationDetailScreen({
    super.key,
    required this.notification,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.cardLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Supprimer
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error),
            onPressed: () => _showDeleteDialog(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec icône et badge
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.cardLight,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Icône de type
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _getNotificationColor(notification.type).withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _getNotificationColor(notification.type).withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      _getNotificationIcon(notification.type),
                      color: _getNotificationColor(notification.type),
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Badge de type
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getNotificationColor(notification.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getNotificationColor(notification.type).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      notification.typeDisplay,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _getNotificationColor(notification.type),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Contenu principal
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardLight,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                            height: 1.3,
                          ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 10,
                          height: 10,
                          margin: const EdgeInsets.only(top: 6, left: 8),
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryRed,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Date et heure
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 16,
                        color: AppTheme.textGrey.withOpacity(0.7),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatDateTime(notification.createdAt),
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.textGrey.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.schedule_rounded,
                        size: 16,
                        color: AppTheme.textGrey.withOpacity(0.7),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        notification.formattedDate,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.textGrey.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Divider
                  Container(
                    height: 1,
                    color: AppTheme.textGrey.withOpacity(0.1),
                  ),
                  const SizedBox(height: 20),

                  // Message
                  Text(
                    notification.message,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppTheme.textDark,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),

            // Informations supplémentaires
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.info.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.info.withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  _buildInfoRow(
                    'Statut',
                    notification.isRead ? 'Lue' : 'Non lue',
                    notification.isRead ? AppTheme.success : AppTheme.warning,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    'État d\'envoi',
                    _getStatusDisplay(notification.status),
                    _getStatusColor(notification.status),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    'Reçue le',
                    DateFormat('dd MMMM yyyy à HH:mm', 'fr_FR')
                        .format(notification.createdAt),
                    AppTheme.textGrey,
                  ),
                  if (notification.updatedAt != notification.createdAt) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      'Dernière mise à jour',
                      DateFormat('dd MMMM yyyy à HH:mm', 'fr_FR')
                          .format(notification.updatedAt),
                      AppTheme.textGrey,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Marquer comme lu/non lu
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _toggleReadStatus(context, ref),
                      icon: Icon(
                        notification.isRead
                            ? Icons.mark_email_unread_rounded
                            : Icons.mark_email_read_rounded,
                      ),
                      label: Text(
                        notification.isRead
                            ? 'Marquer comme non lue'
                            : 'Marquer comme lue',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.info,
                        side: const BorderSide(color: AppTheme.info),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Supprimer
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showDeleteDialog(context, ref),
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('Supprimer'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.error,
                        side: const BorderSide(color: AppTheme.error),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textGrey,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Color _getNotificationColor(String type) {
    switch (type.toLowerCase()) {
      case 'system':
        return AppTheme.info;
      case 'order':
        return AppTheme.warning;
      case 'delivery':
        return AppTheme.success;
      case 'account':
        return AppTheme.primaryRed;
      default:
        return AppTheme.textGrey;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'system':
        return Icons.info_rounded;
      case 'order':
        return Icons.shopping_bag_rounded;
      case 'delivery':
        return Icons.local_shipping_rounded;
      case 'account':
        return Icons.person_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  String _getStatusDisplay(String status) {
    switch (status.toLowerCase()) {
      case 'sent':
        return 'Envoyée';
      case 'delivered':
        return 'Délivrée';
      case 'failed':
        return 'Échec';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'sent':
        return AppTheme.info;
      case 'delivered':
        return AppTheme.success;
      case 'failed':
        return AppTheme.error;
      default:
        return AppTheme.textGrey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('EEEE dd MMMM yyyy • HH:mm', 'fr_FR').format(dateTime);
  }

  void _toggleReadStatus(BuildContext context, WidgetRef ref) async {
    if (!notification.isRead) {
      // Marquer comme lue
      await ref.read(notificationsProvider.notifier).markAsRead(notification.uuid);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 12),
                Text('Notification marquée comme lue'),
              ],
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      // Pour marquer comme non lue, il faudrait une API dédiée
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fonctionnalité non disponible'),
          backgroundColor: AppTheme.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: AppTheme.error),
            SizedBox(width: 12),
            Text('Supprimer la notification', style: TextStyle(fontSize: 16),),
          ],
        ),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer cette notification ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Annuler',
              style: TextStyle(color: AppTheme.textGrey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Fermer le dialog

              await ref.read(notificationsProvider.notifier)
                  .deleteNotification(notification.uuid);

              if (context.mounted) {
                Navigator.pop(context); // Retour à la liste

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: Colors.white),
                        SizedBox(width: 12),
                        Text('Notification supprimée'),
                      ],
                    ),
                    backgroundColor: AppTheme.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}