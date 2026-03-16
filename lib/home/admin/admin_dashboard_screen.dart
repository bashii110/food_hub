import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/api_client.dart';
import '../../presentation/providers/auth_provider.dart';
import 'admin_order_screen.dart';
import 'admin_payment_settingscreen.dart';
import 'admin_product_screen.dart';
import 'adminuser_screen.dart';


// ══════════════════════════════════════════════════════════════
// ADMIN STATS PROVIDER
// ══════════════════════════════════════════════════════════════
final adminStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    return await apiClient.get('/admin/dashboard');
  } catch (e) {
    debugPrint('Admin stats error: $e');
    return {
      'total_orders': 0,
      'today_orders': 0,
      'pending_verification': 0,
      'total_revenue': 0.0,
      'today_revenue': 0.0,
      'total_users': 0,
      'total_products': 0,
      'recent_orders': [],
    };
  }
});


// ══════════════════════════════════════════════════════════════
// ADMIN DASHBOARD SCREEN
// ══════════════════════════════════════════════════════════════
class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState
    extends ConsumerState<AdminDashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    _DashboardTab(),
    AdminOrdersScreen(),
    AdminProductsScreen(),
    AdminUsersScreen(),
    AdminPaymentSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authProvider);
    final user = authAsync.asData?.value.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          // ── USER INFO ─────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  user?.name ?? 'Admin',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  (user?.role ?? 'admin').toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // ── LOGOUT ───────────────────────────────
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await ref.read(authProvider.notifier).logout(); // ✅ triggers AppRoot rebuild
              }
            },
          )

        ],
      ),

      body: Row(
        children: [
          // ── NAVIGATION RAIL ─────────────────────
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long),
                label: Text('Orders'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.restaurant_menu_outlined),
                selectedIcon: Icon(Icons.restaurant_menu),
                label: Text('Products'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: Text('Users'),
              ),
              NavigationRailDestination(
                icon:         Icon(Icons.account_balance_wallet_outlined),
                selectedIcon: Icon(Icons.account_balance_wallet),
                label:        Text('Payments'),
              ),
            ],
          ),

          const VerticalDivider(width: 1),

          // ── CONTENT ─────────────────────────────
          Expanded(
            child: _screens[_selectedIndex],
          ),
        ],
      ),
    );
  }
}


// ══════════════════════════════════════════════════════════════
// DASHBOARD TAB
// ══════════════════════════════════════════════════════════════
class _DashboardTab extends ConsumerWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(adminStatsProvider),
      child: statsAsync.when(
        loading: () =>
        const Center(child: CircularProgressIndicator()),

        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Failed to load dashboard'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () =>
                    ref.invalidate(adminStatsProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),

        data: (stats) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Overview',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              // ── STATS GRID ───────────────────────
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _StatCard(
                    title: 'Total Orders',
                    value: stats['total_orders'].toString(),
                    icon: Icons.shopping_cart,
                    color: Colors.blue,
                  ),
                  _StatCard(
                    title: 'Today Orders',
                    value: stats['today_orders'].toString(),
                    icon: Icons.today,
                    color: Colors.green,
                  ),
                  _StatCard(
                    title: 'Pending Verification',
                    value:
                    stats['pending_verification'].toString(),
                    icon: Icons.pending_actions,
                    color: Colors.orange,
                  ),
                  _StatCard(
                    title: 'Total Users',
                    value: stats['total_users'].toString(),
                    icon: Icons.people,
                    color: Colors.purple,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── REVENUE GRID ─────────────────────
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2,
                children: [
                  _RevenueCard(
                    title: 'Total Revenue',
                    amount: double.tryParse(stats['total_revenue'].toString()) ?? 0.0,
                    color: Theme.of(context).colorScheme.primary, // Use primary color
                  ),
                  _RevenueCard(
                    title: 'Today Revenue',
                    amount: double.tryParse(stats['today_revenue'].toString()) ?? 0.0,
                    color: Theme.of(context).colorScheme.secondary, // Use secondary color
                  ),


                  _StatCard(
                    title: 'Total Products',
                    value:
                    stats['total_products'].toString(),
                    icon: Icons.restaurant_menu,
                    color: Colors.red,
                  ),
                ],
              ),

              const SizedBox(height: 32),

              Text(
                'Recent Orders',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              _RecentOrdersList(
                orders: stats['recent_orders'] ?? [],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// ══════════════════════════════════════════════════════════════
// STAT CARD
// ══════════════════════════════════════════════════════════════
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(title,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}


// ══════════════════════════════════════════════════════════════
// REVENUE CARD
// ══════════════════════════════════════════════════════════════
class _RevenueCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;

  const _RevenueCard({
    required this.title,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              'Rs ${amount.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ══════════════════════════════════════════════════════════════
// RECENT ORDERS LIST
// ══════════════════════════════════════════════════════════════
class _RecentOrdersList extends StatelessWidget {
  final List<dynamic> orders;

  const _RecentOrdersList({required this.orders});

  Color _statusColor(String status) {
    switch (status) {
      case 'pending_payment':
        return Colors.orange;
      case 'pending_verification':
        return Colors.amber;
      case 'verified':
        return Colors.blue;
      case 'preparing':
        return Colors.purple;
      case 'out_for_delivery':
        return Colors.teal;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: Text('No recent orders')),
      );
    }

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: orders.length,
        separatorBuilder: (_, __) =>
        const Divider(height: 1),
        itemBuilder: (context, index) {
          final order = orders[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor:
              _statusColor(order['status']),
              child: Text(
                '#${order['id']}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
            ),
            title:
            Text(order['user']?['name'] ?? 'Unknown'),
            subtitle: Text(
              order['status']
                  .toString()
                  .replaceAll('_', ' ')
                  .toUpperCase(),
              style: TextStyle(
                color:
                _statusColor(order['status']),
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: Text(
              'Rs ${order['total_amount']}',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
          );
        },
      ),
    );
  }
}
