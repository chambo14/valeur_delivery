import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class StatusUpdateDialog extends StatefulWidget {
  final String currentStatus;
  final Function(String status, String? notes) onConfirm;

  const StatusUpdateDialog({
    super.key,
    required this.currentStatus,
    required this.onConfirm,
  });

  @override
  State<StatusUpdateDialog> createState() => _StatusUpdateDialogState();
}

class _StatusUpdateDialogState extends State<StatusUpdateDialog> {
  final TextEditingController _notesController = TextEditingController();
  String? _selectedStatus;

  // ✅ CORRIGÉ : Utiliser les vrais statuts du backend
  final Map<String, Map<String, dynamic>> _statusOptions = {
    'accepted': {
      'label': 'Accepter',
      'icon': Icons.check_circle_rounded,
      'color': AppTheme.success,
    },
    'picked': { // ✅ CORRIGÉ : "picked" au lieu de "picked_up"
      'label': 'Récupérée',
      'icon': Icons.inventory_2_rounded,
      'color': AppTheme.info,
    },
    'delivering': { // ✅ CORRIGÉ : "delivering" au lieu de "in_transit"
      'label': 'En transit',
      'icon': Icons.local_shipping_rounded,
      'color': AppTheme.warning,
    },
    'delivered': {
      'label': 'Livrée',
      'icon': Icons.done_all_rounded,
      'color': AppTheme.success,
    },
    'cancelled': {
      'label': 'Annuler',
      'icon': Icons.cancel_rounded,
      'color': AppTheme.error,
    },
    'returned': {
      'label': 'Retournée',
      'icon': Icons.keyboard_return_rounded,
      'color': AppTheme.warning,
    },
  };

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView( // ✅ Ajout pour éviter overflow
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      color: AppTheme.primaryRed,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Changer le statut',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Options de statut
              ...(_statusOptions.entries.map((entry) {
                if (entry.key == widget.currentStatus) return const SizedBox.shrink();

                final isSelected = _selectedStatus == entry.key;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedStatus = entry.key;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? entry.value['color'].withOpacity(0.1)
                            : AppTheme.cardGrey,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? entry.value['color']
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            entry.value['icon'],
                            color: isSelected
                                ? entry.value['color']
                                : AppTheme.textGrey,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              entry.value['label'],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: isSelected
                                    ? entry.value['color']
                                    : AppTheme.textDark,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle_rounded,
                              color: entry.value['color'],
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList()),

              const SizedBox(height: 16),

              // Champ notes
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Notes (optionnel)',
                  hintText: 'Ajouter une note...',
                  filled: true,
                  fillColor: AppTheme.cardGrey,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Boutons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: AppTheme.textGrey.withOpacity(0.3),
                        ),
                      ),
                      child: const Text(
                        'Annuler',
                        style: TextStyle(
                          color: AppTheme.textGrey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _selectedStatus == null
                          ? null
                          : () {
                        widget.onConfirm(
                          _selectedStatus!,
                          _notesController.text.isEmpty
                              ? null
                              : _notesController.text,
                        );
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedStatus == null
                            ? AppTheme.textGrey
                            : AppTheme.primaryRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Confirmer',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}