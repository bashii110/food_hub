import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class ManualPaymentScreen extends StatefulWidget {
  final double amount;
  final String paymentMethod;
  final String accountTitle;
  final String accountNumber;
  final Function(bool success, String? txnImagePath) onPaymentComplete;

  const ManualPaymentScreen({
    super.key,
    required this.amount,
    required this.paymentMethod,
    required this.accountTitle,
    required this.accountNumber,
    required this.onPaymentComplete,
  });

  @override
  State<ManualPaymentScreen> createState() => _ManualPaymentScreenState();
}

class _ManualPaymentScreenState extends State<ManualPaymentScreen> {
  File? _transactionImage;

  /// Pick an image using camera or gallery
  // Function to pick image from gallery
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _transactionImage = File(pickedFile.path);
      });
    } else {
      print('No image selected.');
    }
  }


  /// Copy account number to clipboard
  void _copyAccountNumber() {
    Clipboard.setData(ClipboardData(text: widget.accountNumber));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Account number copied to clipboard')),
    );
  }

  /// Manual confirmation dialog
  void _confirmPayment() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Payment'),
        content: const Text('Are you sure you have sent the payment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onPaymentComplete(true, _transactionImage?.path);
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

            // QR Code
            Center(
              child: QrImageView(
                data: widget.accountNumber,
                version: QrVersions.auto,
                size: 200,
              ),
            ),
            const SizedBox(height: 24),

            // Account Details
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Account Title', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(widget.accountTitle),
                    const SizedBox(height: 12),
                    Text('Account Number', style: TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(widget.accountNumber),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: _copyAccountNumber,
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Amount to Send', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Rs ${widget.amount.toStringAsFixed(2)}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Upload Transaction Image
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Upload Payment Proof', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Select Image'),
                    ),
                    const SizedBox(height: 12),
                    if (_transactionImage != null)
                      Image.file(_transactionImage!, height: 200),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Confirm Button
            ElevatedButton.icon(
              onPressed: _confirmPayment,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('I have completed the payment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
