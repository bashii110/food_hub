import '../entities/cart_item.dart';
import '../entities/food.dart';

/// CartItemModel — plain Dart class, no Hive annotations.
/// Serialised to/from Map<String,dynamic> and stored via
/// cartrepo_impl using Hive.box<dynamic> with JSON maps.
/// This avoids every type-cast problem that the manual
/// TypeAdapter caused (int vs double, etc.).
class CartItemModel {
  final String foodId;
  final String foodName;
  final String foodDescription;
  final double foodPrice;
  final String foodImageUrl;
  final String foodCategory;
  final double foodRating;
  final int foodReviewCount;
  final List<String> foodIngredients;
  final int foodPreparationTime;
  final int foodCalories;
  final int quantity;
  final String? specialInstructions;

  CartItemModel({
    required this.foodId,
    required this.foodName,
    required this.foodDescription,
    required this.foodPrice,
    required this.foodImageUrl,
    required this.foodCategory,
    required this.foodRating,
    required this.foodReviewCount,
    required this.foodIngredients,
    required this.foodPreparationTime,
    required this.foodCalories,
    required this.quantity,
    this.specialInstructions,
  });

  // ─── Build from a CartItem entity ────────────────────────────
  factory CartItemModel.fromCartItem(CartItem cartItem) {
    return CartItemModel(
      foodId:              cartItem.food.id,
      foodName:            cartItem.food.name,
      foodDescription:     cartItem.food.description,
      foodPrice:           cartItem.food.price,
      foodImageUrl:        cartItem.food.imageUrl,
      foodCategory:        cartItem.food.category,
      foodRating:          cartItem.food.rating,
      foodReviewCount:     cartItem.food.reviewCount,
      foodIngredients:     List<String>.from(cartItem.food.ingredients),
      foodPreparationTime: cartItem.food.preparationTime,
      foodCalories:        cartItem.food.calories,
      quantity:            cartItem.quantity,
      specialInstructions: cartItem.specialInstructions,
    );
  }

  // ─── Serialise to a plain Map (stored in Hive as-is) ─────────
  Map<String, dynamic> toMap() {
    return {
      'foodId':              foodId,
      'foodName':            foodName,
      'foodDescription':     foodDescription,
      'foodPrice':           foodPrice,         // stored as double
      'foodImageUrl':        foodImageUrl,
      'foodCategory':        foodCategory,
      'foodRating':          foodRating,        // stored as double
      'foodReviewCount':     foodReviewCount,
      'foodIngredients':     foodIngredients,
      'foodPreparationTime': foodPreparationTime,
      'foodCalories':        foodCalories,
      'quantity':            quantity,
      'specialInstructions': specialInstructions,
    };
  }

  // ─── Deserialise from a plain Map (safe casts) ───────────────
  factory CartItemModel.fromMap(Map<dynamic, dynamic> map) {
    return CartItemModel(
      foodId:              map['foodId']?.toString() ?? '',
      foodName:            map['foodName']?.toString() ?? '',
      foodDescription:     map['foodDescription']?.toString() ?? '',
      foodPrice:           _toDouble(map['foodPrice']),
      foodImageUrl:        map['foodImageUrl']?.toString() ?? '',
      foodCategory:        map['foodCategory']?.toString() ?? '',
      foodRating:          _toDouble(map['foodRating'], fallback: 4.5),
      foodReviewCount:     _toInt(map['foodReviewCount']),
      foodIngredients:     _toStringList(map['foodIngredients']),
      foodPreparationTime: _toInt(map['foodPreparationTime']),
      foodCalories:        _toInt(map['foodCalories']),
      quantity:            _toInt(map['quantity'], fallback: 1),
      specialInstructions: map['specialInstructions']?.toString(),
    );
  }

  // ─── Convert back to domain entity ───────────────────────────
  CartItem toCartItem() {
    return CartItem(
      food: Food(
        id:              foodId,
        name:            foodName,
        description:     foodDescription,
        price:           foodPrice,
        imageUrl:        foodImageUrl,
        category:        foodCategory,
        rating:          foodRating,
        reviewCount:     foodReviewCount,
        ingredients:     foodIngredients,
        preparationTime: foodPreparationTime,
        calories:        foodCalories,
        isPopular:       false,
        isAvailable:     true,
      ),
      quantity:            quantity,
      specialInstructions: specialInstructions,
    );
  }

  // ─── Private safe-cast helpers ────────────────────────────────
  static double _toDouble(dynamic v, {double fallback = 0.0}) {
    if (v == null) return fallback;
    if (v is double) return v;
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
    return [];
  }
}