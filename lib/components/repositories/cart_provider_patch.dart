// In cart_provider.dart — update cartRepositoryProvider only:
//
// Replace:
//   final cartBox = Hive.box<CartItemModel>('cart');
//
// With:
//   final cartBox = Hive.box<dynamic>('cart');

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import 'cart_repo.dart';
import 'cartrepo_impl.dart';

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  final cartBox = Hive.box<dynamic>('cart');   // ← dynamic, not CartItemModel
  return CartRepositoryImpl(cartBox);
});