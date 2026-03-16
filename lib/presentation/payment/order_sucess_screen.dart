import 'package:flutter/material.dart';
import '../../home/homescreen.dart';
import '../providers/cart_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OrderSuccessScreen extends ConsumerWidget {
  final int orderId;
  final String paymentMethod;
  final bool isCashOnDelivery;

  const OrderSuccessScreen({
    super.key,
    required this.orderId,
    required this.paymentMethod,
    this.isCashOnDelivery = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      // Prevent going back to checkout/cart with the back button
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          // ✅ FIX: SingleChildScrollView prevents overflow on small screens
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 32),

                // ── SUCCESS ICON ─────────────────────────────
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green.shade600,
                    size: 80,
                  ),
                ),

                const SizedBox(height: 32),

                // ── TITLE ────────────────────────────────────
                Text(
                  isCashOnDelivery
                      ? 'Order Placed Successfully!'
                      : 'Payment Proof Submitted!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // ── ORDER ID CARD ────────────────────────────
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          'Order ID',
                          style:
                          Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '#$orderId',
                          style: Theme.of(context)
                              .textTheme
                              .displaySmall
                              ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            paymentMethod,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── WHAT HAPPENS NEXT ────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isCashOnDelivery
                        ? Colors.orange.shade50
                        : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isCashOnDelivery
                          ? Colors.orange.shade200
                          : Colors.blue.shade200,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: isCashOnDelivery
                                ? Colors.orange.shade700
                                : Colors.blue.shade700,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'What happens next?',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isCashOnDelivery
                                  ? Colors.orange.shade900
                                  : Colors.blue.shade900,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (isCashOnDelivery) ...[
                        const _StatusStep(
                            number: '1',
                            text: 'Your order is being prepared'),
                        const _StatusStep(
                            number: '2',
                            text: 'We will deliver it to your address'),
                        const _StatusStep(
                            number: '3',
                            text: 'Pay cash when you receive the order'),
                      ] else ...[
                        const _StatusStep(
                            number: '1',
                            text:
                            'Admin will verify your payment (usually within 24 hours)'),
                        const _StatusStep(
                            number: '2',
                            text:
                            'Once verified, your order will be prepared'),
                        const _StatusStep(
                            number: '3',
                            text: 'We will deliver it to your address'),
                      ],
                    ],
                  ),
                ),

                // ✅ FIX: Fixed gap instead of Spacer (Spacer breaks in scrollable)
                const SizedBox(height: 40),

                // ── ACTION BUTTONS ───────────────────────────
                ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to home and let the user go to order history
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                          (route) => false,
                    );
                  },
                  icon: const Icon(Icons.receipt_long),
                  label: const Text('View My Orders'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                          (route) => false,
                    );
                  },
                  icon: const Icon(Icons.home),
                  label: const Text('Back to Home'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// STATUS STEP WIDGET
// ══════════════════════════════════════════════════════════════
class _StatusStep extends StatelessWidget {
  final String number;
  final String text;

  const _StatusStep({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                text,
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}