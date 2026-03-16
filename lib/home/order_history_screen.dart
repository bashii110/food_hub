import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/api_client.dart';
import '../../data/services/order_service.dart';
import '../presentation/payment/payment_method_screen.dart';
import '../presentation/providers/auth_provider.dart';

// ── Provider ──────────────────────────────────────────────────
final userOrdersProvider =
FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState.value?.user == null) return [];
  return OrderService.getMyOrders();
});

// ── Screen ────────────────────────────────────────────────────
class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(userOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(userOrdersProvider),
          ),
        ],
      ),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(userOrdersProvider),
        ),
        data: (orders) {
          if (orders.isEmpty) {
            return const _EmptyOrders();
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(userOrdersProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: orders.length,
              itemBuilder: (ctx, i) => _OrderCard(
                order: orders[i],
                onChanged: () => ref.invalidate(userOrdersProvider),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Order Card ────────────────────────────────────────────────
class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onChanged;
  const _OrderCard({required this.order, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = order['status'] as String? ?? 'unknown';
    final paymentMethod = order['payment_method'] as String? ?? '';
    final isCod = paymentMethod == 'cod';
    final needsProof = status == 'pending_payment' && !isCod;
    final isCancellable =
        status == 'pending_payment' || status == 'pending_verification';
    final items = (order['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Order #${order['id']}',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                _StatusBadge(status: status),
              ],
            ),
            const SizedBox(height: 8),

            // ── Date & Amount ──
            Text(
              '${order['created_at'] ?? ''}  •  PKR ${_fmt(order['total_amount'])}',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 10),

            // ── Items ──
            if (items.isNotEmpty)
              ...items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Text('${item['quantity']}x ',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600)),
                    Expanded(
                      child: Text(
                        item['product_name'] as String? ??
                            (item['product'] as Map?)?['name'] as String? ??
                            'Item',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      'PKR ${_fmt(item['price'])}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              )),

            const Divider(height: 20),

            // ── Amounts ──
            _AmountRow(
                label: 'Subtotal',
                value: 'PKR ${_fmt(order['subtotal'])}'),
            _AmountRow(
                label: 'Delivery Fee',
                value: 'PKR ${_fmt(order['delivery_fee'])}'),
            _AmountRow(
                label: 'Total',
                value: 'PKR ${_fmt(order['total_amount'])}',
                bold: true),

            const SizedBox(height: 12),

            // ── Actions ──
            if (needsProof)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PaymentMethodScreen(
                        orderId: order['id'] as int,
                        amount:
                        (order['total_amount'] as num).toDouble(),
                      ),
                    ),
                  ).then((_) => onChanged()),
                  icon: const Icon(Icons.upload_file, size: 18),
                  label: const Text('Upload Payment Proof'),
                ),
              ),

            if (isCancellable) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _cancelOrder(context, order['id'] as int, onChanged),
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('Cancel Order'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                    side: BorderSide(
                        color: Theme.of(context).colorScheme.error),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _cancelOrder(
      BuildContext context, int orderId, VoidCallback onChanged) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => _CancelDialog(),
    );
    if (reason == null) return;

    try {
      await OrderService.cancelOrder(orderId, reason: reason);
      onChanged();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Order cancelled'),
              backgroundColor: Colors.orange),
        );
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message), backgroundColor: Colors.red));
      }
    }
  }

  String _fmt(dynamic v) {
    if (v == null) return '0';
    return (double.tryParse(v.toString()) ?? 0).toStringAsFixed(0);
  }
}

// ── Status Badge ──────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  static const _colors = {
    'pending_payment': Colors.orange,
    'pending_verification': Colors.amber,
    'verified': Colors.blue,
    'preparing': Colors.purple,
    'out_for_delivery': Colors.teal,
    'delivered': Colors.green,
    'cancelled': Colors.red,
  };

  static const _icons = {
    'pending_payment': Icons.payment,
    'pending_verification': Icons.hourglass_empty,
    'verified': Icons.check_circle_outline,
    'preparing': Icons.restaurant,
    'out_for_delivery': Icons.local_shipping,
    'delivered': Icons.check_circle,
    'cancelled': Icons.cancel,
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[status] ?? Colors.grey;
    final icon = _icons[status] ?? Icons.receipt;
    final label = status.replaceAll('_', ' ').toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 10, color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ── Cancel Dialog ─────────────────────────────────────────────
class _CancelDialog extends StatefulWidget {
  @override
  State<_CancelDialog> createState() => _CancelDialogState();
}

class _CancelDialogState extends State<_CancelDialog> {
  final _ctrl = TextEditingController();
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Cancel Order'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Are you sure? This cannot be undone.'),
        const SizedBox(height: 12),
        TextField(
          controller: _ctrl,
          decoration: const InputDecoration(
              labelText: 'Reason (optional)', border: OutlineInputBorder()),
        ),
      ],
    ),
    actions: [
      TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Keep Order')),
      FilledButton(
        onPressed: () => Navigator.pop(context, _ctrl.text.trim()),
        style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error),
        child: const Text('Cancel Order'),
      ),
    ],
  );
}

// ── Amount Row ────────────────────────────────────────────────
class _AmountRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _AmountRow(
      {required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: bold ? const TextStyle(fontWeight: FontWeight.bold) : null),
        Text(value,
            style: bold ? const TextStyle(fontWeight: FontWeight.bold) : null),
      ],
    ),
  );
}

// ── Empty State ───────────────────────────────────────────────
class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders();
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.receipt_long,
            size: 80,
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withOpacity(0.2)),
        const SizedBox(height: 16),
        const Text('No orders yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('Your order history will appear here',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    ),
  );
}

// ── Error View ────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}