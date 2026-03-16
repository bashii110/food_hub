import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/api_client.dart';

// ══════════════════════════════════════════════════════════════
// ADMIN ORDERS PROVIDER
// ══════════════════════════════════════════════════════════════
final adminOrdersProvider =
FutureProvider.family<Map<String, dynamic>, String?>(
        (ref, status) async {
      try {
        final query =
        status != null && status != 'all' ? '?status=$status' : '';
        return await apiClient.get('/admin/orders$query');
      } catch (e) {
        debugPrint('Error loading admin orders: $e');
        return {'data': []};
      }
    });

// ══════════════════════════════════════════════════════════════
// ADMIN ORDERS SCREEN
// ══════════════════════════════════════════════════════════════
class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() =>
      _AdminOrdersScreenState();
}

class _AdminOrdersScreenState
    extends ConsumerState<AdminOrdersScreen> {
  String _selectedStatus = 'all';

  final List<Map<String, String>> _statusFilters = [
    {'value': 'all', 'label': 'All'},
    {'value': 'pending_verification', 'label': '⏳ Pending'},
    {'value': 'verified', 'label': 'Verified'},
    {'value': 'preparing', 'label': 'Preparing'},
    {'value': 'out_for_delivery', 'label': 'Delivery'},
    {'value': 'delivered', 'label': 'Delivered'},
    {'value': 'cancelled', 'label': 'Cancelled'},
  ];

  Color _statusColor(String status) => switch (status) {
    'pending_payment' => Colors.grey,
    'pending_verification' => Colors.amber.shade700,
    'verified' => Colors.blue,
    'preparing' => Colors.purple,
    'out_for_delivery' => Colors.teal,
    'delivered' => Colors.green,
    'cancelled' => Colors.red,
    _ => Colors.grey,
  };

  Future<void> _verifyPayment(int orderId) async {
    try {
      await apiClient.post('/admin/orders/$orderId/verify');
      ref.invalidate(adminOrdersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Payment verified ✓'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Future<void> _rejectPayment(int orderId) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject Payment'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Reason for rejection',
            hintText: 'e.g. Wrong amount, blurry screenshot…',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (reason != null && reason.trim().isNotEmpty) {
      try {
        await apiClient.post('/admin/orders/$orderId/reject',
            body: {'reason': reason.trim()});
        ref.invalidate(adminOrdersProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Payment rejected'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ));
        }
      }
    }
  }

  /// Opens a full-screen dialog to zoom into the payment screenshot.
  void _viewScreenshot(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(
              child: Center(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.broken_image,
                        color: Colors.white54, size: 64),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync =
    ref.watch(adminOrdersProvider(_selectedStatus));
    final theme = Theme.of(context);

    return Column(
      children: [
        // ── Status filter chips ───────────────────────────
        Container(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _statusFilters.map((f) {
                final selected = _selectedStatus == f['value'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(f['label']!),
                    selected: selected,
                    onSelected: (_) =>
                        setState(() => _selectedStatus = f['value']!),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        const Divider(height: 1),

        // ── Orders list ───────────────────────────────────
        Expanded(
          child: ordersAsync.when(
            loading: () =>
            const Center(child: CircularProgressIndicator()),

            error: (e, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 64, color: Colors.red),
                  const SizedBox(height: 12),
                  Text('Failed to load orders',
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () =>
                        ref.invalidate(adminOrdersProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),

            data: (response) {
              final orders =
                  (response['data'] as List<dynamic>?) ?? [];

              if (orders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long,
                          size: 64,
                          color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text('No orders found',
                          style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 16)),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(adminOrdersProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) =>
                  const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final order =
                    orders[i] as Map<String, dynamic>;
                    final status =
                        order['status'] as String? ?? '';
                    final isPending =
                        status == 'pending_verification';

                    // Payment & screenshot
                    final payment = order['payment']
                    as Map<String, dynamic>?;
                    final screenshotUrl =
                    payment?['screenshot_url'] as String?;
                    final reference =
                    payment?['reference'] as String?;
                    final paymentMethod =
                    payment?['method'] as String?;

                    // DB stores: "payment_proofs/2026/03/file.jpg"
                    // We need:   "http://192.168.100.21:8000/storage/payment_proofs/2026/03/file.jpg"
                    //
                    // serverRoot = strip everything after host:port
                    // e.g. "http://192.168.100.21:8000/v1/api" → "http://192.168.100.21:8000"
                    final String? fullScreenshotUrl;
                    if (screenshotUrl == null || screenshotUrl.isEmpty) {
                      fullScreenshotUrl = null;
                    } else {
                      // Always extract just scheme+host+port from baseUrl
                      final parsedBase = Uri.parse(ApiClient.baseUrl);
                      final serverRoot =
                          '${parsedBase.scheme}://${parsedBase.host}:${parsedBase.port}';

                      if (screenshotUrl.startsWith('http')) {
                        // Full URL stored — extract path only, use correct host
                        final path = Uri.tryParse(screenshotUrl)?.path ?? '';
                        fullScreenshotUrl = '$serverRoot$path';
                      } else if (screenshotUrl.startsWith('/storage/') ||
                          screenshotUrl.startsWith('storage/')) {
                        // Has storage prefix already
                        final path = screenshotUrl.startsWith('/')
                            ? screenshotUrl
                            : '/$screenshotUrl';
                        fullScreenshotUrl = '$serverRoot$path';
                      } else {
                        // Raw path: "payment_proofs/2026/03/file.jpg"
                        fullScreenshotUrl =
                        '$serverRoot/storage/$screenshotUrl';
                      }
                    }

                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: ExpansionTile(
                        // ── Tile header ─────────────────
                        leading: CircleAvatar(
                          backgroundColor: _statusColor(status),
                          child: Text(
                            '#${order['id']}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          order['user']?['name'] as String? ??
                              'Unknown',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              status
                                  .replaceAll('_', ' ')
                                  .toUpperCase(),
                              style: TextStyle(
                                color: _statusColor(status),
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              'Rs ${order['total_amount']}  •  ${paymentMethod?.toUpperCase() ?? 'N/A'}',
                              style: const TextStyle(
                                  fontSize: 12),
                            ),
                          ],
                        ),
                        // Badge for pending verification
                        trailing: isPending
                            ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius:
                            BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.amber.shade300),
                          ),
                          child: Text(
                            'Review',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade800,
                            ),
                          ),
                        )
                            : null,

                        // ── Expanded content ────────────
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                                16, 0, 16, 16),
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                const Divider(),

                                // ── Order items ──────────
                                const Text('Items',
                                    style: TextStyle(
                                        fontWeight:
                                        FontWeight.bold)),
                                const SizedBox(height: 6),
                                ...((order['items']
                                as List<dynamic>?) ??
                                    [])
                                    .map((item) {
                                  final i = item
                                  as Map<String, dynamic>;
                                  return Padding(
                                    padding: const EdgeInsets
                                        .only(bottom: 4),
                                    child: Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment
                                          .spaceBetween,
                                      children: [
                                        Text(
                                            '${i['product']?['name']} x${i['quantity']}'),
                                        Text(
                                            'Rs ${i['price']}'),
                                      ],
                                    ),
                                  );
                                }),

                                const Divider(height: 20),

                                // ── Phone number ─────────
                                // Order stores its own phone, fallback to user phone
                                Builder(builder: (context) {
                                  final phone =
                                  (order['phone'] as String?)?.isNotEmpty == true
                                      ? order['phone'] as String
                                      : order['user']?['phone'] as String?;
                                  if (phone == null || phone.isEmpty) {
                                    return const SizedBox.shrink();
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(children: [
                                      const Icon(Icons.phone_outlined,
                                          size: 16, color: Colors.grey),
                                      const SizedBox(width: 6),
                                      Text(phone,
                                          style: const TextStyle(fontSize: 13)),
                                    ]),
                                  );
                                }),

                                // ── Delivery address ─────
                                Row(children: [
                                  const Icon(
                                      Icons.location_on_outlined,
                                      size: 16,
                                      color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      order['delivery_address']
                                      as String? ??
                                          '',
                                      style: const TextStyle(
                                          fontSize: 13),
                                    ),
                                  ),
                                ]),

                                const SizedBox(height: 16),

                                // ══════════════════════════
                                // PAYMENT SCREENSHOT SECTION
                                // ══════════════════════════
                                if (fullScreenshotUrl != null) ...[
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isPending
                                          ? Colors.amber.shade50
                                          : Colors.grey.shade50,
                                      borderRadius:
                                      BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isPending
                                            ? Colors.amber.shade300
                                            : Colors.grey.shade200,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        // Header row — Flexible prevents overflow
                                        Row(children: [
                                          Icon(
                                            Icons.receipt_outlined,
                                            size: 16,
                                            color: isPending
                                                ? Colors.amber.shade700
                                                : Colors.grey,
                                          ),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              'Payment Screenshot',
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: isPending
                                                    ? Colors.amber.shade800
                                                    : Colors.grey.shade700,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          // Tap to zoom icon (no text = no overflow)
                                          Icon(
                                            Icons.zoom_in,
                                            size: 16,
                                            color: Colors.grey.shade400,
                                          ),
                                        ]),

                                        if (reference != null &&
                                            reference
                                                .isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Row(children: [
                                            const Icon(Icons.tag,
                                                size: 13,
                                                color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Ref: $reference',
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey),
                                            ),
                                          ]),
                                        ],

                                        const SizedBox(height: 10),

                                        // Screenshot image — tap to zoom
                                        GestureDetector(
                                          onTap: () => _viewScreenshot(
                                              context,
                                              fullScreenshotUrl!),
                                          child: ClipRRect(
                                            borderRadius:
                                            BorderRadius.circular(
                                                8),
                                            child: Stack(
                                              alignment:
                                              Alignment.center,
                                              children: [
                                                Image.network(
                                                  fullScreenshotUrl,
                                                  width:
                                                  double.infinity,
                                                  height: 220,
                                                  fit: BoxFit.cover,
                                                  loadingBuilder: (ctx,
                                                      child,
                                                      progress) {
                                                    if (progress ==
                                                        null) {
                                                      return child;
                                                    }
                                                    return Container(
                                                      height: 220,
                                                      color: Colors
                                                          .grey
                                                          .shade200,
                                                      child:
                                                      const Center(
                                                        child:
                                                        CircularProgressIndicator(),
                                                      ),
                                                    );
                                                  },
                                                  errorBuilder: (_,
                                                      __,
                                                      ___) =>
                                                      Container(
                                                        height: 120,
                                                        color: Colors
                                                            .grey.shade200,
                                                        child: Column(
                                                          mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                          children: [
                                                            const Icon(
                                                                Icons
                                                                    .broken_image_outlined,
                                                                size: 40,
                                                                color: Colors
                                                                    .grey),
                                                            const SizedBox(
                                                                height: 6),
                                                            Text(
                                                              'Could not load image',
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .grey
                                                                      .shade600,
                                                                  fontSize:
                                                                  12),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                ),
                                                // Zoom icon overlay
                                                Positioned(
                                                  bottom: 8,
                                                  right: 8,
                                                  child: Container(
                                                    padding:
                                                    const EdgeInsets
                                                        .all(4),
                                                    decoration:
                                                    BoxDecoration(
                                                      color: Colors
                                                          .black54,
                                                      borderRadius:
                                                      BorderRadius
                                                          .circular(
                                                          6),
                                                    ),
                                                    child: const Icon(
                                                      Icons
                                                          .zoom_in_rounded,
                                                      color:
                                                      Colors.white,
                                                      size: 18,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ] else if (isPending) ...[
                                  // No screenshot uploaded yet
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius:
                                      BorderRadius.circular(8),
                                      border: Border.all(
                                          color:
                                          Colors.orange.shade200),
                                    ),
                                    child: Row(children: [
                                      Icon(Icons.warning_amber,
                                          color:
                                          Colors.orange.shade600,
                                          size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        'No payment screenshot uploaded yet',
                                        style: TextStyle(
                                          color:
                                          Colors.orange.shade800,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ]),
                                  ),
                                  const SizedBox(height: 12),
                                ],

                                // ── Verify / Reject buttons ──
                                if (isPending) ...[
                                  Row(children: [
                                    Expanded(
                                      child: FilledButton.icon(
                                        onPressed: () =>
                                            _verifyPayment(
                                                order['id'] as int),
                                        icon: const Icon(Icons.check,
                                            size: 18),
                                        label:
                                        const Text('Verify Payment'),
                                        style: FilledButton.styleFrom(
                                          backgroundColor:
                                          Colors.green,
                                          padding: const EdgeInsets
                                              .symmetric(vertical: 12),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () =>
                                            _rejectPayment(
                                                order['id'] as int),
                                        icon: const Icon(Icons.close,
                                            size: 18),
                                        label: const Text('Reject'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red,
                                          side: const BorderSide(
                                              color: Colors.red),
                                          padding: const EdgeInsets
                                              .symmetric(vertical: 12),
                                        ),
                                      ),
                                    ),
                                  ]),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}