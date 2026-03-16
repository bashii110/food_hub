import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../components/entities/food.dart';
import '../../data/services/api_client.dart';
import '../../data/services/product_service.dart';

// Resolve relative path → absolute URL
String _resolveImageUrl(String? raw) {
  if (raw == null || raw.trim().isEmpty) return '';
  if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
  final base = Uri.parse(ApiClient.baseUrl);
  return '${base.scheme}://${base.host}:${base.port}$raw';
}

// ══════════════════════════════════════════════════════════════
// PROVIDERS
// ══════════════════════════════════════════════════════════════

final allFoodsProvider = FutureProvider<List<Food>>((ref) async {
  try {
    final products = await ProductService.getProducts();
    return products.map(_mapToFood).toList();
  } catch (e) {
    print('Error loading products: $e');
    return [];
  }
});

final popularFoodsProvider = FutureProvider<List<Food>>((ref) async {
  try {
    final products = await ProductService.getPopularProducts();
    return products.map(_mapToFood).toList();
  } catch (e) {
    print('Error loading popular products: $e');
    return [];
  }
});

final categoriesProvider = FutureProvider<List<String>>((ref) async {
  try {
    final categories = await ProductService.getCategories();
    return ['All', ...categories.map((c) => c['name'] as String).toList()];
  } catch (e) {
    print('Error loading categories: $e');
    return ['All'];
  }
});

final selectedCategoryProvider = StateProvider<String>((ref) => 'All');
final searchQueryProvider       = StateProvider<String>((ref) => '');

final displayedFoodsProvider = FutureProvider<List<Food>>((ref) async {
  final searchQuery      = ref.watch(searchQueryProvider);
  final selectedCategory = ref.watch(selectedCategoryProvider);

  try {
    List<Map<String, dynamic>> products;

    if (searchQuery.isNotEmpty) {
      products = await ProductService.searchProducts(searchQuery);
    } else if (selectedCategory != 'All') {
      final categories = await ProductService.getCategories();
      final category   = categories.firstWhere(
            (c) => c['name'] == selectedCategory,
        orElse: () => <String, dynamic>{},
      );
      products = category.isNotEmpty
          ? await ProductService.getProducts(categoryId: category['id'] as int)
          : await ProductService.getProducts();
    } else {
      products = await ProductService.getProducts();
    }

    return products.map(_mapToFood).toList();
  } catch (e) {
    print('Error loading filtered products: $e');
    return [];
  }
});

final foodByIdProvider = FutureProvider.family<Food?, String>((ref, id) async {
  try {
    final productId = int.tryParse(id);
    if (productId == null) return null;
    final product = await ProductService.getProduct(productId);
    if (product == null) return null;
    return _mapToFood(product);
  } catch (e) {
    print('Error loading product: $e');
    return null;
  }
});

// ══════════════════════════════════════════════════════════════
// MAP JSON → Food entity
// The ONLY change from the original: imageUrl now calls _resolveImageUrl()
// ══════════════════════════════════════════════════════════════
Food _mapToFood(Map<String, dynamic> json) {
  final category     = json['category'] as Map<String, dynamic>?;
  final categoryName = category?['name'] as String? ?? 'Unknown';

  List<String> ingredients = [];
  final ingredientsRaw = json['ingredients'];
  if (ingredientsRaw is String) {
    try {
      final decoded = jsonDecode(ingredientsRaw);
      if (decoded is List) ingredients = decoded.cast<String>();
    } catch (_) {}
  } else if (ingredientsRaw is List) {
    ingredients = ingredientsRaw.map((e) => e.toString()).toList();
  }

  return Food(
    id:              json['id'].toString(),
    name:            json['name'] as String? ?? '',
    description:     json['description'] as String? ?? '',
    price:           (json['price'] as num?)?.toDouble() ?? 0.0,

    // ✅ THE FIX — was: json['image_url'] as String? ?? ''
    //              now: _resolveImageUrl(json['image_url'] as String?)
    imageUrl:        _resolveImageUrl(json['image_url'] as String?),

    category:        categoryName,
    rating:          (json['rating'] as num?)?.toDouble() ?? 4.5,
    reviewCount:     json['review_count'] as int? ?? 0,
    ingredients:     ingredients,
    preparationTime: json['preparation_time'] as int? ?? 20,
    calories:        json['calories'] as int? ?? 0,
    isPopular:       json['is_popular']  as bool? ?? false,
    isAvailable:     json['is_available'] as bool? ?? true,
  );
}