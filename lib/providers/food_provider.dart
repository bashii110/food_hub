import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/entities/food.dart';
import '../components/repositories/food-repo_impl.dart';
import '../components/repositories/foodrepo.dart';

// Repository Provider
final foodRepositoryProvider = Provider<FoodRepository>((ref) {
  return FoodRepositoryImpl();
});

// All Foods Provider
final allFoodsProvider = FutureProvider<List<Food>>((ref) async {
  final repository = ref.watch(foodRepositoryProvider);
  return repository.getAllFoods();
});

// Popular Foods Provider
final popularFoodsProvider = FutureProvider<List<Food>>((ref) async {
  final repository = ref.watch(foodRepositoryProvider);
  return repository.getPopularFoods();
});

// Categories Provider
final categoriesProvider = Provider<List<String>>((ref) {
  final repository = ref.watch(foodRepositoryProvider);
  return repository.getCategories();
});

// Selected Category Provider
final selectedCategoryProvider = StateProvider<String>((ref) => 'All');

// Filtered Foods by Category Provider
final filteredFoodsProvider = FutureProvider<List<Food>>((ref) async {
  final repository = ref.watch(foodRepositoryProvider);
  final selectedCategory = ref.watch(selectedCategoryProvider);
  return repository.getFoodsByCategory(selectedCategory);
});

// Search Query Provider
final searchQueryProvider = StateProvider<String>((ref) => '');

// Searched Foods Provider
final searchedFoodsProvider = FutureProvider<List<Food>>((ref) async {
  final repository = ref.watch(foodRepositoryProvider);
  final query = ref.watch(searchQueryProvider);

  if (query.isEmpty) {
    return repository.getAllFoods();
  }

  return repository.searchFoods(query);
});

// Combined Foods Provider (combines category filter and search)
final displayedFoodsProvider = FutureProvider<List<Food>>((ref) async {
  final searchQuery = ref.watch(searchQueryProvider);
  final selectedCategory = ref.watch(selectedCategoryProvider);
  final repository = ref.watch(foodRepositoryProvider);

  List<Food> foods;

  if (searchQuery.isNotEmpty) {
    foods = await repository.searchFoods(searchQuery);
  } else {
    foods = await repository.getFoodsByCategory(selectedCategory);
  }

  return foods;
});

// Single Food Provider
final foodByIdProvider = FutureProvider.family<Food?, String>((ref, id) async {
  final repository = ref.watch(foodRepositoryProvider);
  return repository.getFoodById(id);
});