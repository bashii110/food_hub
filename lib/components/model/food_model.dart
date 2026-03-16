import 'dart:convert';
import '../entities/food.dart';

class FoodModel extends Food {
  const FoodModel({
    required super.id,
    required super.name,
    required super.description,
    required super.price,
    required super.imageUrl,
    required super.category,
    required super.rating,
    required super.reviewCount,
    required super.ingredients,
    required super.preparationTime,
    required super.calories,
    required super.isPopular,
    required super.isAvailable,
  });

  // ─────────────────────────────────────────────────────────────
  // Static helpers — MUST be static so factory constructors can
  // call them (factory constructors have no access to `this`)
  // ─────────────────────────────────────────────────────────────

  static double _toDouble(dynamic v, {double fallback = 0.0}) {
    if (v == null) return fallback;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? fallback;
  }

  static int _toInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? fallback;
  }

  static List<String> _toStringList(dynamic v) {
    if (v is List) return v.map((e) => e.toString()).toList();
    if (v is String && v.isNotEmpty) {
      try {
        final decoded = jsonDecode(v);
        if (decoded is List) return decoded.map((e) => e.toString()).toList();
      } catch (_) {}
    }
    return [];
  }

  // ─────────────────────────────────────────────────────────────
  // Factory — uses static helpers, no instance access needed
  // ─────────────────────────────────────────────────────────────

  factory FoodModel.fromJson(Map<String, dynamic> json) {
    // Category can be a nested object or a plain string
    final categoryRaw = json['category'];
    final categoryName = categoryRaw is Map<String, dynamic>
        ? (categoryRaw['name']?.toString() ?? 'Unknown')
        : (categoryRaw?.toString() ?? 'Unknown');

    return FoodModel(
      id:              json['id'].toString(),
      name:            json['name']?.toString() ?? '',
      description:     json['description']?.toString() ?? '',
      price:           _toDouble(json['price']),
      imageUrl:        json['image_url']?.toString() ?? '',   // snake_case ✓
      category:        categoryName,
      rating:          _toDouble(json['rating'], fallback: 4.5),
      reviewCount:     _toInt(json['review_count']),          // snake_case ✓
      ingredients:     _toStringList(json['ingredients']),
      preparationTime: _toInt(json['preparation_time'], fallback: 20), // snake_case ✓
      calories:        _toInt(json['calories']),
      isPopular:       json['is_popular'] == true,
      isAvailable:     json['is_available'] != false,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // toJson — keeps snake_case to stay consistent with the API
  // ─────────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() {
    return {
      'id':               id,
      'name':             name,
      'description':      description,
      'price':            price,
      'image_url':        imageUrl,
      'category':         category,
      'rating':           rating,
      'review_count':     reviewCount,
      'ingredients':      ingredients,
      'preparation_time': preparationTime,
      'calories':         calories,
      'is_popular':       isPopular,
      'is_available':     isAvailable,
    };
  }

  Food toEntity() {
    return Food(
      id:              id,
      name:            name,
      description:     description,
      price:           price,
      imageUrl:        imageUrl,
      category:        category,
      rating:          rating,
      reviewCount:     reviewCount,
      ingredients:     ingredients,
      preparationTime: preparationTime,
      calories:        calories,
      isPopular:       isPopular,
      isAvailable:     isAvailable,
    );
  }
}