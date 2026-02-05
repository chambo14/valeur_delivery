import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/delivery/assignment.dart';
import '../../../theme/app_theme.dart';

class DeliveryCard extends StatelessWidget {
  final Assignment assignment;
  final VoidCallback? onTap;

  const DeliveryCard({
    super.key,
    required this.assignment,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    if (assignment.isAssigned) {
      statusColor = AppTheme.warning;
    } else if (assignment.isAccepted) {
      statusColor = AppTheme.info;
    } else if (assignment.isCompleted) {
      statusColor = AppTheme.success;
    } else {
      statusColor = AppTheme.error;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        assignment.order.orderNumber ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: statusColor.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        assignment.statusDisplay,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Client
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.cardGrey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          size: 16,
                          color: AppTheme.success,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              assignment.order.customerName ?? 'Client',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              assignment.order.customerPhone ?? 'N/A',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Adresse de livraison
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.info.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        size: 16,
                        color: AppTheme.info,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        assignment.order.deliveryAddress ?? 'Adresse non disponible',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textGrey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Zone
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.warning.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.map_rounded,
                            size: 14,
                            color: AppTheme.warning,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          assignment.order.zone.name ?? 'Zone',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textGrey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    // ✅ NOUVEAU : Prix de livraison
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatPrice(assignment.order.pricing.finalPrice),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryRed,
                          ),
                        ),
                        // ✅ Distance et véhicule (si disponibles)
                        if (assignment.order.pricing.distanceKm != null)
                          Text(
                            '${assignment.order.pricing.distanceKm!.toStringAsFixed(1)} km • ${assignment.order.pricing.vehicleType ?? 'N/A'}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.textGrey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Zone
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.warning.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.work,
                            size: 14,
                            color: AppTheme.accentRed,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          assignment.order.barcodeValue ?? 'Barecode',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textGrey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    // ✅ NOUVEAU : Prix de livraison
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatPrice(assignment.order.orderAmount),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryRed,
                          ),
                        ),

                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ Helper pour formater le prix
  String _formatPrice(double price) {
    final priceInt = price.toInt();
    return '${NumberFormat('#,###', 'fr_FR').format(priceInt)} F';
  }
}
