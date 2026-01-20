import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/delivery/assignment.dart';
import '../../data/providers/today_orders_provider.dart';
import '../../theme/app_theme.dart';

class NewOrderNotification extends ConsumerWidget {
  final Assignment order;
  final VoidCallback onDismiss;

  const NewOrderNotification({
    super.key,
    required this.order,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: order.order.isExpress
              ? const LinearGradient(
            colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
          )
              : const LinearGradient(
            colors: [AppTheme.primaryRed, AppTheme.accentRed],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryRed.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header avec animation
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Icône animée
                  TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 600),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            order.order.isExpress
                                ? Icons.bolt_rounded
                                : Icons.local_shipping_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              order.order.isExpress ? '⚡ COURSE EXPRESS' : '📦 NOUVELLE COURSE',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.order.orderNumber.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onDismiss,
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Infos client
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_rounded,
                          size: 20, color: AppTheme.textGrey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          order.order.customerName.toString(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_rounded,
                          size: 20, color: AppTheme.primaryRed),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          order.order.deliveryAddress.toString(),
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textGrey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            onDismiss();
                            await ref
                                .read(todayOrdersProvider.notifier)
                                .rejectOrder(order.order.uuid.toString());
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.error,
                            side: const BorderSide(color: AppTheme.error),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Refuser',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () async {
                            onDismiss();
                            await ref
                                .read(todayOrdersProvider.notifier)
                                .acceptOrder(order.order.uuid.toString());
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.success,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Accepter',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Afficher la notification
void showNewOrderNotification(
    BuildContext context,
    Assignment order,
    ) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => NewOrderNotification(
      order: order,
      onDismiss: () => Navigator.of(context).pop(),
    ),
  );
}