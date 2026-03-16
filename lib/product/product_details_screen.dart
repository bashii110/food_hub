import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../cart/cart_screen.dart';
import '../components/app_constants.dart';
import '../components/app_string.dart';
import '../components/entities/cart_item.dart';
import '../components/entities/food.dart';
import '../components/utils/app_utils.dart';
import '../data/services/api_client.dart';
import '../presentation/providers/cart_provider.dart';

// Resolve "/storage/..." → "http://host:port/storage/..."
String _resolveUrl(String raw) {
  if (raw.isEmpty) return '';
  if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
  final b = Uri.parse(ApiClient.baseUrl);
  return '${b.scheme}://${b.host}:${b.port}$raw';
}

class ProductDetailScreen extends ConsumerStatefulWidget {
  final Food food;

  const ProductDetailScreen({
    super.key,
    required this.food,
  });

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen>
    with SingleTickerProviderStateMixin {
  int _quantity = 1;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppConstants.animationDurationNormal,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _incrementQuantity() {
    if (_quantity < AppConstants.maxQuantityPerItem) {
      setState(() => _quantity++);
    }
  }

  void _decrementQuantity() {
    if (_quantity > AppConstants.minQuantityPerItem) {
      setState(() => _quantity--);
    }
  }

  Future<void> _addToCart() async {
    final cartItem = CartItem(
      food: widget.food,
      quantity: _quantity,
    );

    try {
      await ref.read(cartProvider.notifier).addToCart(cartItem);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.food.name} added to cart'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'View Cart',
            onPressed: () {
              // ✅ FIX: Actually navigate to the cart screen
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              );
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add item to cart: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isInCart = ref.watch(isInCartProvider(widget.food.id));
    final cartQuantity = ref.watch(cartItemQuantityProvider(widget.food.id));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App Bar with Hero Image ──────────────────────────
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'food_${widget.food.id}',
                child: CachedNetworkImage(
                  imageUrl: _resolveUrl(widget.food.imageUrl),
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    child: Icon(
                      Icons.restaurant,
                      size: 80,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Content ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name & Price Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              widget.food.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Rs ${widget.food.price.toStringAsFixed(0)}',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Category chip
                      Chip(
                        label: Text(widget.food.category),
                        backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                        labelStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Info chips row
                      Row(
                        children: [
                          _buildInfoChip(
                            context,
                            Icons.star,
                            widget.food.rating.toStringAsFixed(1),
                            Colors.amber,
                          ),
                          const SizedBox(width: 8),
                          _buildInfoChip(
                            context,
                            Icons.timer_outlined,
                            '${widget.food.preparationTime} min',
                            Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          _buildInfoChip(
                            context,
                            Icons.local_fire_department_outlined,
                            '${widget.food.calories} cal',
                            Colors.orange,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Description
                      Text(
                        AppStrings.description,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.food.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7),
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Ingredients
                      if (widget.food.ingredients.isNotEmpty) ...[
                        Text(
                          AppStrings.ingredients,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: widget.food.ingredients
                              .map(
                                (ingredient) => Chip(
                              label: Text(ingredient),
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceVariant,
                            ),
                          )
                              .toList(),
                        ),
                      ],

                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      // ── Bottom Bar ────────────────────────────────────────────
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Quantity Selector
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _decrementQuantity,
                      icon: const Icon(Icons.remove),
                      color: _quantity > 1
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.3),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        _quantity.toString(),
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      onPressed: _incrementQuantity,
                      icon: const Icon(Icons.add),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Add to Cart Button
              Expanded(
                child: ElevatedButton(
                  onPressed: _addToCart,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isInCart && cartQuantity > 0) ...[
                        const Icon(Icons.check, size: 20),
                        const SizedBox(width: 8),
                        Text('In Cart ($cartQuantity)'),
                      ] else ...[
                        const Icon(Icons.shopping_cart, size: 20),
                        const SizedBox(width: 8),
                        const Text(AppStrings.addToCart),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(
      BuildContext context,
      IconData icon,
      String label,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}