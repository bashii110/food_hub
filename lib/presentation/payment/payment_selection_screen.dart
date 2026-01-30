import 'package:flutter/material.dart';
import 'package:food_hub/presentation/payment/manualpayment_screen.dart';
import 'instant_payment_screen.dart'; // Add this

class PaymentSelectionScreen extends StatelessWidget {
  final double amount;

  const PaymentSelectionScreen({
    super.key,
    required this.amount,
  });

  void _handlePaymentComplete(
      BuildContext context,
      bool success,
      String? transactionId,
      String paymentMethod,
      ) {
    if (success) {
      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 32),
              SizedBox(width: 12),
              Text('Payment Successful'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Payment Method: $paymentMethod'),
              const SizedBox(height: 8),
              if (transactionId != null) ...[
                Text('Transaction ID: $transactionId'),
                const SizedBox(height: 8),
              ],
              Text('Amount: Rs ${amount.toStringAsFixed(2)}'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.green.shade700,
                        size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your order has been placed successfully!',
                        style: TextStyle(
                          color: Colors.green.shade900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Close payment selection
                Navigator.of(context).pop(); // Close cart

                // TODO: Navigate to order confirmation screen
                // TODO: Clear cart
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } else {
      // Show failure message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Text('Payment failed or cancelled'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () {
              // User can try again
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Payment Method'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Amount Display
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'Total Amount',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Rs ${amount.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Payment Methods Title
            Text(
              'Choose Payment Method',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // Instant Payment Notice
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Real instant payments - Pay via browser or scan QR code!',
                      style: TextStyle(
                        color: Colors.green.shade900,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // JazzCash Payment Option (Instant - Real Payment)
            _PaymentMethodCard(
              icon: Icons.payment,
              title: 'JazzCash',
              subtitle: 'Pay via browser or QR code',
              color: Colors.red,
              badge: 'INSTANT PAY',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ManualPaymentScreen(
                      amount: amount,
                      paymentMethod: 'JazzCash',
                      onPaymentComplete: (success, transactionId) {
                        _handlePaymentComplete(
                          context,
                          success,
                          transactionId,
                          'JazzCash',
                        );
                      }, accountTitle: 'Bashir Ahmed', accountNumber: '03193009345',
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // Easypaisa Payment Option (Instant - Real Payment)
            _PaymentMethodCard(
              icon: Icons.account_balance_wallet,
              title: 'Easypaisa',
              subtitle: 'Pay via browser or QR code',
              color: Colors.green,
              badge: 'INSTANT PAY',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ManualPaymentScreen(
                      amount: amount,
                      paymentMethod: 'JazzCash',
                      onPaymentComplete: (success, transactionId) {
                        _handlePaymentComplete(
                          context,
                          success,
                          transactionId,
                          'JazzCash',
                        );
                      }, accountTitle: 'Bashir Ahmed', accountNumber: '03193009345',
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // Cash on Delivery Option
            _PaymentMethodCard(
              icon: Icons.money,
              title: 'Cash on Delivery',
              subtitle: 'Pay when you receive your order',
              color: Colors.orange,
              onTap: () {
                // Handle COD
                _handlePaymentComplete(
                  context,
                  true,
                  'COD-${DateTime.now().millisecondsSinceEpoch}',
                  'Cash on Delivery',
                );
              },
            ),

            const SizedBox(height: 24),

            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline,
                          color: Colors.orange.shade700),
                      const SizedBox(width: 12),
                      Text(
                        'How to Enable Real Payments',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '1. Register for merchant accounts:\n'
                        '   • JazzCash: sandbox.jazzcash.com.pk\n'
                        '   • Easypaisa: easypay.easypaisa.com.pk\n\n'
                        '2. Get your merchant credentials\n\n'
                        '3. Update payment service files with credentials\n\n'
                        '4. Replace MockPaymentScreen with real payment screens\n\n'
                        'See PAYMENT_INTEGRATION_GUIDE.md for details',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String? badge;
  final VoidCallback onTap;

  const _PaymentMethodCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              badge!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}