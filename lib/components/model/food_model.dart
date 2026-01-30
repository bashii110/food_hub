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
    super.isPopular,
    super.isAvailable,
  });

  factory FoodModel.fromJson(Map<String, dynamic> json) {
    return FoodModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String,
      category: json['category'] as String,
      rating: (json['rating'] as num).toDouble(),
      reviewCount: json['reviewCount'] as int,
      ingredients: List<String>.from(json['ingredients'] as List),
      preparationTime: json['preparationTime'] as int,
      calories: json['calories'] as int,
      isPopular: json['isPopular'] as bool? ?? false,
      isAvailable: json['isAvailable'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'category': category,
      'rating': rating,
      'reviewCount': reviewCount,
      'ingredients': ingredients,
      'preparationTime': preparationTime,
      'calories': calories,
      'isPopular': isPopular,
      'isAvailable': isAvailable,
    };
  }

  Food toEntity() {
    return Food(
      id: id,
      name: name,
      description: description,
      price: price,
      imageUrl: imageUrl,
      category: category,
      rating: rating,
      reviewCount: reviewCount,
      ingredients: ingredients,
      preparationTime: preparationTime,
      calories: calories,
      isPopular: isPopular,
      isAvailable: isAvailable,
    );
  }
}