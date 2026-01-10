import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/deliveries_provider.dart';
import '../../theme/app_theme.dart';

class DeliveriesListScreen extends ConsumerStatefulWidget {
  const DeliveriesListScreen({super.key});

  @override
  ConsumerState<DeliveriesListScreen> createState() =>
      _DeliveriesListScreenState();
}

class _DeliveriesListScreenState extends ConsumerState<DeliveriesListScreen> {
  @override
  void initState() {
    super.initState();
    // Charger les livraisons au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(deliveriesProvider.notifier).loadDeliveries();
    });
  }

  Future<void> _handleRefresh() async {
    await ref.read(deliveriesProvider.notifier).refreshDeliveries();
  }

  Future<void> _handleAccept(String assignmentUuid) async {
    final success = await ref
        .read(deliveriesProvider.notifier)
        .acceptAssignment(assignmentUuid);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Livraison acceptée !'),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final deliveriesState = ref.watch(deliveriesProvider);
    final isLoading = deliveriesState.isLoading;
    final assignments = deliveriesState.assignments;
    final hasError = deliveriesState.hasError;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes livraisons'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () {
              // Afficher filtre par statut
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : hasError
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 60, color: AppTheme.error),
              const SizedBox(height: 16),
              Text(deliveriesState.errorMessage ?? 'Erreur'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref
                    .read(deliveriesProvider.notifier)
                    .loadDeliveries(),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        )
            : assignments.isEmpty
            ? const Center(child: Text('Aucune livraison'))
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: assignments.length,
          itemBuilder: (context, index) {
            final assignment = assignments[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(assignment.order.orderNumber),
                subtitle: Text(assignment.order.customerName),
                trailing: assignment.isAssigned
                    ? ElevatedButton(
                  onPressed: () => _handleAccept(
                      assignment.assignmentUuid),
                  child: const Text('Accepter'),
                )
                    : Text(assignment.statusDisplay),
              ),
            );
          },
        ),
      ),
    );
  }
}