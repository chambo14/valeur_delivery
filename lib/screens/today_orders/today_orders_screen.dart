import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/today_orders_provider.dart';
import '../../theme/app_theme.dart';

class TodayOrdersScreen extends ConsumerStatefulWidget {
  const TodayOrdersScreen({super.key});

  @override
  ConsumerState<TodayOrdersScreen> createState() => _TodayOrdersScreenState();
}

class _TodayOrdersScreenState extends ConsumerState<TodayOrdersScreen> {
  @override
  void initState() {
    super.initState();

    // Charger les courses au démarrage
    Future.microtask(() {
      ref.read(todayOrdersProvider.notifier).loadTodayOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final todayOrdersState = ref.watch(todayOrdersProvider);
    final totalOrders = ref.watch(todayOrdersCountProvider);
    final assignedCount = ref.watch(todayAssignedCountProvider);
    final acceptedCount = ref.watch(todayAcceptedCountProvider);
    final expressCount = ref.watch(todayExpressCountProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Courses du jour'),
        backgroundColor: AppTheme.cardLight,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              ref.read(todayOrdersProvider.notifier).refreshTodayOrders();
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(todayOrdersProvider.notifier).refreshTodayOrders(),
        color: AppTheme.primaryRed,
        child: Column(
          children: [
            // Stats header
            Container(
              padding: const EdgeInsets.all(16),
              color: AppTheme.cardLight,
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total',
                      totalOrders.toString(),
                      AppTheme.info,
                      Icons.list_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Assignées',
                      assignedCount.toString(),
                      AppTheme.warning,
                      Icons.assignment_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Acceptées',
                      acceptedCount.toString(),
                      AppTheme.success,
                      Icons.check_circle_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Express',
                      expressCount.toString(),
                      AppTheme.primaryRed,
                      Icons.bolt_rounded,
                    ),
                  ),
                ],
              ),
            ),

            // Liste des courses
            Expanded(
              child: _buildBody(todayOrdersState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(TodayOrdersState state) {
    if (state.isLoading && !state.hasData) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryRed),
      );
    }

    if (state.hasError && !state.hasData) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 64, color: AppTheme.error),
            const SizedBox(height: 16),
            Text(
              state.errorMessage ?? 'Une erreur est survenue',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textGrey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(todayOrdersProvider.notifier).loadTodayOrders();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (!state.hasData) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_rounded,
              size: 80,
              color: AppTheme.textGrey.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune course',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textGrey.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vous n\'avez pas de courses pour aujourd\'hui',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textGrey.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.orders.length,
      itemBuilder: (context, index) {
        final assignment = state.orders[index];
        return _buildOrderCard(assignment);
      },
    );
  }

  Widget _buildOrderCard(assignment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardLight,
        borderRadius: BorderRadius.circular(16),
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
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: assignment.order.isExpress
                  ? AppTheme.primaryRed.withOpacity(0.1)
                  : AppTheme.info.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                if (assignment.order.isExpress)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryRed,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt_rounded, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'EXPRESS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    assignment.order.orderNumber,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: assignment.isAccepted
                        ? AppTheme.success.withOpacity(0.1)
                        : AppTheme.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    assignment.statusDisplay,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: assignment.isAccepted
                          ? AppTheme.success
                          : AppTheme.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Client
                Row(
                  children: [
                    const Icon(Icons.person_rounded, size: 18, color: AppTheme.textGrey),
                    const SizedBox(width: 8),
                    Text(
                      assignment.order.customerName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      assignment.order.customerPhone,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textGrey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Adresse de livraison
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_rounded, size: 18, color: AppTheme.primaryRed),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        assignment.order.deliveryAddress,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ),
                  ],
                ),

                // Boutons d'action pour assignées
                if (assignment.isAssigned) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final success = await ref
                                .read(todayOrdersProvider.notifier)
                                .rejectOrder(assignment.order.uuid);

                            if (success && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Course refusée'),
                                  backgroundColor: AppTheme.error,
                                ),
                              );
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.error,
                            side: const BorderSide(color: AppTheme.error),
                          ),
                          child: const Text('Refuser'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () async {
                            final success = await ref
                                .read(todayOrdersProvider.notifier)
                                .acceptOrder(assignment.order.uuid);

                            if (success && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Course acceptée'),
                                  backgroundColor: AppTheme.success,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.success,
                          ),
                          child: const Text('Accepter'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}