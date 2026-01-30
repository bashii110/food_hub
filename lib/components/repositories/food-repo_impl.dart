
import '../entities/food.dart';
import '../mock data/mockfood.dart';
import '../model/food_model.dart';
import 'foodrepo.dart';


class FoodRepositoryImpl implements FoodRepository {
  List<Food>? _cachedFoods;

  List<Food> _getFoods() {
    if (_cachedFoods == null) {
      _cachedFoods = mockFoodData
          .map((json) => FoodModel.fromJson(json).toEntity())
          .toList();
    }
    return _cachedFoods!;
  }

  @override
  Future<List<Food>> getAllFoods() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));
    return _getFoods();
  }

  @override
  Future<List<Food>> getFoodsByCategory(String category) async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (category.toLowerCase() == 'all') {
      return _getFoods();
    }

    return _getFoods()
        .where((food) => food.category.toLowerCase() == category.toLowerCase())
        .toList();
  }

  @override
  Future<List<Food>> searchFoods(String query) async {
    await Future.delayed(const Duration(milliseconds: 300));

    if (query.isEmpty) {
      return _getFoods();
    }

    final lowercaseQuery = query.toLowerCase();
    return _getFoods().where((food) {
      return food.name.toLowerCase().contains(lowercaseQuery) ||
          food.description.toLowerCase().contains(lowercaseQuery) ||
          food.category.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  @override
  Future<Food?> getFoodById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));

    try {
      return _getFoods().firstWhere((food) => food.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<Food>> getPopularFoods() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _getFoods().where((food) => food.isPopular).toList();
  }

  @override
  List<String> getCategories() {
    return [
      'All',
      'Burger',
      'Pizza',
      'Pasta',
      'Dessert',
      'Drinks',
    ];
  }
}