import 'package:hive/hive.dart';
import '../entities/cart_item.dart';
import '../model/cart_item_model.dart';
import 'cart_repo.dart';

/// Stores each cart item as a Map<String, dynamic> under its foodId as key.
/// Uses Box<dynamic> — no TypeAdapter needed, eliminates int-vs-double cast bugs.
class CartRepositoryImpl implements CartRepository {
  final Box<dynamic> _cartBox;

  CartRepositoryImpl(this._cartBox);

  // ─── Read all items ───────────────────────────────────────────
  @override
  Future<List<CartItem>> getCartItems() async {
    try {
      final List<CartItem> items = [];
      for (final key in _cartBox.keys) {
        final raw = _cartBox.get(key);
        if (raw is Map) {
          try {
            final model = CartItemModel.fromMap(raw);
            items.add(model.toCartItem());
          } catch (_) {
            // skip any single corrupt entry
          }
        }
      }
      return items;
    } catch (_) {
      return [];
    }
  }

  // ─── Add or merge ─────────────────────────────────────────────
  @override
  Future<void> addToCart(CartItem item) async {
    try {
      final key = item.food.id;
      final existing = _cartBox.get(key);

      if (existing is Map) {
        // Already in cart → merge quantity
        final existingModel = CartItemModel.fromMap(existing);
        final merged = CartItemModel(
          foodId:              existingModel.foodId,
          foodName:            existingModel.foodName,
          foodDescription:     existingModel.foodDescription,
          foodPrice:           existingModel.foodPrice,
          foodImageUrl:        existingModel.foodImageUrl,
          foodCategory:        existingModel.foodCategory,
          foodRating:          existingModel.foodRating,
          foodReviewCount:     existingModel.foodReviewCount,
          foodIngredients:     existingModel.foodIngredients,
          foodPreparationTime: existingModel.foodPreparationTime,
          foodCalories:        existingModel.foodCalories,
          quantity:            existingModel.quantity + item.quantity,
          specialInstructions: item.specialInstructions ?? existingModel.specialInstructions,
        );
        await _cartBox.put(key, merged.toMap());
      } else {
        // New item
        final model = CartItemModel.fromCartItem(item);
        await _cartBox.put(key, model.toMap());
      }
    } catch (e) {
      rethrow;
    }
  }

  // ─── Update ───────────────────────────────────────────────────
  @override
  Future<void> updateCartItem(CartItem item) async {
    try {
      final key = item.food.id;
      if (_cartBox.containsKey(key)) {
        final model = CartItemModel.fromCartItem(item);
        await _cartBox.put(key, model.toMap());
      }
    } catch (e) {
      rethrow;
    }
  }

  // ─── Remove ───────────────────────────────────────────────────
  @override
  Future<void> removeFromCart(String foodId) async {
    try {
      await _cartBox.delete(foodId);
    } catch (e) {
      rethrow;
    }
  }

  // ─── Clear ────────────────────────────────────────────────────
  @override
  Future<void> clearCart() async {
    try {
      await _cartBox.clear();
    } catch (e) {
      rethrow;
    }
  }

  // ─── Count ────────────────────────────────────────────────────
  @override
  Future<int> getCartItemCount() async {
    try {
      final List<CartItem> items = await getCartItems();
      // Use a plain for-loop with explicit int — avoids FutureOr<int> inference
      int count = 0;
      for (final item in items) {
        count += item.quantity;
      }
      return count;
    } catch (_) {
      return 0;
    }
  }

  // ─── Total ────────────────────────────────────────────────────
  @override
  Future<double> getCartTotal() async {
    try {
      final List<CartItem> items = await getCartItems();
      // Same pattern — plain loop, explicit double
      double total = 0.0;
      for (final item in items) {
        total += item.totalPrice;
      }
      return total;
    } catch (_) {
      return 0.0;
    }
  }
}