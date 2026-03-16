import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/services/api_client.dart';
import '../../data/services/order_service.dart';
import '../presentation/payment/order_sucess_screen.dart';
import '../presentation/providers/auth_provider.dart';
import '../presentation/providers/cart_provider.dart';
import '../presentation/providers/paymentsettingsprovider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _nameCtrl    = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _notesCtrl   = TextEditingController();

  String _paymentMethod = 'cod';
  bool   _isProcessing  = false;

  // ── Screenshot fields ─────────────────────────────────────────
  File?      _screenshotFile;
  Uint8List? _screenshotBytes;
  bool get _hasScreenshot =>
      kIsWeb ? _screenshotBytes != null : _screenshotFile != null;

  static const _paymentOptions = [
    {'value': 'cod',           'label': 'Cash on Delivery', 'icon': Icons.money},
    {'value': 'jazzcash',      'label': 'JazzCash',         'icon': Icons.phone_android},
    {'value': 'easypaisa',     'label': 'Easypaisa',        'icon': Icons.account_balance_wallet},
    {'value': 'bank_transfer', 'label': 'Bank Transfer',    'icon': Icons.account_balance},
  ];

  bool get _isOnlinePayment => _paymentMethod != 'cod';

  // Method accent color
  Color _methodColor(String method) {
    switch (method) {
      case 'jazzcash':      return Colors.red.shade700;
      case 'easypaisa':     return Colors.green.shade700;
      case 'bank_transfer': return Colors.blue.shade700;
      default:              return Colors.grey;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).value?.user;
      if (user != null) {
        _nameCtrl.text = user.name;
        if (user.phone   != null) _phoneCtrl.text   = user.phone!;
        if (user.address != null) _addressCtrl.text = user.address!;
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double get _subtotal {
    final items = ref.read(cartProvider).value ?? [];
    return items.fold(0.0, (sum, i) => sum + (i.food.price * i.quantity));
  }

  double get _deliveryFee => _subtotal >= 500 ? 0.0 : 50.0;
  double get _total       => _subtotal + _deliveryFee;

  Future<void> _pickScreenshot() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920, maxHeight: 1920, imageQuality: 85,
      );
      if (picked == null) return;
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() => _screenshotBytes = bytes);
      } else {
        setState(() => _screenshotFile = File(picked.path));
      }
    } catch (e) {
      if (mounted) _showError('Could not pick image: $e');
    }
  }

  Future<void> _placeOrder() async {
    final address = _addressCtrl.text.trim();
    if (address.isEmpty)      { _showError('Please enter a delivery address'); return; }
    if (address.length < 10)  { _showError('Please enter a complete delivery address'); return; }
    if (_isOnlinePayment && !_hasScreenshot) {
      _showError('Please attach your payment screenshot first');
      return;
    }

    final cartItems = ref.read(cartProvider).value ?? [];
    if (cartItems.isEmpty) { _showError('Your cart is empty'); return; }

    setState(() => _isProcessing = true);

    try {
      final items = cartItems
          .map((item) => {'product_id': int.parse(item.food.id), 'quantity': item.quantity})
          .toList();

      // Step 1 — create the order
      final order = await OrderService.placeOrder(
        items:           items,
        deliveryAddress: address,
        paymentMethod:   _paymentMethod,
        customerName:    _nameCtrl.text.trim(),
        phone:           _phoneCtrl.text.trim(),
        notes:           _notesCtrl.text.trim(),
      );

      final orderId = order['id'] as int;

      // Step 2 — upload screenshot (online only)
      if (_isOnlinePayment) {
        final bytes = kIsWeb
            ? _screenshotBytes!.toList()
            : await _screenshotFile!.readAsBytes();
        await OrderService.uploadPaymentProof(
          orderId: orderId, imageBytes: bytes, method: _paymentMethod,
        );
      }

      // Step 3 — clear cart only after BOTH succeed
      ref.read(cartProvider.notifier).clearCart();

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => OrderSuccessScreen(
            orderId:          orderId,
            paymentMethod:    _isOnlinePayment ? _paymentMethod : 'Cash on Delivery',
            isCashOnDelivery: !_isOnlinePayment,
          ),
        ),
            (route) => route.isFirst,
      );
    } on ApiException catch (e) {
      if (mounted) _showError(e.firstError);
    } catch (e) {
      if (mounted) _showError('Failed to place order. Please try again.');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Copied to clipboard'),
      duration: Duration(seconds: 1),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme             = Theme.of(context);
    final cartAsync         = ref.watch(cartProvider);
    final paymentSettings   = ref.watch(paymentSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: cartAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (_, __) => const Center(child: Text('Failed to load cart')),
        data: (_) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              // ── Delivery Details ──────────────────────────────
              Text('Delivery Details',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _Field(_nameCtrl,    'Full Name',                       Icons.person),
              const SizedBox(height: 12),
              _Field(_phoneCtrl,   'Phone Number',                    Icons.phone,
                  keyboard: TextInputType.phone),
              const SizedBox(height: 12),
              _Field(_addressCtrl, 'Delivery Address',                Icons.location_on, maxLines: 3),
              const SizedBox(height: 12),
              _Field(_notesCtrl,   'Special Instructions (optional)', Icons.note, maxLines: 2),

              const SizedBox(height: 20),

              // ── Payment Method ────────────────────────────────
              Text('Payment Method',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              ..._paymentOptions.map((opt) => RadioListTile<String>(
                value:      opt['value'] as String,
                groupValue: _paymentMethod,
                onChanged:  (v) => setState(() {
                  _paymentMethod   = v!;
                  _screenshotFile  = null;
                  _screenshotBytes = null;
                }),
                secondary: Icon(opt['icon'] as IconData),
                title:     Text(opt['label'] as String),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                tileColor: _paymentMethod == opt['value']
                    ? theme.colorScheme.primaryContainer.withOpacity(0.3)
                    : null,
              )),

              // ── Online payment section ────────────────────────
              if (_isOnlinePayment) ...[
                const SizedBox(height: 20),

                // ── Account details card (from backend) ───────
                paymentSettings.when(
                  loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      )),
                  error: (_, __) => Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:        Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border:       Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(children: [
                      Icon(Icons.warning_amber, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Could not load account details. '
                              'Please contact support for payment info.',
                        ),
                      ),
                    ]),
                  ),
                  data: (settings) {
                    // Find the setting for the selected method
                    final setting = settings.where(
                          (s) => s.method == _paymentMethod,
                    ).firstOrNull;

                    if (setting == null) {
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:        Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Payment details not configured yet. '
                              'Please contact admin.',
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    final color = _methodColor(_paymentMethod);

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                            color: color.withOpacity(0.5), width: 1.5),
                      ),
                      color: color.withOpacity(0.06),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Row(children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: color.withOpacity(0.15),
                                child: Icon(Icons.account_balance_wallet,
                                    color: color, size: 18),
                              ),
                              const SizedBox(width: 10),
                              Text('Send via ${setting.label}',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: color)),
                            ]),

                            const Divider(height: 20),

                            // Account Name
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Account Name',
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 13)),
                                Text(setting.accountName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14)),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // Account Number + copy
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Account Number',
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 13)),
                                Row(children: [
                                  Text(setting.accountNumber,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: color)),
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () =>
                                        _copyToClipboard(setting.accountNumber),
                                    child: Icon(Icons.copy_outlined,
                                        size: 18, color: color),
                                  ),
                                ]),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // Amount
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Amount to Send',
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 13)),
                                Text('PKR ${_total.toStringAsFixed(0)}',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: color)),
                              ],
                            ),

                            // Instructions if available
                            if (setting.instructions != null &&
                                setting.instructions!.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              const Divider(height: 1),
                              const SizedBox(height: 10),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.info_outline,
                                      size: 14,
                                      color: color.withOpacity(0.7)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      setting.instructions!,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: color.withOpacity(0.8)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // ── Screenshot picker ─────────────────────────
                Text('Payment Screenshot *',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),

                GestureDetector(
                  onTap: _pickScreenshot,
                  child: Container(
                    height: 160,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _hasScreenshot
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                        width: _hasScreenshot ? 2 : 1.5,
                      ),
                    ),
                    child: _hasScreenshot
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: kIsWeb
                          ? Image.memory(_screenshotBytes!,
                          fit: BoxFit.cover, width: double.infinity)
                          : Image.file(_screenshotFile!,
                          fit: BoxFit.cover, width: double.infinity),
                    )
                        : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined,
                            size: 44,
                            color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(height: 8),
                        Text('Tap to attach payment screenshot',
                            style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 13)),
                        const SizedBox(height: 4),
                        Text('Required before placing order',
                            style: TextStyle(
                                color: Colors.red.shade400,
                                fontSize: 11)),
                      ],
                    ),
                  ),
                ),

                if (_hasScreenshot)
                  TextButton.icon(
                    onPressed: _pickScreenshot,
                    icon:  const Icon(Icons.change_circle_outlined),
                    label: const Text('Change Screenshot'),
                  ),
              ],

              const SizedBox(height: 24),

              // ── Order Summary ─────────────────────────────────
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    _SummaryRow('Subtotal', 'PKR ${_subtotal.toStringAsFixed(0)}'),
                    const SizedBox(height: 6),
                    _SummaryRow(
                      'Delivery Fee',
                      _deliveryFee == 0
                          ? 'FREE'
                          : 'PKR ${_deliveryFee.toStringAsFixed(0)}',
                      valueColor: _deliveryFee == 0 ? Colors.green : null,
                    ),
                    const Divider(height: 20),
                    _SummaryRow('Total', 'PKR ${_total.toStringAsFixed(0)}',
                        bold: true),
                  ]),
                ),
              ),

              const SizedBox(height: 20),

              // ── Place Order Button ────────────────────────────
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _placeOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                      width: 24, height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                      : Text(
                      _isOnlinePayment
                          ? 'Submit & Place Order'
                          : 'Place Order',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Reusable text field ───────────────────────────────────────
class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int maxLines;
  final TextInputType keyboard;

  const _Field(this.controller, this.label, this.icon,
      {this.maxLines = 1, this.keyboard = TextInputType.text});

  @override
  Widget build(BuildContext context) => TextField(
    controller:   controller,
    maxLines:     maxLines,
    keyboardType: keyboard,
    decoration: InputDecoration(
      labelText:  label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

// ── Order summary row ─────────────────────────────────────────
class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  const _SummaryRow(this.label, this.value,
      {this.bold = false, this.valueColor});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label,
          style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
      Text(value,
          style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              color: valueColor ??
                  (bold ? Theme.of(context).colorScheme.primary : null))),
    ],
  );
}