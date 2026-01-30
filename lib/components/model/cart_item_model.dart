import 'package:hive/hive.dart';
import '../entities/cart_item.dart';
import '../entities/food.dart';

/// CartItemModel for Hive persistence
/// Manual implementation without code generation to avoid part/part-of issues
class CartItemModel extends HiveObject {
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

  factory CartItemModel.fromCartItem(CartItem cartItem) {
    return CartItemModel(
      foodId: cartItem.food.id,
      foodName: cartItem.food.name,
      foodDescription: cartItem.food.description,
      foodPrice: cartItem.food.price,
      foodImageUrl: cartItem.food.imageUrl,
      foodCategory: cartItem.food.category,
      foodRating: cartItem.food.rating,
      foodReviewCount: cartItem.food.reviewCount,
      foodIngredients: cartItem.food.ingredients,
      foodPreparationTime: cartItem.food.preparationTime,
      foodCalories: cartItem.food.calories,
      quantity: cartItem.quantity,
      specialInstructions: cartItem.specialInstructions,
    );
  }

  CartItem toCartItem() {
    return CartItem(
      food: Food(
        id: foodId,
        name: foodName,
        description: foodDescription,
        price: foodPrice,
        imageUrl: foodImageUrl,
        category: foodCategory,
        rating: foodRating,
        reviewCount: foodReviewCount,
        ingredients: foodIngredients,
        preparationTime: foodPreparationTime,
        calories: foodCalories,
      ),
      quantity: quantity,
      specialInstructions: specialInstructions,
    );
  }
}

/// Manual Hive Adapter for CartItemModel
/// This adapter is manually written to avoid code generation issues
class CartItemModelAdapter extends TypeAdapter<CartItemModel> {
  @override
  final int typeId = 0;

  @override
  CartItemModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CartItemModel(
      foodId: fields[0] as String,
      foodName: fields[1] as String,
      foodDescription: fields[2] as String,
      foodPrice: fields[3] as double,
      foodImageUrl: fields[4] as String,
      foodCategory: fields[5] as String,
      foodRating: fields[6] as double,
      foodReviewCount: fields[7] as int,
      foodIngredients: (fields[8] as List).cast<String>(),
      foodPreparationTime: fields[9] as int,
      foodCalories: fields[10] as int,
      quantity: fields[11] as int,
      specialInstructions: fields[12] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CartItemModel obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.foodId)
      ..writeByte(1)
      ..write(obj.foodName)
      ..writeByte(2)
      ..write(obj.foodDescription)
      ..writeByte(3)
      ..write(obj.foodPrice)
      ..writeByte(4)
      ..write(obj.foodImageUrl)
      ..writeByte(5)
      ..write(obj.foodCategory)
      ..writeByte(6)
      ..write(obj.foodRating)
      ..writeByte(7)
      ..write(obj.foodReviewCount)
      ..writeByte(8)
      ..write(obj.foodIngredients)
      ..writeByte(9)
      ..write(obj.foodPreparationTime)
      ..writeByte(10)
      ..write(obj.foodCalories)
      ..writeByte(11)
      ..write(obj.quantity)
      ..writeByte(12)
      ..write(obj.specialInstructions);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is CartItemModelAdapter &&
              runtimeType == other.runtimeType &&
              typeId == other.typeId;
}