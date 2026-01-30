import 'package:equatable/equatable.dart';

class Food extends Equatable {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final double rating;
  final int reviewCount;
  final List<String> ingredients;
  final int preparationTime; // in minutes
  final int calories;
  final bool isPopular;
  final bool isAvailable;

  const Food({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.rating,
    required this.reviewCount,
    required this.ingredients,
    required this.preparationTime,
    required this.calories,
    this.isPopular = false,
    this.isAvailable = true,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    price,
    imageUrl,
    category,
    rating,
    reviewCount,
    ingredients,
    preparationTime,
    calories,
    isPopular,
    isAvailable,
  ];
}