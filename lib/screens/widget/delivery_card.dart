// screens/widget/delivery_card.dart

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
    // ✅ CORRECTION : Gérer TOUS les statuts
    Color statusColor;
    IconData statusIcon;

    if (assignment.isAssigned) {
      statusColor = AppTheme.warning;
      statusIcon = Icons.assignment_rounded;
    } else if (assignment.isAccepted) {
      statusColor = AppTheme.info;
      statusIcon = Icons.check_circle_rounded;
    } else if (assignment.isPicked) {
      statusColor = AppTheme.warning;
      statusIcon = Icons.inventory_2_rounded;
    } else if (assignment.isStocked) {
      statusColor = AppTheme.info;
      statusIcon = Icons.warehouse_rounded;
    } else if (assignment.isDelivering) {
      statusColor = AppTheme.primaryRed;
      statusIcon = Icons.local_shipping_rounded;
    } else if (assignment.isDelivered) {
      statusColor = AppTheme.success;
      statusIcon = Icons.verified_rounded;
    } else if (assignment.isReturned) {
      statusColor = AppTheme.warning;
      statusIcon = Icons.keyboard_return_rounded;
    } else if (assignment.isCancelled) {
      statusColor = AppTheme.error;
      statusIcon = Icons.cancel_rounded;
    } else if (assignment.isFailed) {
      statusColor = AppTheme.error;
      statusIcon = Icons.error_rounded;
    } else {
      statusColor = AppTheme.textGrey;
      statusIcon = Icons.help_outline_rounded;
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
                // En-tête avec icône
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          // ✅ Icône de statut
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              statusIcon,
                              size: 16,
                              color: statusColor,
                            ),
                          ),
                          const SizedBox(width: 10),
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
                        ],
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
                            if (assignment.order.customerPhone != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                assignment.order.customerPhone!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textGrey,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ✅ Adresse selon le statut
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _getAddressColor(assignment).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getAddressIcon(assignment),
                        size: 16,
                        color: _getAddressColor(assignment),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _getDisplayAddress(assignment),
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

                // Footer - Zone et Prix
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
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
                        if (assignment.order.pricing.distanceKm != null)
                          Text(
                            '${assignment.order.pricing.distanceKm!.toStringAsFixed(1)} km',
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

                // Barcode et Prix commande
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.info.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.qr_code_rounded,
                            size: 14,
                            color: AppTheme.info,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          assignment.order.barcodeValue ?? 'Barcode',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textGrey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatPrice(assignment.order.orderAmount),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const Text(
                          'Montant',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.textGrey,
                            fontWeight: FontWeight.w500,
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

  // ✅ Helper pour l'icône d'adresse
  IconData _getAddressIcon(Assignment assignment) {
    if (assignment.isAccepted) {
      return Icons.store_rounded; // Pickup
    }
    return Icons.location_on_rounded; // Delivery
  }

  // ✅ Helper pour la couleur de l'icône
  Color _getAddressColor(Assignment assignment) {
    if (assignment.isAccepted) {
      return AppTheme.warning;
    }
    return AppTheme.info;
  }

  // ✅ Helper pour l'adresse à afficher
  String _getDisplayAddress(Assignment assignment) {
    final order = assignment.order;

    if (assignment.isAccepted) {
      return order.pickupAddress ?? 'Adresse de récupération inconnue';
    }
    return order.deliveryAddress ?? 'Adresse de livraison inconnue';
  }

  String _formatPrice(double price) {
    final priceInt = price.toInt();
    return '${NumberFormat('#,###', 'fr_FR').format(priceInt)} F';
  }
}