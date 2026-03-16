import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../data/services/api_client.dart';
import '../home/admin/admin_payment_settingscreen.dart';
import '../presentation/providers/auth_provider.dart';


/* ══════════════════════════════════════════════════════════
   ENTRY POINT  –  AdminApp
   ══════════════════════════════════════════════════════════ */
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setApplicationSwitcherDescription(
    const ApplicationSwitcherDescription(label: 'FoodHub Admin'),
  );
  runApp(const ProviderScope(child: AdminApp()));
}

class AdminApp extends ConsumerWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'FoodHub Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF6B6B)),
      ),
      home: const AdminRoot(),
    );
  }
}

/* ──────────────────────────────────────────────────────────
   ROOT  –  auth gate: login or shell
   ────────────────────────────────────────────────────────── */
class AdminRoot extends ConsumerWidget {
  const AdminRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    return authState.when(
      data: (s) {
        if (s.status == AuthStatus.authenticated && s.user!.isStaff) {
          return const AdminShell();
        }
        return const AdminLoginScreen();
      },
      loading: () =>
      const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const AdminLoginScreen(),
    );
  }
}

/* ──────────────────────────────────────────────────────────
   ADMIN LOGIN
   ────────────────────────────────────────────────────────── */
class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});
  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    await ref.read(authProvider.notifier).login(
      email:    _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    );
    final state = ref.read(authProvider);
    state.whenData((s) {
      if (s.status == AuthStatus.authenticated && !s.user!.isStaff) {
        ref.read(authProvider.notifier).logout();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:  Text('Access denied. Staff account required.'),
                behavior: SnackBarBehavior.floating),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final theme     = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: SizedBox(
              width: 360,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(20)),
                      child: const Icon(Icons.dashboard,
                          color: Colors.white, size: 40),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Admin Panel',
                      style: theme.textTheme.headlineMedium,
                      textAlign: TextAlign.center),
                  Text('FoodHub Management',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center),
                  const SizedBox(height: 36),

                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.colorScheme.outline)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: _passwordCtrl,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () => setState(() => _obscure = !_obscure)),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.colorScheme.outline)),
                    ),
                    onSubmitted: (_) => _login(),
                  ),
                  const SizedBox(height: 8),

                  authState.when(
                    data: (s) => s.error != null
                        ? Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(s.error!,
                            style: TextStyle(color: theme.colorScheme.error),
                            textAlign: TextAlign.center))
                        : const SizedBox.shrink(),
                    loading: () => const SizedBox.shrink(),
                    error:   (_, __) => const SizedBox.shrink(),
                  ),

                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _login,
                      child: authState.when(
                        data: (s) => s.status == AuthStatus.loading
                            ? const SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                            : const Text('Sign In',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        loading: () => const Text('Sign In'),
                        error:   (_, __) => const Text('Sign In'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Default: admin@foodhub.com / admin123',
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* ══════════════════════════════════════════════════════════
   ADMIN SHELL  –  navigation rail + page router
   ══════════════════════════════════════════════════════════ */
class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key});
  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  int _index = 0;

  static final _destinations = [
    const NavigationRailDestination(
        icon:         Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label:        Text('Dashboard')),
    const NavigationRailDestination(
        icon:         Icon(Icons.shopping_bag_outlined),
        selectedIcon: Icon(Icons.shopping_bag),
        label:        Text('Orders')),
    const NavigationRailDestination(
        icon:         Icon(Icons.fastfood_outlined),
        selectedIcon: Icon(Icons.fastfood),
        label:        Text('Products')),
    const NavigationRailDestination(
        icon:         Icon(Icons.people_outlined),
        selectedIcon: Icon(Icons.people),
        label:        Text('Users')),
    const NavigationRailDestination(                        // ← NEW
        icon:         Icon(Icons.account_balance_wallet_outlined),
        selectedIcon: Icon(Icons.account_balance_wallet),
        label:        Text('Payments')),
  ];

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.when(
        data: (s) => s.user, loading: () => null, error: (_, __) => null);

    return Scaffold(
      body: Row(
        children: [
          /* ── Rail ─── */
          NavigationRail(
            selectedIndex:           _index,
            onDestinationSelected:   (i) => setState(() => _index = i),
            destinations:            _destinations,
            labelType:               NavigationRailLabelType.selected,
            leading: Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.fastfood, color: Colors.white, size: 28),
              ),
            ),
            trailing: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(user?.name ?? '', style: const TextStyle(fontSize: 11)),
                IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () => ref.read(authProvider.notifier).logout()),
              ],
            ),
          ),
          const VerticalDivider(thickness: 0.5),

          /* ── Page content ─── */
          Expanded(
            child: IndexedStack(
              index: _index,
              children: const [
                DashboardPage(),
                OrdersPage(),
                ProductsPage(),
                UsersPage(),
                AdminPaymentSettingsScreen(),               // ← NEW
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* Helper extension */
extension _UserExt on AppUser {
  bool get isStaff => role == 'admin' || role == 'staff';
}

/* ══════════════════════════════════════════════════════════
   DASHBOARD PAGE
   ══════════════════════════════════════════════════════════ */
class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});
  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      _stats = await apiClient.get('/admin/dashboard');
      setState(() => _loading = false);
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'), behavior: SnackBarBehavior.floating));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _stats == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final theme               = Theme.of(context);
    final totalOrders         = _stats!['total_orders'] as int;
    final todayOrders         = _stats!['today_orders'] as int;
    final pendingVerification = _stats!['pending_verification'] as int;
    final totalRevenue        = (_stats!['total_revenue'] as num).toDouble();
    final todayRevenue        = (_stats!['today_revenue'] as num).toDouble();
    final totalUsers          = _stats!['total_users'] as int;
    final totalProducts       = _stats!['total_products'] as int;
    final recentOrders        = _stats!['recent_orders'] as List;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Dashboard',
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.refresh), onPressed: _fetch),
            ],
          ),
          const SizedBox(height: 24),

          Row(children: [
            _statCard(context, 'Total Orders',    totalOrders,         Icons.shopping_bag,    theme.colorScheme.primary),
            _statCard(context, 'Today Orders',    todayOrders,         Icons.today,           Colors.blue),
            _statCard(context, 'Pending Verify',  pendingVerification, Icons.pending_actions, Colors.orange),
            _statCard(context, 'Total Users',     totalUsers,          Icons.people,          Colors.green),
          ]),
          const SizedBox(height: 16),

          Row(children: [
            _revenueCard(context, 'Total Revenue',   totalRevenue,              theme.colorScheme.primary),
            _revenueCard(context, 'Today Revenue',   todayRevenue,              Colors.green),
            _revenueCard(context, 'Total Products',  totalProducts.toDouble(),  Colors.purple),
          ]),
          const SizedBox(height: 24),

          Text('Recent Orders',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: recentOrders.map((o) {
                final order = o as Map<String, dynamic>;
                final user  = order['user'] as Map<String, dynamic>;
                return ListTile(
                  leading:  _statusIcon(order['status'] as String),
                  title:    Text('Order #${order['id']}  –  ${user['name']}'),
                  subtitle: Text(
                      'Rs ${(order['total_amount'] as num).toStringAsFixed(0)}  •  ${order['status']}'),
                  trailing: Text(order['created_at'] as String,
                      style: theme.textTheme.bodySmall),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(BuildContext context, String label, int value,
      IconData icon, Color color) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.bodyMedium),
                    Icon(icon, color: color),
                  ],
                ),
                const SizedBox(height: 12),
                Text(value.toString(),
                    style: TextStyle(
                        fontSize: 28, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _revenueCard(BuildContext context, String label, double value, Color color) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 8),
                Text('Rs ${value.toStringAsFixed(0)}',
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusIcon(String status) {
    final color = switch (status) {
      'pending_payment'      => Colors.grey,
      'pending_verification' => Colors.orange,
      'verified'             => Colors.blue,
      'preparing'            => Colors.purple,
      'out_for_delivery'     => Colors.teal,
      'delivered'            => Colors.green,
      'cancelled'            => Colors.red,
      _                      => Colors.grey,
    };
    return Container(
      width: 10, height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

/* ══════════════════════════════════════════════════════════
   ORDERS PAGE  –  list, filter, verify/reject, status update
   ══════════════════════════════════════════════════════════ */
class OrdersPage extends ConsumerStatefulWidget {
  const OrdersPage({super.key});
  @override
  ConsumerState<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends ConsumerState<OrdersPage> {
  List<Map<String, dynamic>> _orders = [];
  bool   _loading      = true;
  String _filterStatus = '';
  String _search       = '';

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final params = [];
      if (_filterStatus.isNotEmpty) params.add('status=$_filterStatus');
      if (_search.isNotEmpty)       params.add('search=$_search');
      final query = params.isEmpty ? '' : '?${params.join('&')}';

      final res = await apiClient.get('/admin/orders$query');
      _orders = (res['data'] as List).cast<Map<String, dynamic>>();
      setState(() => _loading = false);
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statuses = [
      '', 'pending_payment', 'pending_verification', 'verified',
      'preparing', 'out_for_delivery', 'delivered', 'cancelled'
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                      hintText:   'Search orders...',
                      prefixIcon: const Icon(Icons.search),
                      border:     OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10))),
                  onChanged: (v) { _search = v; _fetch(); },
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _filterStatus,
                hint:  const Text('All'),
                items: statuses
                    .map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s.isEmpty
                        ? 'All Statuses'
                        : s.replaceAll('_', ' ').capitalize)))
                    .toList(),
                onChanged: (v) { _filterStatus = v!; _fetch(); },
              ),
            ],
          ),
        ),
        const Divider(height: 0),

        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
            itemCount: _orders.length,
            itemBuilder: (_, i) {
              final o = _orders[i];
              final u = o['user'] as Map<String, dynamic>;
              return ListTile(
                leading:  _statusDot(o['status'] as String),
                title:    Text('Order #${o['id']}  –  ${u['name']}'),
                subtitle: Text(
                    'Rs ${(o['total_amount'] as num).toStringAsFixed(0)}  •  ${(o['status'] as String).replaceAll('_', ' ').capitalize}'),
                trailing: Row(children: [
                  if (o['status'] == 'pending_verification')
                    IconButton(
                        icon:      const Icon(Icons.check_circle, color: Colors.green),
                        onPressed: () => _verify(o['id'] as int)),
                  if (o['status'] == 'pending_verification')
                    IconButton(
                        icon:      const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () => _showRejectDialog(o['id'] as int)),
                  IconButton(
                      icon:      const Icon(Icons.chevron_right),
                      onPressed: () => _showOrderDetail(context, o)),
                ]),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _verify(int orderId) async {
    try {
      await apiClient.post('/admin/orders/$orderId/verify');
      _fetch();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'), behavior: SnackBarBehavior.floating));
      }
    }
  }

  void _showRejectDialog(int orderId) {
    final ctrl = TextEditingController();
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title:   const Text('Reject Payment'),
          content: TextField(
              controller: ctrl,
              decoration: const InputDecoration(hintText: 'Reason for rejection')),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await apiClient.post('/admin/orders/$orderId/reject',
                        body: {'reason': ctrl.text});
                    _fetch();
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Error: $e'),
                          behavior: SnackBarBehavior.floating));
                    }
                  }
                },
                child: const Text('Reject')),
          ],
        ));
  }

  void _showOrderDetail(BuildContext context, Map<String, dynamic> order) {
    final items   = order['items']   as List;
    final payment = order['payment'] as Map<String, dynamic>?;
    final user    = order['user']    as Map<String, dynamic>;
    final theme   = Theme.of(context);

    showGeneralDialog(
      context:     context,
      pageBuilder: (_, __, ___) => Scaffold(
        appBar: AppBar(title: Text('Order #${order['id']}')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                  child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Customer',
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                            Text('${user['name']}  (${user['email']})'),
                          ]))),
              const SizedBox(height: 12),

              Card(
                  child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Items',
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                            ...items.map((i) {
                              final item = i as Map<String, dynamic>;
                              final prod = item['product'] as Map<String, dynamic>;
                              return ListTile(
                                leading:  Text('x${item['quantity']}'),
                                title:    Text(prod['name'] as String),
                                trailing: Text(
                                    'Rs ${((item['price'] as num) * (item['quantity'] as int)).toStringAsFixed(0)}'),
                              );
                            }),
                            const Divider(),
                            Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Total',
                                      style: TextStyle(fontWeight: FontWeight.bold)),
                                  Text(
                                      'Rs ${(order['total_amount'] as num).toStringAsFixed(0)}',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.primary)),
                                ]),
                          ]))),
              const SizedBox(height: 12),

              if (payment != null)
                Card(
                    child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Payment',
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold)),
                              Text('Method: ${payment['method'] ?? 'N/A'}'),
                              Text('Reference: ${payment['reference'] ?? 'N/A'}'),
                              if (payment['screenshot_url'] != null) ...[
                                const SizedBox(height: 8),
                                const Text('Screenshot:',
                                    style: TextStyle(fontWeight: FontWeight.w500)),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    '${ApiClient.baseUrl.replaceAll('/api/v1', '')}${payment['screenshot_url']}',
                                    height:       200,
                                    fit:          BoxFit.contain,
                                    errorBuilder: (_, __, ___) =>
                                    const Placeholder(fallbackHeight: 200),
                                  ),
                                ),
                              ],
                            ]))),
              const SizedBox(height: 12),

              Card(
                  child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Update Status',
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Wrap(spacing: 8, children: [
                              for (final s in [
                                'preparing', 'out_for_delivery',
                                'delivered',  'cancelled'
                              ])
                                ElevatedButton(
                                  onPressed: () =>
                                      _updateStatus(context, order['id'] as int, s),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: s == 'cancelled'
                                        ? Colors.red
                                        : theme.colorScheme.primary,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: Text(s.replaceAll('_', ' ').capitalize),
                                ),
                            ]),
                          ]))),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateStatus(
      BuildContext context, int orderId, String status) async {
    Navigator.pop(context);
    try {
      await apiClient.put('/admin/orders/$orderId/status', body: {'status': status});
      _fetch();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'), behavior: SnackBarBehavior.floating));
      }
    }
  }

  Widget _statusDot(String status) {
    final color = switch (status) {
      'pending_payment'      => Colors.grey,
      'pending_verification' => Colors.orange,
      'verified'             => Colors.blue,
      'preparing'            => Colors.purple,
      'out_for_delivery'     => Colors.teal,
      'delivered'            => Colors.green,
      'cancelled'            => Colors.red,
      _                      => Colors.grey,
    };
    return Container(
        width: 12, height: 12,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle));
  }
}

/* ══════════════════════════════════════════════════════════
   PRODUCTS PAGE  –  list + add / edit / delete
   ══════════════════════════════════════════════════════════ */
class ProductsPage extends ConsumerStatefulWidget {
  const ProductsPage({super.key});
  @override
  ConsumerState<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends ConsumerState<ProductsPage> {
  List<Map<String, dynamic>> _products   = [];
  List<Map<String, dynamic>> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final pRes = await apiClient.get('/products?per_page=100');
      _products  = (pRes['data'] as List).cast<Map<String, dynamic>>();

      final cRes  = await apiClient.get('/categories');
      _categories = (cRes['categories'] as List).cast<Map<String, dynamic>>();

      setState(() => _loading = false);
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Products',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                  icon:      const Icon(Icons.add),
                  label:     const Text('Add Product'),
                  onPressed: () => _showProductForm(context, null)),
            ],
          ),
        ),
        const Divider(height: 0),

        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
            itemCount: _products.length,
            itemBuilder: (_, i) {
              final p = _products[i];
              return ListTile(
                leading: p['image_url'] != null
                    ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                        '${ApiClient.baseUrl.replaceAll('/api/v1', '')}${p['image_url']}',
                        width: 48, height: 48, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                        const Icon(Icons.fastfood)))
                    : const Icon(Icons.fastfood),
                title:    Text(p['name'] as String),
                subtitle: Text(
                    'Rs ${(p['price'] as num).toStringAsFixed(0)}  •  ${(p['category'] as Map<String, dynamic>)['name']}'),
                trailing: Row(children: [
                  IconButton(
                      icon:      const Icon(Icons.edit),
                      onPressed: () => _showProductForm(context, p)),
                  IconButton(
                      icon:      const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _delete(p['id'] as int)),
                ]),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showProductForm(BuildContext context, Map<String, dynamic>? existing) {
    final nameCtrl  = TextEditingController(text: existing?['name']);
    final priceCtrl = TextEditingController(
        text: existing != null
            ? (existing['price'] as num).toStringAsFixed(0)
            : '');
    final descCtrl     = TextEditingController(text: existing?['description']);
    int? selectedCatId = existing?['category'] != null
        ? (existing?['category'] as Map<String, dynamic>)['id'] as int
        : null;

    showGeneralDialog(
      context:     context,
      pageBuilder: (_, __, ___) => Scaffold(
        appBar: AppBar(
            title: Text(existing != null ? 'Edit Product' : 'Add Product')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: StatefulBuilder(
            builder: (ctx, setS) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                        labelText: 'Product Name',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 16),

                TextField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        labelText: 'Price (Rs)',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 16),

                TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 16),

                DropdownButtonFormField<int>(
                  value: selectedCatId,
                  decoration: InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10))),
                  items: _categories
                      .map((c) => DropdownMenuItem(
                      value: c['id'] as int,
                      child: Text(c['name'] as String)))
                      .toList(),
                  onChanged: (v) => setS(() => selectedCatId = v),
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: () async {
                    final body = {
                      'name':        nameCtrl.text,
                      'price':       priceCtrl.text,
                      'description': descCtrl.text,
                      'category_id': selectedCatId,
                    };
                    try {
                      if (existing != null) {
                        await apiClient.put('/products/${existing['id']}',
                            body: body);
                      } else {
                        await apiClient.post('/products', body: body);
                      }
                      Navigator.pop(ctx);
                      _fetch();
                    } catch (e) {
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                          content: Text('Error: $e'),
                          behavior: SnackBarBehavior.floating));
                    }
                  },
                  child: Text(existing != null ? 'Update' : 'Create',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _delete(int id) async {
    try {
      await apiClient.delete('/products/$id');
      _fetch();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'), behavior: SnackBarBehavior.floating));
      }
    }
  }
}

/* ══════════════════════════════════════════════════════════
   USERS PAGE  –  list, search, block/unblock
   ══════════════════════════════════════════════════════════ */
class UsersPage extends ConsumerStatefulWidget {
  const UsersPage({super.key});
  @override
  ConsumerState<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends ConsumerState<UsersPage> {
  List<Map<String, dynamic>> _users = [];
  bool   _loading = true;
  String _search  = '';

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final query = _search.isNotEmpty ? '?search=$_search' : '';
      final res   = await apiClient.get('/admin/users$query');
      _users      = (res['data'] as List).cast<Map<String, dynamic>>();
      setState(() => _loading = false);
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
                hintText:   'Search users...',
                prefixIcon: const Icon(Icons.search),
                border:     OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10))),
            onChanged: (v) { _search = v; _fetch(); },
          ),
        ),
        const Divider(height: 0),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
            itemCount: _users.length,
            itemBuilder: (_, i) {
              final u      = _users[i];
              final active = u['is_active'] as bool;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text((u['name'] as String)[0],
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                title:    Text(u['name'] as String),
                subtitle: Text(
                    '${u['email']}  •  ${u['orders_count'] ?? 0} orders'),
                trailing: Row(children: [
                  Chip(
                    label: Text(active ? 'Active' : 'Blocked'),
                    color: MaterialStateProperty.all(active
                        ? Colors.green.shade100
                        : Colors.red.shade100),
                    labelStyle: TextStyle(
                        color: active
                            ? Colors.green.shade800
                            : Colors.red.shade800),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.block,
                        color: active ? Colors.red : Colors.green),
                    onPressed: () => _toggleBlock(u['id'] as int),
                  ),
                ]),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _toggleBlock(int userId) async {
    try {
      await apiClient.post('/admin/users/$userId/toggle-block');
      _fetch();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'), behavior: SnackBarBehavior.floating));
      }
    }
  }
}

/* ══════════════════════════════════════════════════════════
   UTILITY  –  String.capitalize
   ══════════════════════════════════════════════════════════ */
extension StringExt on String {
  String get capitalize => isEmpty ? '' : this[0].toUpperCase() + substring(1);
}