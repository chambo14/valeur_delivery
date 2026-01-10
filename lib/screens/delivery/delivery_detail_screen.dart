import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/providers/deliveries_provider.dart';
import '../../data/providers/delivery_detail_provider.dart';
import '../../theme/app_theme.dart';

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
    // ✅ Charger le détail au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(deliveryDetailProvider.notifier)
          .loadOrderDetail(widget.orderUuid);
    });
  }

  @override
  void dispose() {
    // ✅ Réinitialiser l'état en quittant
    ref.read(deliveryDetailProvider.notifier).reset();
    super.dispose();
  }

  // ✅ Gérer l'acceptation
  Future<void> _handleAccept() async {
    // Demander une note optionnelle
    final notes = await _showNotesDialog(
      title: 'Accepter la livraison',
      hint: 'Ajouter une note (optionnel)',
    );

    if (notes == null) return; // Annulé

    final success = await ref
        .read(deliveryDetailProvider.notifier)
        .acceptAssignment(notes: notes.isEmpty ? null : notes);

    if (!mounted) return;

    if (success) {
      // Rafraîchir la liste des livraisons
      ref.read(deliveriesProvider.notifier).refreshDeliveries();

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
      final errorMessage = ref.read(deliveryDetailProvider).errorMessage;
      _showError(errorMessage ?? 'Erreur lors de l\'acceptation');
    }
  }

  // ✅ Gérer le refus
  Future<void> _handleReject() async {
    // Demander une raison obligatoire
    final notes = await _showNotesDialog(
      title: 'Refuser la livraison',
      hint: 'Raison du refus',
      required: true,
    );

    if (notes == null || notes.isEmpty) return; // Annulé ou vide

    final success = await ref
        .read(deliveryDetailProvider.notifier)
        .rejectAssignment(notes: notes);

    if (!mounted) return;

    if (success) {
      // Rafraîchir la liste des livraisons
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
      final errorMessage = ref.read(deliveryDetailProvider).errorMessage;
      _showError(errorMessage ?? 'Erreur lors du refus');
    }
  }

  // ✅ Gérer la mise à jour du statut
  Future<void> _handleUpdateStatus(String newStatus) async {
    // Demander une note optionnelle
    final notes = await _showNotesDialog(
      title: 'Mettre à jour le statut',
      hint: 'Ajouter une note (optionnel)',
    );

    if (notes == null) return; // Annulé

    final success = await ref
        .read(deliveryDetailProvider.notifier)
        .updateStatus(newStatus, notes: notes.isEmpty ? null : notes);

    if (!mounted) return;

    if (success) {
      // Rafraîchir la liste des livraisons
      ref.read(deliveriesProvider.notifier).refreshDeliveries();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Text('Statut mis à jour : $newStatus'),
            ],
          ),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      final errorMessage = ref.read(deliveryDetailProvider).errorMessage;
      _showError(errorMessage ?? 'Erreur lors de la mise à jour');
    }
  }

  // ✅ Afficher une erreur
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
      ),
    );
  }

  // ✅ Dialog pour saisir les notes
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
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Annuler'),
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
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Écouter l'état du détail
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
          // ✅ Bouton refresh
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: isLoading
                ? null
                : () =>
                ref.read(deliveryDetailProvider.notifier).refreshDetail(),
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
    final detailState = ref.watch(deliveryDetailProvider);
    final isAccepting = detailState.isAccepting;
    final isRejecting = detailState.isRejecting;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statut
          _buildStatusCard(assignment),

          const SizedBox(height: 20),

          // Infos client
          _buildSectionCard(
            'Client',
            Icons.person_rounded,
            [
              _buildInfoRow('Nom', assignment.order.customerName),
              _buildInfoRow('Téléphone', assignment.order.customerPhone),
            ],
          ),

          const SizedBox(height: 16),

          // Adresses
          _buildSectionCard(
            'Adresses',
            Icons.location_on_rounded,
            [
              _buildInfoRow('Récupération', assignment.order.pickupAddress),
              const Divider(height: 24),
              _buildInfoRow('Livraison', assignment.order.deliveryAddress),
            ],
          ),

          const SizedBox(height: 16),

          // Zone + Barcode
          _buildSectionCard(
            'Informations',
            Icons.map_rounded,
            [
              _buildInfoRow('Zone', assignment.order.zone.name),
              _buildInfoRow('Code barre', assignment.order.barcodeValue),
              _buildInfoRow(
                'Express',
                assignment.order.isExpress ? 'Oui' : 'Non',
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
              _buildInfoRow(
                'Réservée le',
                DateFormat('dd/MM/yyyy à HH:mm', 'fr_FR')
                    .format(assignment.order.reservedAt),
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

          // Boutons d'action
          if (assignment.isAssigned && !isAccepting && !isRejecting)
            _buildActionButtons(),

          // ✅ Boutons pour mettre à jour le statut (si acceptée)
          if (assignment.isAccepted && !detailState.isUpdatingStatus)
            _buildStatusUpdateButtons(),
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
    } else if (assignment.isCompleted) {
      statusColor = AppTheme.success;
      statusIcon = Icons.verified_rounded;
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
    final detailState = ref.watch(deliveryDetailProvider);
    final isAccepting = detailState.isAccepting;
    final isRejecting = detailState.isRejecting;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isAccepting || isRejecting ? null : _handleReject,
            icon: isRejecting
                ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.close_rounded),
            label: const Text('Refuser'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.error,
              side: const BorderSide(color: AppTheme.error),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: isAccepting || isRejecting ? null : _handleAccept,
            icon: isAccepting
                ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            )
                : const Icon(Icons.check_rounded),
            label: const Text('Accepter'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusUpdateButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Mettre à jour le statut :',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => _handleUpdateStatus('picked_up'),
          icon: const Icon(Icons.check_box_rounded),
          label: const Text('Marquer comme récupérée'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.info,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () => _handleUpdateStatus('in_transit'),
          icon: const Icon(Icons.local_shipping_rounded),
          label: const Text('En transit'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.warning,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () => _handleUpdateStatus('delivered'),
          icon: const Icon(Icons.verified_rounded),
          label: const Text('Marquer comme livrée'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.success,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }
}