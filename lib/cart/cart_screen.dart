import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'checkout_screen.dart';
import '../presentation/providers/cart_provider.dart';
import '../presentation/providers/auth_provider.dart';
import '../presentation/payment/payment_upload_screen.dart';
import '../data/services/order_service.dart';
import '../presentation/auth/login_screen.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  bool _isProcessing = false;

  // Subtotal
  double _getSubtotal(List cartItems) {
    return cartItems.fold(
      0.0,
          (sum, item) => sum + (item.food.price * item.quantity),
    );
  }

  double _getDeliveryFee(double subtotal) {
    return subtotal >= 500 ? 0.0 : 60.0; // ← 60
  }

  double _getTotal(double subtotal, double deliveryFee) {
    return subtotal + deliveryFee;
  }

  Future<String?> _showAddressDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.location_on, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Delivery Address'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your complete delivery address:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'House #, Street, Area, City',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.home),
              ),
              maxLines: 3,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter address')),
                );
                return;
              }
              Navigator.pop(context, controller.text.trim());
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Future<String?> _showPaymentMethodDialog() async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Payment Method'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.phone_android, color: Colors.purple),
              title: const Text('JazzCash'),
              subtitle: const Text('Pay via JazzCash mobile app'),
              onTap: () => Navigator.pop(context, 'jazzcash'),
            ),
            ListTile(
              leading: const Icon(Icons.mobile_friendly, color: Colors.blue),
              title: const Text('Easypaisa'),
              subtitle: const Text('Pay via Easypaisa mobile app'),
              onTap: () => Navigator.pop(context, 'easypaisa'),
            ),
            ListTile(
              leading: const Icon(Icons.account_balance, color: Colors.green),
              title: const Text('Bank Transfer'),
              subtitle: const Text('Direct bank transfer'),
              onTap: () => Navigator.pop(context, 'bank_transfer'),
            ),
            ListTile(
              leading: const Icon(Icons.money, color: Colors.orange),
              title: const Text('Cash on Delivery'),
              subtitle: const Text('Pay when you receive'),
              onTap: () => Navigator.pop(context, 'cash_on_delivery'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCheckout() async {
    // Check login
    final authState = ref.read(authProvider).value;
    if (authState?.user == null) {
      final shouldLogin = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Login Required'),
          content: const Text('Please login to place an order.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Login'),
            ),
          ],
        ),
      );
      if (shouldLogin == true && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
      return;
    }

    final cartItems = ref.read(cartProvider).value ?? [];
    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final address = await _showAddressDialog();
      if (address == null || address.isEmpty) {
        setState(() => _isProcessing = false);
        return;
      }

      final paymentMethod = await _showPaymentMethodDialog();
      if (paymentMethod == null) {
        setState(() => _isProcessing = false);
        return;
      }

      final items = cartItems
          .map((item) => {
        'product_id': int.parse(item.food.id),
        'quantity': item.quantity,
      })
          .toList();

      final order = await OrderService.placeOrder(
        items: items,
        deliveryAddress: address,
        paymentMethod: paymentMethod,
      );

      if (order == null) throw Exception('Failed to create order');

      ref.read(cartProvider.notifier).clearCart();

      if (!mounted) return;

      if (paymentMethod == 'cash_on_delivery') {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Order placed successfully! Cash on Delivery'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentUploadScreen(
              orderId: order['id'] as int,
              amount: (order['total_amount'] as num).toDouble(),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartAsyncValue = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        actions: [
          cartAsyncValue.when(
            data: (items) => items.isNotEmpty
                ? TextButton.icon(
              onPressed: () => ref.read(cartProvider.notifier).clearCart(),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Clear'),
            )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: cartAsyncValue.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Your cart is empty',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add some delicious items to get started!',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          final subtotal = _getSubtotal(items);
          final deliveryFee = _getDeliveryFee(subtotal);
          final total = _getTotal(subtotal, deliveryFee);

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final cartItem = items[index];
                    return Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: cartItem.food.imageUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                imageUrl: cartItem.food.imageUrl,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey[300],
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.restaurant),
                                ),
                              )
                                  : Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.restaurant,
                                  size: 40,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cartItem.food.name,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Rs ${cartItem.food.price.toStringAsFixed(0)}',
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey[300]!),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          if (cartItem.quantity > 1) {
                                            ref
                                                .read(cartProvider.notifier)
                                                .updateQuantity(
                                                cartItem.food.id,
                                                cartItem.quantity - 1);
                                          } else {
                                            ref
                                                .read(cartProvider.notifier)
                                                .removeFromCart(cartItem.food.id);
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          child: Icon(
                                            cartItem.quantity > 1
                                                ? Icons.remove
                                                : Icons.delete_outline,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding:
                                        const EdgeInsets.symmetric(horizontal: 12),
                                        child: Text(
                                          cartItem.quantity.toString(),
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () {
                                          ref
                                              .read(cartProvider.notifier)
                                              .updateQuantity(
                                              cartItem.food.id,
                                              cartItem.quantity + 1);
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          child: const Icon(Icons.add, size: 20),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Rs ${(cartItem.food.price * cartItem.quantity).toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal'),
                        Text('Rs ${subtotal.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Delivery Fee'),
                        Text(
                          deliveryFee == 0
                              ? 'FREE'
                              : 'Rs ${deliveryFee.toStringAsFixed(0)}',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: deliveryFee == 0 ? Colors.green : null),
                        ),
                      ],
                    ),
                    if (subtotal < 500) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Add Rs ${(500 - subtotal).toStringAsFixed(0)} more for free delivery',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total',
                          style:
                          Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Rs ${total.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isProcessing ? null : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CheckoutScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isProcessing
                            ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                            : const Text(
                          'Proceed to Checkout',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('Error loading cart: $error')),
      ),
    );
  }
}
