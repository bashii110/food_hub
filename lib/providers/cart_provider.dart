import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../components/entities/cart_item.dart';
import '../components/model/cart_item_model.dart';
import '../components/repositories/cart_repo.dart';
import '../components/repositories/cartrepo_impl.dart';


// Repository Provider
final cartRepositoryProvider = Provider<CartRepository>((ref) {
  final cartBox = Hive.box<CartItemModel>('cart');
  return CartRepositoryImpl(cartBox);
});

// Cart State Notifier
class CartNotifier extends StateNotifier<AsyncValue<List<CartItem>>> {
  final CartRepository _repository;

  CartNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadCart();
  }

  Future<void> loadCart() async {
    state = const AsyncValue.loading();
    try {
      final items = await _repository.getCartItems();
      state = AsyncValue.data(items);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addToCart(CartItem item) async {
    try {
      await _repository.addToCart(item);
      await loadCart();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateQuantity(String foodId, int newQuantity) async {
    final currentState = state.value;
    if (currentState == null) return;

    try {
      final item = currentState.firstWhere((item) => item.food.id == foodId);
      final updatedItem = item.copyWith(quantity: newQuantity);
      await _repository.updateCartItem(updatedItem);
      await loadCart();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> incrementQuantity(String foodId) async {
    final currentState = state.value;
    if (currentState == null) return;

    try {
      final item = currentState.firstWhere((item) => item.food.id == foodId);
      await updateQuantity(foodId, item.quantity + 1);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> decrementQuantity(String foodId) async {
    final currentState = state.value;
    if (currentState == null) return;

    try {
      final item = currentState.firstWhere((item) => item.food.id == foodId);
      if (item.quantity > 1) {
        await updateQuantity(foodId, item.quantity - 1);
      } else {
        await removeFromCart(foodId);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeFromCart(String foodId) async {
    try {
      await _repository.removeFromCart(foodId);
      await loadCart();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> clearCart() async {
    try {
      await _repository.clearCart();
      await loadCart();
    } catch (e) {
      rethrow;
    }
  }
}

// Cart Provider
final cartProvider = StateNotifierProvider<CartNotifier, AsyncValue<List<CartItem>>>((ref) {
  final repository = ref.watch(cartRepositoryProvider);
  return CartNotifier(repository);
});

// Cart Item Count Provider
final cartItemCountProvider = Provider<int>((ref) {
  final cartAsync = ref.watch(cartProvider);
  return cartAsync.when(
    data: (items) => items.fold<int>(0, (sum, item) => sum + item.quantity),
    loading: () => 0,
    error: (_, __) => 0,
  );
});

// Cart Total Provider
final cartTotalProvider = Provider<double>((ref) {
  final cartAsync = ref.watch(cartProvider);
  return cartAsync.when(
    data: (items) => items.fold<double>(0, (sum, item) => sum + item.totalPrice),
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
});

// Check if item is in cart
final isInCartProvider = Provider.family<bool, String>((ref, foodId) {
  final cartAsync = ref.watch(cartProvider);
  return cartAsync.when(
    data: (items) => items.any((item) => item.food.id == foodId),
    loading: () => false,
    error: (_, __) => false,
  );
});

// Get item quantity in cart
final cartItemQuantityProvider = Provider.family<int, String>((ref, foodId) {
  final cartAsync = ref.watch(cartProvider);
  return cartAsync.when(
    data: (items) {
      try {
        final item = items.firstWhere((item) => item.food.id == foodId);
        return item.quantity;
      } catch (e) {
        return 0;
      }
    },
    loading: () => 0,
    error: (_, __) => 0,
  );
});