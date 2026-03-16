class Food {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final double rating;
  final int reviewCount;
  final List<String> ingredients;
  final int preparationTime;
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
    required this.isPopular,
    required this.isAvailable,
  });

  factory Food.fromJson(Map<String, dynamic> json) => Food(
    id: json['id'].toString(),
    name: json['name'] ?? '',
    description: json['description'] ?? '',
    price: (json['price'] as num).toDouble(),
    imageUrl: json['image_url'] ?? '',
    category: json['category'] ?? '',
    rating: (json['rating'] as num?)?.toDouble() ?? 0,
    reviewCount: json['review_count'] ?? 0,
    ingredients: (json['ingredients'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList() ??
        [],
    preparationTime: json['preparation_time'] ?? 0,
    calories: json['calories'] ?? 0,
    isPopular: json['is_popular'] ?? false,
    isAvailable: json['is_available'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'price': price,
    'image_url': imageUrl,
    'category': category,
    'rating': rating,
    'review_count': reviewCount,
    'ingredients': ingredients,
    'preparation_time': preparationTime,
    'calories': calories,
    'is_popular': isPopular,
    'is_available': isAvailable,
  };
}
