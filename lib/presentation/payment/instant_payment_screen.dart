import 'dart:io';

import 'package:flutter/material.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:qr_flutter/qr_flutter.dart';

class InstantPaymentScreen extends StatefulWidget {
  final double amount;
  final String paymentMethod; // 'JazzCash' or 'Easypaisa'
  final Function(bool success, String? transactionId) onPaymentComplete;

  const InstantPaymentScreen({
    super.key,
    required this.amount,
    required this.paymentMethod,
    required this.onPaymentComplete,
  });

  // Payment constants
  static const String jazzCashAccount = '03193009345';
  static const String easypaisaAccount = '03193009345';

  @override
  State<InstantPaymentScreen> createState() => _InstantPaymentScreenState();
}

class _InstantPaymentScreenState extends State<InstantPaymentScreen> {
  /// Open app directly via Android package
  void _openPaymentApp() {
    if (!Platform.isAndroid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('App launch only supported on Android')),
      );
      return;
    }

    String packageName;
    if (widget.paymentMethod == 'JazzCash') {
      packageName = 'pk.jazzcash.app'; // JazzCash package name
    } else if (widget.paymentMethod == 'Easypaisa') {
      packageName = 'com.easypaisa.consumerapp'; // Easypaisa package name
    } else {
      return;
    }

    try {
      final intent = AndroidIntent(
        package: packageName,
      );
      intent.launch();
      _showPaymentConfirmationDialog();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
            Text('${widget.paymentMethod} app could not be opened.')),
      );
    }
  }

  /// QR code data
  String _getQRData() {
    if (widget.paymentMethod == 'JazzCash') {
      return 'jazzcash://pay?account=${InstantPaymentScreen.jazzCashAccount}&amount=${widget.amount.toInt()}';
    } else if (widget.paymentMethod == 'Easypaisa') {
      return 'easypaisa://pay?account=${InstantPaymentScreen.easypaisaAccount}&amount=${widget.amount.toInt()}';
    }
    return 'payment://amount=${widget.amount.toInt()}';
  }

  /// Manual confirmation dialog
  void _showPaymentConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Did you complete the payment?'),
        content: const Text(
            'Please confirm if you have successfully completed the payment.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              widget.onPaymentComplete(false, null);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final txnId = 'TXN_${DateTime.now().millisecondsSinceEpoch}';
              Navigator.pop(context);
              Navigator.pop(context);
              widget.onPaymentComplete(true, txnId);
            },
            child: const Text('Yes, Paid'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.paymentMethod == 'JazzCash' ? Colors.red : Colors.green;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.paymentMethod} Payment'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            widget.onPaymentComplete(false, null);
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    widget.paymentMethod == 'JazzCash'
                        ? Icons.payment
                        : Icons.account_balance_wallet,
                    size: 64,
                    color: color,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.paymentMethod,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Amount
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text('Amount to Pay',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Text('Rs ${widget.amount.toStringAsFixed(2)}',
                        style: Theme.of(context)
                            .textTheme
                            .displaySmall
                            ?.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                        )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Open App button
            ElevatedButton.icon(
              onPressed: _openPaymentApp,
              icon: const Icon(Icons.mobile_friendly),
              label: Text('Open ${widget.paymentMethod} App'),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 32),

            // QR Code
            Text('Scan QR Code to Pay',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: QrImageView(
                  data: _getQRData(),
                  version: QrVersions.auto,
                  size: 200.0,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Payment Details
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 12),
                        Text('Payment Details',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            )),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                        'Account: ${widget.paymentMethod == 'JazzCash' ? InstantPaymentScreen.jazzCashAccount : InstantPaymentScreen.easypaisaAccount}',
                        style: TextStyle(color: Colors.blue.shade900)),
                    const SizedBox(height: 4),
                    Text('Amount: Rs ${widget.amount.toStringAsFixed(2)}',
                        style: TextStyle(color: Colors.blue.shade900)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Manual confirmation
            OutlinedButton.icon(
              onPressed: _showPaymentConfirmationDialog,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('I have completed the payment'),
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color),
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
