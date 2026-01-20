import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/providers/deliveries_provider.dart';
import '../../data/providers/delivery_detail_provider.dart';
import '../../data/services/call_service.dart';
import '../../data/services/locations_service.dart';
import '../../theme/app_theme.dart';
import '../navigation/navigation_screen.dart';
import '../widget/status_update_dialog.dart';

class DeliveryDetailScreen extends ConsumerStatefulWidget {
  final String orderUuid;

  const DeliveryDetailScreen({
    super.key,
    required this.orderUuid,
  });

  @override
  ConsumerState<DeliveryDetailScreen> createState() =>
      _DeliveryDetailScreenState();
}

class _DeliveryDetailScreenState extends ConsumerState<DeliveryDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(deliveryDetailProvider.notifier)
          .loadOrderDetail(widget.orderUuid);
    });
  }

  @override
  void dispose() {
    ref.read(deliveryDetailProvider.notifier).reset();
    super.dispose();
  }

  Future<void> _handleAccept() async {
    final notes = await _showNotesDialog(
      title: 'Accepter la livraison',
      hint: 'Ajouter une note (optionnel)',
    );

    if (notes == null) return;

    _showLoadingDialog();

    final location = await LocationService.getCurrentLocation();

    if (!mounted) return;

    if (location == null) {
      Navigator.pop(context);
      _showError('Impossible d\'obtenir votre position GPS');
      return;
    }

    final success = await ref.read(deliveriesProvider.notifier).updateOrderStatus(
      widget.orderUuid,
      'accepted',
      notes: notes.isEmpty ? null : notes,
      location: location,
    );

    if (!mounted) return;
    Navigator.pop(context);

    if (success) {
      ref.read(deliveriesProvider.notifier).refreshDeliveries();
      ref
          .read(deliveryDetailProvider.notifier)
          .loadOrderDetail(widget.orderUuid);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text('Livraison acceptée !'),
            ],
          ),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      _showError('Erreur lors de l\'acceptation');
    }
  }

  Future<void> _handleReject() async {
    final notes = await _showNotesDialog(
      title: 'Refuser la livraison',
      hint: 'Raison du refus',
      required: true,
    );

    if (notes == null || notes.isEmpty) return;

    _showLoadingDialog();

    final location = await LocationService.getCurrentLocation();

    if (!mounted) return;

    if (location == null) {
      Navigator.pop(context);
      _showError('Impossible d\'obtenir votre position GPS');
      return;
    }

    final success = await ref.read(deliveriesProvider.notifier).updateOrderStatus(
      widget.orderUuid,
      'cancelled',
      notes: notes,
      location: location,
    );

    if (!mounted) return;
    Navigator.pop(context);

    if (success) {
      ref.read(deliveriesProvider.notifier).refreshDeliveries();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text('Livraison refusée'),
            ],
          ),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
    } else {
      _showError('Erreur lors du refus');
    }
  }

  Future<void> _handleStatusUpdate() async {
    final detailState = ref.read(deliveryDetailProvider);
    final currentStatus = detailState.assignment?.assignmentStatus ?? '';

    showDialog(
      context: context,
      builder: (context) => StatusUpdateDialog(
        currentStatus: currentStatus,
        onConfirm: (status, notes) async {
          _showLoadingDialog();

          final location = await LocationService.getCurrentLocation();

          if (!mounted) return;

          if (location == null) {
            Navigator.pop(context);
            _showError('Impossible d\'obtenir votre position GPS');
            return;
          }

          final success = await ref
              .read(deliveriesProvider.notifier)
              .updateOrderStatus(
            widget.orderUuid,
            status,
            notes: notes,
            location: location,
          );

          if (!mounted) return;
          Navigator.pop(context);

          if (success) {
            ref.read(deliveriesProvider.notifier).refreshDeliveries();
            ref
                .read(deliveryDetailProvider.notifier)
                .loadOrderDetail(widget.orderUuid);

            String message;
            Color backgroundColor;

            switch (status) {
              case 'picked':
                message = 'Colis récupéré ✅';
                backgroundColor = AppTheme.info;
                break;
              case 'delivering':
                message = 'Livraison en cours 🚗';
                backgroundColor = AppTheme.warning;
                break;
              case 'delivered':
                message = 'Livraison terminée 🎉';
                backgroundColor = AppTheme.success;
                break;
              case 'returned':
                message = 'Colis retourné 🔄';
                backgroundColor = AppTheme.warning;
                break;
              case 'cancelled':
                message = 'Course annulée ❌';
                backgroundColor = AppTheme.error;
                break;
              default:
                message = 'Statut mis à jour';
                backgroundColor = AppTheme.success;
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.white),
                    const SizedBox(width: 12),
                    Text(message),
                  ],
                ),
                backgroundColor: backgroundColor,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else {
            _showError('Erreur lors de la mise à jour');
          }
        },
      ),
    );
  }

  // ✅ Gérer l'appel téléphonique
  Future<void> _handlePhoneCall(String phoneNumber) async {
    final success = await CallService.makePhoneCall(phoneNumber);

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Impossible de lancer l\'appel. Vérifiez que votre appareil peut passer des appels.',
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  // ✅ Gérer WhatsApp
  void _handleWhatsApp(String contact) async {
    final detailState = ref.read(deliveryDetailProvider);
    final orderNumber = detailState.assignment?.order.orderNumber ?? '';

    final message =
        'Bonjour, je suis votre livreur Valeur Delivery pour la commande $orderNumber.';

    final encodedMessage = Uri.encodeComponent(message);

    String cleanNumber = contact.replaceAll(RegExp(r'[^\d]'), '');

    if (!cleanNumber.startsWith('225')) {
      cleanNumber = '225$cleanNumber';
    }

    final androidUrl =
        'whatsapp://send?phone=$cleanNumber&text=$encodedMessage';
    final iosUrl = 'https://wa.me/$cleanNumber?text=$encodedMessage';

    try {
      if (Platform.isIOS) {
        await launchUrl(
          Uri.parse(iosUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        await launchUrl(
          Uri.parse(androidUrl),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Impossible d'ouvrir WhatsApp. Vérifiez qu'il est installé.",
            ),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  // ✅ Naviguer vers le lieu de pickup
  void _navigateToPickup(assignment) {
    if (assignment.order.pickupLatitude == null ||
        assignment.order.pickupLongitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Coordonnées du pickup non disponibles'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NavigationScreen(
          destination: LatLng(
            assignment.order.pickupLatitude!,
            assignment.order.pickupLongitude!,
          ),
          destinationName: 'Point de récupération',
          destinationAddress: assignment.order.pickupAddress ?? '',
        ),
      ),
    );
  }

  // ✅ Naviguer vers le lieu de livraison
  void _navigateToDelivery(assignment) {
    if (assignment.order.deliveryLatitude == null ||
        assignment.order.deliveryLongitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Coordonnées de livraison non disponibles'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NavigationScreen(
          destination: LatLng(
            assignment.order.deliveryLatitude!,
            assignment.order.deliveryLongitude!,
          ),
          destinationName: assignment.order.customerName ?? 'Client',
          destinationAddress: assignment.order.deliveryAddress ?? '',
        ),
      ),
    );
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppTheme.primaryRed),
                  SizedBox(height: 16),
                  Text(
                    'Mise à jour en cours...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<String?> _showNotesDialog({
    required String title,
    required String hint,
    bool required = false,
  }) {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppTheme.cardGrey,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text(
              'Annuler',
              style: TextStyle(color: AppTheme.textGrey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (required && controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Veuillez saisir une raison'),
                    backgroundColor: AppTheme.error,
                  ),
                );
                return;
              }
              Navigator.pop(context, controller.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detailState = ref.watch(deliveryDetailProvider);
    final isLoading = detailState.isLoading;
    final hasError = detailState.hasError;
    final assignment = detailState.assignment;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(assignment?.order.orderNumber ?? 'Détail'),
        backgroundColor: AppTheme.cardLight,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: isLoading
                ? null
                : () => ref
                .read(deliveryDetailProvider.notifier)
                .loadOrderDetail(widget.orderUuid),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasError
          ? _buildErrorState(detailState.errorMessage)
          : assignment == null
          ? _buildEmptyState()
          : _buildDetailContent(assignment),
      floatingActionButton: assignment != null &&
          !assignment.isAssigned &&
          !assignment.isCompleted &&
          !assignment.isFailed &&
          !assignment.isCancelled
          ? FloatingActionButton.extended(
        onPressed: _handleStatusUpdate,
        backgroundColor: AppTheme.primaryRed,
        icon: const Icon(Icons.edit_rounded, color: Colors.white),
        label: const Text(
          'Changer statut',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      )
          : null,
    );
  }

  Widget _buildErrorState(String? errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 50,
              color: AppTheme.error,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Erreur de chargement',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage ?? 'Une erreur est survenue',
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textGrey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => ref
                .read(deliveryDetailProvider.notifier)
                .loadOrderDetail(widget.orderUuid),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text('Aucune donnée disponible'),
    );
  }

  Widget _buildDetailContent(assignment) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statut
          _buildStatusCard(assignment),

          const SizedBox(height: 20),

          // ✅ NOUVEAU : Parcours de livraison (Pickup → Delivery)
          _buildDeliveryJourney(assignment),

          const SizedBox(height: 20),

          // Infos client avec boutons d'appel
          _buildClientCard(assignment),

          const SizedBox(height: 16),

          // Zone + Barcode
          _buildSectionCard(
            'Informations',
            Icons.map_rounded,
            [
              _buildInfoRow(
                  'Zone', assignment.order.zone.name ?? 'Zone inconnue'),
              _buildInfoRow('Code barre',
                  assignment.order.barcodeValue ?? 'Non disponible'),
              _buildInfoRow(
                'Express',
                assignment.order.isExpress ? 'Oui ⚡' : 'Non',
                valueColor: assignment.order.isExpress
                    ? AppTheme.warning
                    : AppTheme.textGrey,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Dates
          _buildSectionCard(
            'Dates',
            Icons.calendar_today_rounded,
            [
              if (assignment.order.reservedAt != null)
                _buildInfoRow(
                  'Réservée le',
                  DateFormat('dd/MM/yyyy à HH:mm', 'fr_FR')
                      .format(assignment.order.reservedAt!),
                ),
              _buildInfoRow(
                'Assignée le',
                DateFormat('dd/MM/yyyy à HH:mm', 'fr_FR')
                    .format(assignment.assignedAt),
              ),
              if (assignment.acceptedAt != null)
                _buildInfoRow(
                  'Acceptée le',
                  DateFormat('dd/MM/yyyy à HH:mm', 'fr_FR')
                      .format(assignment.acceptedAt!),
                ),
              if (assignment.completedAt != null)
                _buildInfoRow(
                  'Terminée le',
                  DateFormat('dd/MM/yyyy à HH:mm', 'fr_FR')
                      .format(assignment.completedAt!),
                ),
            ],
          ),

          const SizedBox(height: 32),

          // Boutons d'action pour accepter/refuser
          if (assignment.isAssigned) _buildActionButtons(),

          // Instructions pour changer de statut
          if (!assignment.isAssigned &&
              !assignment.isCompleted &&
              !assignment.isFailed &&
              !assignment.isCancelled)
            _buildStatusChangeHint(assignment),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildStatusCard(assignment) {
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
    } else if (assignment.isDelivering) {
      statusColor = AppTheme.info;
      statusIcon = Icons.local_shipping_rounded;
    } else if (assignment.isDelivered || assignment.isCompleted) {
      statusColor = AppTheme.success;
      statusIcon = Icons.verified_rounded;
    } else if (assignment.isReturned) {
      statusColor = AppTheme.warning;
      statusIcon = Icons.keyboard_return_rounded;
    } else {
      statusColor = AppTheme.error;
      statusIcon = Icons.cancel_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor.withOpacity(0.15),
            statusColor.withOpacity(0.05)
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Statut',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  assignment.statusDisplay,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ NOUVEAU : Parcours de livraison
  Widget _buildDeliveryJourney(assignment) {
    final pickupAddress =
        assignment.order.pickupAddress ?? 'Adresse non disponible';
    final deliveryAddress =
        assignment.order.deliveryAddress ?? 'Adresse non disponible';

    final bool isPickupPhase = assignment.isAccepted || assignment.isPicked;
    final bool isDeliveryPhase =
        assignment.isDelivering || assignment.isDelivered;
    final bool isCompleted = assignment.isCompleted;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.info.withOpacity(0.1),
            AppTheme.primaryRed.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.info.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.info.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.route_rounded,
                  color: AppTheme.info,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Parcours de livraison',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ÉTAPE 1 : PICKUP
          _buildJourneyStep(
            stepNumber: 1,
            title: 'Récupération du colis',
            address: pickupAddress,
            icon: Icons.inventory_2_rounded,
            color: AppTheme.warning,
            isActive: isPickupPhase,
            isCompleted: isDeliveryPhase || isCompleted,
            showNavigation: assignment.isAccepted || assignment.isPicked,
            onNavigate: assignment.order.pickupLatitude != null &&
                assignment.order.pickupLongitude != null
                ? () => _navigateToPickup(assignment)
                : null,
          ),

          const SizedBox(height: 16),

          _buildConnectionLine(isActive: isDeliveryPhase || isCompleted),

          const SizedBox(height: 16),

          // ÉTAPE 2 : DELIVERY
          _buildJourneyStep(
            stepNumber: 2,
            title: 'Livraison au client',
            address: deliveryAddress,
            icon: Icons.home_rounded,
            color: AppTheme.success,
            isActive: isDeliveryPhase,
            isCompleted: isCompleted,
            showNavigation: assignment.isDelivering,
            onNavigate: assignment.order.deliveryLatitude != null &&
                assignment.order.deliveryLongitude != null
                ? () => _navigateToDelivery(assignment)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildJourneyStep({
    required int stepNumber,
    required String title,
    required String address,
    required IconData icon,
    required Color color,
    required bool isActive,
    required bool isCompleted,
    required bool showNavigation,
    VoidCallback? onNavigate,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive
            ? color.withOpacity(0.1)
            : isCompleted
            ? AppTheme.success.withOpacity(0.05)
            : AppTheme.cardGrey.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? color
              : isCompleted
              ? AppTheme.success
              : AppTheme.textGrey.withOpacity(0.3),
          width: isActive ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppTheme.success
                      : isActive
                      ? color
                      : AppTheme.textGrey.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 20,
                  )
                      : Text(
                    stepNumber.toString(),
                    style: TextStyle(
                      color:
                      isActive ? Colors.white : AppTheme.textGrey,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          icon,
                          size: 16,
                          color: isActive
                              ? color
                              : isCompleted
                              ? AppTheme.success
                              : AppTheme.textGrey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isActive || isCompleted
                                  ? AppTheme.textDark
                                  : AppTheme.textGrey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (isActive)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'En cours',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Icon(
                Icons.location_on_rounded,
                size: 14,
                color: isActive
                    ? color
                    : isCompleted
                    ? AppTheme.success
                    : AppTheme.textGrey,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  address,
                  style: TextStyle(
                    fontSize: 13,
                    color: isActive || isCompleted
                        ? AppTheme.textDark
                        : AppTheme.textGrey,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          if (showNavigation && onNavigate != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onNavigate,
                icon: const Icon(Icons.navigation_rounded, size: 16),
                label: Text(
                  stepNumber == 1
                      ? 'Se rendre au pickup'
                      : 'Se rendre au client',
                  style: const TextStyle(fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConnectionLine({required bool isActive}) {
    return Row(
      children: [
        const SizedBox(width: 18),
        Container(
          width: 2,
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isActive
                  ? [AppTheme.warning, AppTheme.success]
                  : [
                AppTheme.textGrey.withOpacity(0.3),
                AppTheme.textGrey.withOpacity(0.3),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClientCard(assignment) {
    final phoneNumber = assignment.order.customerPhone ?? '';
    final hasValidPhone = CallService.isValidPhoneNumber(phoneNumber);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardLight,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.person_rounded,
                    color: AppTheme.primaryRed, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Client',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _buildInfoRow('Nom', assignment.order.customerName ?? 'N/A'),

          if (hasValidPhone) ...[
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Téléphone',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textGrey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        CallService.formatPhoneNumber(phoneNumber),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textDark,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildContactButton(
                            icon: Icons.phone_rounded,
                            label: 'Appeler',
                            color: AppTheme.success,
                            onPressed: () => _handlePhoneCall(phoneNumber),
                          ),
                          _buildContactButton(
                            icon: Icons.chat_rounded,
                            label: 'WhatsApp',
                            color: const Color(0xFF25D366),
                            onPressed: () => _handleWhatsApp(phoneNumber),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            _buildInfoRow(
                'Téléphone', phoneNumber.isEmpty ? 'N/A' : phoneNumber),
          ],
        ],
      ),
    );
  }

  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(
      String title,
      IconData icon,
      List<Widget> children,
      ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardLight,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.primaryRed, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: valueColor ?? AppTheme.textDark,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _handleReject,
            icon: const Icon(Icons.close_rounded),
            label: const Text('Refuser'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.error,
              side: const BorderSide(color: AppTheme.error, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: _handleAccept,
            icon: const Icon(Icons.check_rounded),
            label: const Text('Accepter'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChangeHint(assignment) {
    String hintText;
    IconData hintIcon;
    Color hintColor;

    if (assignment.isAccepted) {
      hintText =
      'Appuyez sur "Changer statut" pour indiquer que vous avez récupéré le colis';
      hintIcon = Icons.inventory_2_rounded;
      hintColor = AppTheme.info;
    } else if (assignment.isPicked) {
      hintText = 'Appuyez sur "Changer statut" pour démarrer la livraison';
      hintIcon = Icons.local_shipping_rounded;
      hintColor = AppTheme.warning;
    } else if (assignment.isDelivering) {
      hintText =
      'Appuyez sur "Changer statut" pour marquer la livraison comme terminée, retournée ou annulée';
      hintIcon = Icons.done_all_rounded;
      hintColor = AppTheme.success;
    } else {
      hintText =
      'Utilisez le bouton "Changer statut" en bas à droite pour mettre à jour la livraison';
      hintIcon = Icons.info_rounded;
      hintColor = AppTheme.info;
    }

    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hintColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hintColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: hintColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hintIcon,
              color: hintColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              hintText,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}