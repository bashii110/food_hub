import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/services/api_client.dart';
import '../../data/services/order_service.dart';
import 'order_sucess_screen.dart';

class PaymentProofUploadScreen extends StatefulWidget {
  final int orderId;
  final double amount;
  final String paymentMethod;
  final String accountNumber;
  final String accountName;

  const PaymentProofUploadScreen({
    super.key,
    required this.orderId,
    required this.amount,
    required this.paymentMethod,
    required this.accountNumber,
    required this.accountName,
  });

  @override
  State<PaymentProofUploadScreen> createState() =>
      _PaymentProofUploadScreenState();
}

class _PaymentProofUploadScreenState extends State<PaymentProofUploadScreen> {
  final _referenceController = TextEditingController();
  File? _imageFile;
  bool _uploading = false;

  @override
  void dispose() {
    _referenceController.dispose();
    super.dispose();
  }

  Color get _paymentColor =>
      widget.paymentMethod.toLowerCase().contains('jazz')
          ? Colors.red
          : widget.paymentMethod.toLowerCase().contains('easy')
          ? Colors.green
          : Colors.blue;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (picked != null && mounted) {
        setState(() => _imageFile = File(picked.path));
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Could not pick image: $e', Colors.red);
      }
    }
  }

  Future<void> _uploadProof() async {
    if (_imageFile == null) {
      _showSnack('Please select a payment screenshot first', Colors.orange);
      return;
    }

    setState(() => _uploading = true);

    try {
      final bytes = await _imageFile!.readAsBytes();

      // ✅ FIX: field name is 'screenshot' (matching backend validation)
      await OrderService.uploadPaymentProof(
        orderId: widget.orderId,
        imageBytes: bytes.toList(),
        reference: _referenceController.text.trim().isEmpty
            ? null
            : _referenceController.text.trim(),
        method: _methodKey(widget.paymentMethod),
      );

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => OrderSuccessScreen(
              orderId: widget.orderId,
              paymentMethod: widget.paymentMethod,
              isCashOnDelivery: false,
            ),
          ),
              (route) => route.isFirst,
        );
      }
    } on ApiException catch (e) {
      if (mounted) _showSnack(e.message, Colors.red);
    } catch (e) {
      if (mounted) _showSnack('Upload failed. Please try again.', Colors.red);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  String _methodKey(String method) {
    final lower = method.toLowerCase();
    if (lower.contains('jazz')) return 'jazzcash';
    if (lower.contains('easy')) return 'easypaisa';
    if (lower.contains('bank')) return 'bank_transfer';
    return 'cod';
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Upload Payment Proof')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Payment Details Card ──
            Card(
              color: _paymentColor.withOpacity(0.08),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: _paymentColor.withOpacity(0.3))),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.payment, color: _paymentColor),
                        const SizedBox(width: 8),
                        Text(widget.paymentMethod,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _paymentColor,
                                fontSize: 18)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(label: 'Account Number', value: widget.accountNumber),
                    _InfoRow(label: 'Account Name', value: widget.accountName),
                    _InfoRow(
                        label: 'Amount',
                        value:
                        'PKR ${widget.amount.toStringAsFixed(0)}',
                        bold: true),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Instructions ──
            Text('How to pay', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.07),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '1. Open your payment app\n'
                    '2. Send PKR amount to the account above\n'
                    '3. Take a clear screenshot of the confirmation\n'
                    '4. Upload it below and add the reference number',
                style: TextStyle(height: 1.6, fontSize: 13),
              ),
            ),

            const SizedBox(height: 20),

            // ── Screenshot Picker ──
            Text('Payment Screenshot *',
                style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),

            GestureDetector(
              onTap: () => _showImageSourceSheet(),
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  border: Border.all(
                      color: _imageFile == null
                          ? theme.colorScheme.outline
                          : theme.colorScheme.primary,
                      width: _imageFile == null ? 1.5 : 2),
                  borderRadius: BorderRadius.circular(12),
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                ),
                child: _imageFile != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Image.file(_imageFile!, fit: BoxFit.cover),
                )
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined,
                        size: 48,
                        color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(height: 8),
                    Text('Tap to select screenshot',
                        style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ),

            if (_imageFile != null) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => _showImageSourceSheet(),
                icon: const Icon(Icons.change_circle_outlined),
                label: const Text('Change Image'),
              ),
            ],

            const SizedBox(height: 16),

            // ── Reference Number ──
            TextField(
              controller: _referenceController,
              decoration: InputDecoration(
                labelText: 'Reference / Transaction ID (optional)',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.tag),
              ),
            ),

            const SizedBox(height: 24),

            // ── Submit Button ──
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _uploading ? null : _uploadProof,
                icon: _uploading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
                    : const Icon(Icons.upload),
                label: Text(_uploading ? 'Uploading...' : 'Submit Payment Proof'),
              ),
            ),

            const SizedBox(height: 12),

            Text(
              'Your order will be confirmed once admin verifies your payment.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _InfoRow({required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13)),
        Text(value,
            style: TextStyle(
                fontWeight:
                bold ? FontWeight.bold : FontWeight.w500,
                fontSize: 13)),
      ],
    ),
  );
}