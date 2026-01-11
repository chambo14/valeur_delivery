import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/providers/deliveries_provider.dart';
import '../../theme/app_theme.dart';
import '../delivery/delivery_detail_screen.dart';
import '../history/history_screen.dart';
import '../map/map_with_orders_screen.dart';
import '../profile/profile_screen.dart';
import '../widget/delivery_card.dart';
import '../widget/notification_icon_button.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  String? _selectedFilter;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(deliveriesProvider.notifier).loadDeliveries();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      _buildHomeContent(),
      const MapWithOrdersScreen(),
      const HistoryScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: _currentIndex == 0 ? _buildAppBar() : null,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.cardLight,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Valeur Delivery',
            style: TextStyle(
              color: AppTheme.textDark,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          Text(
            DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(DateTime.now()),
            style: const TextStyle(
              color: AppTheme.textGrey,
              fontSize: 12,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      actions: const [
        NotificationIconButton(),
        SizedBox(width: 8),
      ],
    );
  }

  Widget _buildHomeContent() {
    final deliveriesState = ref.watch(deliveriesProvider);
    final isLoading = deliveriesState.isLoading;
    final isRefreshing = deliveriesState.isRefreshing;
    final hasError = deliveriesState.hasError;

    final assignments = _selectedFilter == null
        ? deliveriesState.assignments
        : deliveriesState.assignments
        .where((a) => a.assignmentStatus?.toLowerCase() == _selectedFilter)
        .toList();

    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(deliveriesProvider.notifier)
            .refreshDeliveries(status: _selectedFilter);
      },
      color: AppTheme.primaryRed,
      backgroundColor: AppTheme.cardLight,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 16),
                _buildStatsCards(),
                const SizedBox(height: 24),
                _buildFilterChips(),
                const SizedBox(height: 16),
              ],
            ),
          ),

          if (isLoading && !isRefreshing)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.primaryRed),
              ),
            )
          else if (hasError)
            SliverFillRemaining(
              child: _buildErrorState(deliveriesState.errorMessage),
            )
          else if (assignments.isEmpty)
              SliverFillRemaining(
                child: _buildEmptyState(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: DeliveryCard(
                          assignment: assignments[index],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DeliveryDetailScreen(
                                  orderUuid: assignments[index].order.uuid.toString(),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                    childCount: assignments.length,
                  ),
                ),
              ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    final deliveriesState = ref.watch(deliveriesProvider);
    final totalAssignments = deliveriesState.assignments.length;
    final assignedCount = deliveriesState.assignedOnly.length;
    final acceptedCount = deliveriesState.acceptedOnly.length;
    final completedCount = deliveriesState.completedOnly.length;
    final inProgressCount = assignedCount + acceptedCount;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total',
              totalAssignments.toString(),
              Icons.local_shipping_rounded,
              AppTheme.info,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Livrées',
              completedCount.toString(),
              Icons.check_circle_rounded,
              AppTheme.success,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'En cours',
              inProgressCount.toString(),
              Icons.timelapse_rounded,
              AppTheme.warning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label,
      String value,
      IconData icon,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textGrey,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = <Map<String, dynamic>>[
      {'value': null, 'label': 'Toutes'},
      {'value': 'assigned', 'label': 'Assignées'},
      {'value': 'accepted', 'label': 'Acceptées'},
      {'value': 'picked_up', 'label': 'Récupérées'},
      {'value': 'in_transit', 'label': 'En transit'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter['value'];
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedFilter = filter['value'];
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                    colors: [
                      AppTheme.primaryRed,
                      AppTheme.accentRed,
                    ],
                  )
                      : null,
                  color: isSelected ? null : AppTheme.cardLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : AppTheme.textGrey.withOpacity(0.2),
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                    BoxShadow(
                      color: AppTheme.primaryRed.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected) ...[
                      const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      filter['label'],
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textGrey,
                        fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
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
            onPressed: () =>
                ref.read(deliveriesProvider.notifier).loadDeliveries(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    String filterText = _selectedFilter == null
        ? ''
        : _selectedFilter == 'assigned'
        ? 'assignée'
        : _selectedFilter == 'accepted'
        ? 'acceptée'
        : _selectedFilter == 'picked_up'
        ? 'récupérée'
        : _selectedFilter == 'in_transit'
        ? 'en transit'
        : '';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.textGrey.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inbox_rounded,
              size: 60,
              color: AppTheme.textGrey.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Aucune livraison',
            style: TextStyle(
              fontSize: 20,
              color: AppTheme.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            filterText.isEmpty
                ? 'Vous n\'avez aucune livraison pour le moment'
                : 'Vous n\'avez pas de livraison $filterText',
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textGrey,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.info.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_rounded, color: AppTheme.info, size: 18),
                SizedBox(width: 8),
                Text(
                  'Les nouvelles livraisons apparaîtront ici',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), // ✅ Réduit de 8 à 6
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                0,
                Icons.home_rounded,
                Icons.home_outlined,
                'Accueil',
              ),
              _buildNavItem(
                1,
                Icons.map_rounded,
                Icons.map_outlined,
                'Carte',
              ),
              _buildNavItem(
                2,
                Icons.history_rounded,
                Icons.history_rounded,
                'Historique',
              ),
              _buildNavItem(
                3,
                Icons.person_rounded,
                Icons.person_outline_rounded,
                'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      int index,
      IconData activeIcon,
      IconData inactiveIcon,
      String label,
      ) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6), // ✅ Réduit de 8 à 6
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryRed.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? activeIcon : inactiveIcon,
                color: isSelected ? AppTheme.primaryRed : AppTheme.textGrey,
                size: 20, // ✅ Réduit de 21 à 20
              ),
              const SizedBox(height: 3), // ✅ Augmenté de 2 à 3
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppTheme.primaryRed : AppTheme.textGrey,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}