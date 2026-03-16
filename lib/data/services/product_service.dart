import 'api_client.dart';

class ProductService {
  /// Get all available products (optionally filtered)
  static Future<List<Map<String, dynamic>>> getProducts({
    int? categoryId,
    String? search,
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await apiClient.get(
      '/products',
      queryParams: {
        'page': page.toString(),
        'per_page': perPage.toString(),
        if (categoryId != null) 'category_id': categoryId.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );

    // API returns paginated: { data: [...], current_page, last_page, ... }
    final raw = response['data'] ?? response['products'] ?? [];
    return (raw as List).cast<Map<String, dynamic>>();
  }

  /// Get popular products
  static Future<List<Map<String, dynamic>>> getPopularProducts() async {
    final response = await apiClient.get(
      '/products',
      queryParams: {'popular': 'true', 'per_page': '10'},
    );
    final raw = response['data'] ?? response['products'] ?? [];
    return (raw as List).cast<Map<String, dynamic>>();
  }

  /// Get a single product by ID
  static Future<Map<String, dynamic>?> getProduct(int productId) async {
    final response = await apiClient.get('/products/$productId');
    return response['product'] as Map<String, dynamic>?;
  }

  /// Get all categories
  static Future<List<Map<String, dynamic>>> getCategories() async {
    final response = await apiClient.get('/categories');
    final raw = response['categories'] ?? response['data'] ?? [];
    return (raw as List).cast<Map<String, dynamic>>();
  }

  /// Search products
  static Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    return getProducts(search: query);
  }
}