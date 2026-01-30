
import '../entities/food.dart';

abstract class FoodRepository {
  Future<List<Food>> getAllFoods();
  Future<List<Food>> getFoodsByCategory(String category);
  Future<List<Food>> searchFoods(String query);
  Future<Food?> getFoodById(String id);
  Future<List<Food>> getPopularFoods();
  List<String> getCategories();
}