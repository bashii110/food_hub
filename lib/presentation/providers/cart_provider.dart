import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../components/entities/cart_item.dart';
import '../../components/repositories/cart_repo.dart';
import '../../components/repositories/cartrepo_impl.dart';
import 'auth_provider.dart';

// ── Repository Provider ───────────────────────────────────────
// Box<dynamic> — stores plain Maps, no TypeAdapter needed
// AFTER:
// Opens the correct per-user box lazily and safely
final cartRepositoryProvider = Provider.family<CartRepository, String>((ref, userId) {
  final boxName = 'cart_$userId';
  // Box must already be open — opened on login, closed on logout
  final cartBox = Hive.isBoxOpen(boxName)
      ? Hive.box<dynamic>(boxName)
      : throw StateError('Cart box not open for user $userId');
  return CartRepositoryImpl(cartBox);
});

// ── Cart State Notifier ───────────────────────────────────────
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
      final item = currentState.firstWhere((i) => i.food.id == foodId);
      await _repository.updateCartItem(item.copyWith(quantity: newQuantity));
      await loadCart();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> incrementQuantity(String foodId) async {
    final currentState = state.value;
    if (currentState == null) return;
    try {
      final item = currentState.firstWhere((i) => i.food.id == foodId);
      await updateQuantity(foodId, item.quantity + 1);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> decrementQuantity(String foodId) async {
    final currentState = state.value;
    if (currentState == null) return;
    try {
      final item = currentState.firstWhere((i) => i.food.id == foodId);
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

// ── Cart Provider ─────────────────────────────────────────────
// AFTER:
final cartProvider =
StateNotifierProvider<CartNotifier, AsyncValue<List<CartItem>>>((ref) {
  final authState = ref.watch(authProvider).value;
  final userId = authState?.user?.id.toString() ?? 'guest';
  final repository = ref.watch(cartRepositoryProvider(userId));
  return CartNotifier(repository);
});

// ── Cart Item Count ───────────────────────────────────────────
final cartItemCountProvider = Provider<int>((ref) {
  final cartAsync = ref.watch(cartProvider);
  return cartAsync.when(
    data: (items) {
      int count = 0;
      for (final item in items) {
        count += item.quantity;
      }
      return count;
    },
    loading: () => 0,
    error: (_, __) => 0,
  );
});

// ── Cart Total ────────────────────────────────────────────────
final cartTotalProvider = Provider<double>((ref) {
  final cartAsync = ref.watch(cartProvider);
  return cartAsync.when(
    data: (items) {
      double total = 0.0;
      for (final item in items) {
        total += item.totalPrice;
      }
      return total;
    },
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
});

// ── Cart Subtotal (items only, no delivery) ───────────────────
final cartSubtotalProvider = Provider<double>((ref) {
  final cartItems = ref.watch(cartProvider).value ?? [];
  double subtotal = 0.0;
  for (final item in cartItems) {
    subtotal += item.food.price * item.quantity;
  }
  return subtotal;
});

// ── Delivery Fee (free above Rs 500) ─────────────────────────
final deliveryFeeProvider = Provider<double>((ref) {
  final subtotal = ref.watch(cartSubtotalProvider);
  return subtotal >= 500 ? 0.0 : 60.0;
});

// ── Is Item In Cart ───────────────────────────────────────────
final isInCartProvider = Provider.family<bool, String>((ref, foodId) {
  final cartAsync = ref.watch(cartProvider);
  return cartAsync.when(
    data: (items) => items.any((item) => item.food.id == foodId),
    loading: () => false,
    error: (_, __) => false,
  );
});

// ── Item Quantity In Cart ─────────────────────────────────────
final cartItemQuantityProvider = Provider.family<int, String>((ref, foodId) {
  final cartAsync = ref.watch(cartProvider);
  return cartAsync.when(
    data: (items) {
      try {
        return items.firstWhere((item) => item.food.id == foodId).quantity;
      } catch (_) {
        return 0;
      }
    },
    loading: () => 0,
    error: (_, __) => 0,
  );
});