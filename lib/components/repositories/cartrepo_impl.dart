import 'package:hive/hive.dart';
import '../entities/cart_item.dart';
import '../model/cart_item_model.dart';
import 'cart_repo.dart';


class CartRepositoryImpl implements CartRepository {
  final Box<CartItemModel> _cartBox;

  CartRepositoryImpl(this._cartBox);

  @override
  Future<List<CartItem>> getCartItems() async {
    try {
      final items = _cartBox.values.map((model) => model.toCartItem()).toList();
      return items;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> addToCart(CartItem item) async {
    try {
      // Check if item already exists
      final existingIndex = _cartBox.values
          .toList()
          .indexWhere((model) => model.foodId == item.food.id);

      if (existingIndex != -1) {
        // Update quantity if exists
        final existingItem = _cartBox.getAt(existingIndex);
        if (existingItem != null) {
          final updatedItem = CartItemModel.fromCartItem(
            item.copyWith(quantity: existingItem.quantity + item.quantity),
          );
          await _cartBox.putAt(existingIndex, updatedItem);
        }
      } else {
        // Add new item
        final model = CartItemModel.fromCartItem(item);
        await _cartBox.add(model);
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updateCartItem(CartItem item) async {
    try {
      final index = _cartBox.values
          .toList()
          .indexWhere((model) => model.foodId == item.food.id);

      if (index != -1) {
        final model = CartItemModel.fromCartItem(item);
        await _cartBox.putAt(index, model);
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> removeFromCart(String foodId) async {
    try {
      final index =
      _cartBox.values.toList().indexWhere((model) => model.foodId == foodId);

      if (index != -1) {
        await _cartBox.deleteAt(index);
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> clearCart() async {
    try {
      await _cartBox.clear();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<int> getCartItemCount() async {
    try {
      final items = await getCartItems();
      return items.fold<int>(0, (sum, item) => sum + item.quantity);
    } catch (e) {
      return 0;
    }
  }

  @override
  Future<double> getCartTotal() async {
    try {
      final items = await getCartItems();
      return items.fold<double>(0, (sum, item) => sum + item.totalPrice);
    } catch (e) {
      return 0.0;
    }
  }
}