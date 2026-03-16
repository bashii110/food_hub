import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../components/app_constants.dart';
import '../components/entities/cart_item.dart';
import '../components/entities/food.dart';
import '../data/services/api_client.dart';
import '../presentation/providers/cart_provider.dart';
import '../product/product_details_screen.dart';

// ─────────────────────────────────────────────────────────────
// Resolves whatever the API returns into a full URL.
//
// DB stores:  /storage/products/abc.jpg   (relative path)
// We need:    http://192.168.100.21:8000/storage/products/abc.jpg
//
// baseUrl = "http://192.168.100.21:8000/api"
//  → origin = "http://192.168.100.21:8000"  (strip /api suffix)
//  → result = origin + "/storage/products/abc.jpg"
//
// Also handles:
//   already full http:// URL → returned unchanged
//   null / empty             → returns ""  (shows placeholder)
// ─────────────────────────────────────────────────────────────
String _imageUrl(String raw) {
  if (raw.isEmpty) return '';
  if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
  final base = Uri.parse(ApiClient.baseUrl);
  return '${base.scheme}://${base.host}:${base.port}$raw';
}

class FoodCard extends ConsumerStatefulWidget {
  final Food food;
  final int index;

  const FoodCard({
    required this.food,
    this.index = 0,
    super.key,
  });

  @override
  ConsumerState<FoodCard> createState() => _FoodCardState();
}

class _FoodCardState extends ConsumerState<FoodCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppConstants.animationDurationNormal,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    Future.delayed(Duration(milliseconds: 50 * widget.index), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Category-based icon placeholder shown when there is no image
  Widget _buildPlaceholder() {
    IconData icon;
    Color color;

    switch (widget.food.category.toLowerCase()) {
      case 'burgers':
      case 'burger':
        icon = Icons.lunch_dining;
        color = Colors.orange;
        break;
      case 'pizza':
        icon = Icons.local_pizza;
        color = Colors.red;
        break;
      case 'sushi':
        icon = Icons.set_meal;
        color = Colors.pink;
        break;
      case 'salads':
      case 'salad':
        icon = Icons.eco;
        color = Colors.green;
        break;
      case 'desserts':
      case 'dessert':
        icon = Icons.cake;
        color = Colors.purple;
        break;
      case 'drinks':
      case 'drink':
        icon = Icons.local_drink;
        color = Colors.blue;
        break;
      default:
        icon = Icons.restaurant;
        color = Theme.of(context).colorScheme.primary;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.2), color.withOpacity(0.05)],
        ),
      ),
      child: Center(child: Icon(icon, size: 64, color: color)),
    );
  }

  void _openDetail() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) =>
            ProductDetailScreen(food: widget.food),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: AppConstants.animationDurationNormal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isInCart = ref.watch(isInCartProvider(widget.food.id));

    // ✅ Resolve here — works whether food.imageUrl is:
    //   "/storage/products/abc.jpg"          (relative — needs origin prepended)
    //   "http://192.168.100.21:8000/..."     (already absolute — returned as-is)
    //   ""                                   (no image — shows placeholder)
    final resolvedUrl = _imageUrl(widget.food.imageUrl);
    final hasImage = resolvedUrl.isNotEmpty;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GestureDetector(
          onTap: _openDetail,
          child: Card(
            clipBehavior: Clip.antiAlias,
            elevation: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Product Image ──────────────────────────
                Hero(
                  tag: 'food_${widget.food.id}',
                  child: Stack(
                    children: [
                      AspectRatio(
                        aspectRatio: 1.2,
                        child: hasImage
                            ? CachedNetworkImage(
                          imageUrl: resolvedUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            child: const Center(
                                child: CircularProgressIndicator()),
                          ),
                          errorWidget: (_, __, ___) =>
                              _buildPlaceholder(),
                        )
                            : _buildPlaceholder(),
                      ),
                      if (widget.food.isPopular)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color:
                              Theme.of(context).colorScheme.secondary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.local_fire_department,
                                    size: 14,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSecondary),
                                const SizedBox(width: 4),
                                Text('Popular',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSecondary)),
                              ],
                            ),
                          ),
                        ),
                      if (isInCart)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Icon(Icons.check,
                                size: 16,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimary),
                          ),
                        ),
                    ],
                  ),
                ),

                // ── Name, rating, price, add button ────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Text(
                        widget.food.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(widget.food.rating.toString(),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(width: 4),
                        Text('(${widget.food.reviewCount})',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.6))),
                      ]),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Rs ${widget.food.price.toStringAsFixed(0)}',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary,
                                fontWeight: FontWeight.bold),
                          ),

                          // ✅ FIX: + button adds to cart, does NOT navigate
                          Material(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () {
                                ref.read(cartProvider.notifier).addToCart(
                                  CartItem(
                                    food: widget.food,
                                    quantity: 1,
                                  ),
                                );
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text(
                                      '${widget.food.name} added to cart'),
                                  duration: const Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                ));
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Icon(
                                  isInCart ? Icons.shopping_cart : Icons.add,
                                  size: 20,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}