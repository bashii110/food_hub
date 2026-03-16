import 'package:equatable/equatable.dart';
import 'food.dart';

class CartItem extends Equatable {
  final Food food;
  final int quantity;
  final String? specialInstructions;

  const CartItem({
    required this.food,
    required this.quantity,
    this.specialInstructions,
  });

  double get totalPrice => food.price * quantity;

  CartItem copyWith({
    Food? food,
    int? quantity,
    String? specialInstructions,
  }) {
    return CartItem(
      food: food ?? this.food,
      quantity: quantity ?? this.quantity,
      specialInstructions: specialInstructions ?? this.specialInstructions,
    );
  }

  @override
  List<Object?> get props => [food, quantity, specialInstructions];
}