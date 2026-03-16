import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/services/api_client.dart';

// ── Models ────────────────────────────────────────────────────
class DashboardStats {
  final int totalOrders;
  final int pendingVerification;
  final int activeOrders;
  final int totalUsers;
  final double totalRevenue;
  final double todayRevenue;
  final int totalProducts;
  final int totalCategories;
  final List<Map<String, dynamic>> ordersByStatus;
  final List<Map<String, dynamic>> dailyRevenueChart;
  final List<Map<String, dynamic>> recentOrders;
  final List<Map<String, dynamic>> topProducts;

  const DashboardStats({
    required this.totalOrders,
    required this.pendingVerification,
    required this.activeOrders,
    required this.totalUsers,
    required this.totalRevenue,
    required this.todayRevenue,
    required this.totalProducts,
    required this.totalCategories,
    required this.ordersByStatus,
    required this.dailyRevenueChart,
    required this.recentOrders,
    required this.topProducts,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) => DashboardStats(
    totalOrders: _int(json['total_orders']),
    pendingVerification: _int(json['pending_verification']),
    activeOrders: _int(json['active_orders']),
    totalUsers: _int(json['total_users']),
    totalRevenue: _dbl(json['total_revenue']),
    todayRevenue: _dbl(json['today_revenue']),
    totalProducts: _int(json['total_products']),
    totalCategories: _int(json['total_categories']),
    ordersByStatus: _list(json['orders_by_status']),
    dailyRevenueChart: _list(json['daily_revenue_chart']),
    recentOrders: _list(json['recent_orders']),
    topProducts: _list(json['top_products']),
  );

  static int _int(dynamic v) => (v as num?)?.toInt() ?? 0;
  static double _dbl(dynamic v) => double.tryParse(v?.toString() ?? '0') ?? 0;
  static List<Map<String, dynamic>> _list(dynamic v) =>
      (v as List?)?.cast<Map<String, dynamic>>() ?? [];
}

class AdminOrder {
  final int id;
  final String userName;
  final String userEmail;
  final String status;
  final String paymentMethod;
  final double total;
  final String createdAt;
  final Map<String, dynamic>? payment;

  const AdminOrder({
    required this.id,
    required this.userName,
    required this.userEmail,
    required this.status,
    required this.paymentMethod,
    required this.total,
    required this.createdAt,
    this.payment,
  });

  factory AdminOrder.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return AdminOrder(
      id: (json['id'] as num).toInt(),
      userName: user?['name'] as String? ?? 'Unknown',
      userEmail: user?['email'] as String? ?? '',
      status: json['status'] as String? ?? 'unknown',
      paymentMethod: json['payment_method'] as String? ?? '',
      total: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0,
      createdAt: json['created_at'] as String? ?? '',
      payment: json['payment'] as Map<String, dynamic>?,
    );
  }
}

class AdminUser {
  final int id;
  final String name;
  final String email;
  final String role;
  final bool isActive;
  final int ordersCount;

  const AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
    required this.ordersCount,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(
    id: (json['id'] as num).toInt(),
    name: json['name'] as String,
    email: json['email'] as String,
    role: json['role'] as String? ?? 'user',
    isActive: json['is_active'] as bool? ?? true,
    ordersCount: (json['orders_count'] as num?)?.toInt() ?? 0,
  );
}

class AdminProduct {
  final int id;
  final String name;
  final double price;
  final int categoryId;
  final String categoryName;
  final String? imageUrl;
  final bool isAvailable;
  final bool isPopular;

  const AdminProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.categoryId,
    required this.categoryName,
    this.imageUrl,
    required this.isAvailable,
    required this.isPopular,
  });

  factory AdminProduct.fromJson(Map<String, dynamic> json) {
    final cat = json['category'] as Map<String, dynamic>?;
    return AdminProduct(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      categoryId: (cat?['id'] as num?)?.toInt() ??
          (json['category_id'] as num?)?.toInt() ?? 0,
      categoryName: cat?['name'] as String? ?? 'Unknown',
      // Backend returns full URL via accessor
      imageUrl: json['image_url'] as String?,
      isAvailable: json['is_available'] as bool? ?? true,
      isPopular: json['is_popular'] as bool? ?? false,
    );
  }
}

class AdminCategory {
  final int id;
  final String name;
  final String? icon;

  const AdminCategory({required this.id, required this.name, this.icon});

  factory AdminCategory.fromJson(Map<String, dynamic> json) => AdminCategory(
    id: (json['id'] as num).toInt(),
    name: json['name'] as String,
    icon: json['icon'] as String?,
  );
}

// ── Dashboard Provider ────────────────────────────────────────
final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final res = await apiClient.get('/admin/dashboard');
  return DashboardStats.fromJson(res);
});

// ── Admin Orders Provider ─────────────────────────────────────
final adminOrdersProvider =
FutureProvider.family<List<AdminOrder>, String?>((ref, status) async {
  final res = await apiClient.get(
    '/admin/orders',
    queryParams: {
      if (status != null && status != 'all') 'status': status,
    },
  );
  final list = res['data'] as List? ?? [];
  return list
      .cast<Map<String, dynamic>>()
      .map(AdminOrder.fromJson)
      .toList();
});

// ── Order Actions ─────────────────────────────────────────────
class OrderActionsNotifier extends StateNotifier<AsyncValue<void>> {
  OrderActionsNotifier(this._ref) : super(const AsyncValue.data(null));
  final Ref _ref;

  Future<void> verifyPayment(int orderId) async {
    state = const AsyncValue.loading();
    try {
      await apiClient.post('/admin/orders/$orderId/verify');
      _ref.invalidate(adminOrdersProvider);
      _ref.invalidate(dashboardStatsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> rejectPayment(int orderId, String reason) async {
    state = const AsyncValue.loading();
    try {
      await apiClient.post('/admin/orders/$orderId/reject',
          body: {'reason': reason});
      _ref.invalidate(adminOrdersProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateStatus(int orderId, String status,
      {String? note}) async {
    state = const AsyncValue.loading();
    try {
      await apiClient.put('/admin/orders/$orderId/status', body: {
        'status': status,
        if (note != null) 'note': note,
      });
      _ref.invalidate(adminOrdersProvider);
      _ref.invalidate(dashboardStatsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final orderActionsProvider =
StateNotifierProvider<OrderActionsNotifier, AsyncValue<void>>(
        (ref) => OrderActionsNotifier(ref));

// ── Admin Users ───────────────────────────────────────────────
final adminUsersProvider = FutureProvider<List<AdminUser>>((ref) async {
  final res = await apiClient.get('/admin/users');
  final list = res['data'] as List? ?? [];
  return list.cast<Map<String, dynamic>>().map(AdminUser.fromJson).toList();
});

class ToggleBlockNotifier extends StateNotifier<AsyncValue<void>> {
  ToggleBlockNotifier(this._ref) : super(const AsyncValue.data(null));
  final Ref _ref;

  Future<void> toggle(int userId) async {
    state = const AsyncValue.loading();
    try {
      await apiClient.post('/admin/users/$userId/toggle-block');
      _ref.invalidate(adminUsersProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final toggleBlockProvider =
StateNotifierProvider<ToggleBlockNotifier, AsyncValue<void>>(
        (ref) => ToggleBlockNotifier(ref));

// ── Admin Products ────────────────────────────────────────────
final adminProductsProvider = FutureProvider<List<AdminProduct>>((ref) async {
  final res = await apiClient.get('/products', queryParams: {'per_page': '100'});
  final list = res['data'] as List? ?? [];
  return list
      .cast<Map<String, dynamic>>()
      .map(AdminProduct.fromJson)
      .toList();
});

class ProductActionsNotifier extends StateNotifier<AsyncValue<void>> {
  ProductActionsNotifier(this._ref) : super(const AsyncValue.data(null));
  final Ref _ref;

  Future<void> createProduct({
    required String name,
    required double price,
    required int categoryId,
    String? description,
    String? imagePath,
    bool isPopular = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      final fields = {
        'name': name,
        'price': price.toString(),
        'category_id': categoryId.toString(),
        if (description != null) 'description': description,
        'is_popular': isPopular ? '1' : '0',
      };

      if (imagePath != null) {
        final bytes = await _readBytes(imagePath);
        await apiClient.postMultipart('/products', fields, {'image': bytes});
      } else {
        await apiClient.post('/products', body: {
          'name': name,
          'price': price,
          'category_id': categoryId,
          if (description != null) 'description': description,
          'is_popular': isPopular,
        });
      }

      _ref.invalidate(adminProductsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateProduct({
    required int productId,
    required String name,
    required double price,
    required int categoryId,
    String? description,
    String? imagePath,
    bool? isPopular,
    bool? isAvailable,
  }) async {
    state = const AsyncValue.loading();
    try {
      if (imagePath != null) {
        final bytes = await _readBytes(imagePath);
        final fields = {
          '_method': 'PUT',
          'name': name,
          'price': price.toString(),
          'category_id': categoryId.toString(),
          if (description != null) 'description': description,
          if (isPopular != null) 'is_popular': isPopular ? '1' : '0',
          if (isAvailable != null) 'is_available': isAvailable ? '1' : '0',
        };
        await apiClient.postMultipart(
            '/products/$productId', fields, {'image': bytes},
            method: 'PUT');
      } else {
        await apiClient.put('/products/$productId', body: {
          'name': name,
          'price': price,
          'category_id': categoryId,
          if (description != null) 'description': description,
          if (isPopular != null) 'is_popular': isPopular,
          if (isAvailable != null) 'is_available': isAvailable,
        });
      }

      _ref.invalidate(adminProductsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteProduct(int productId) async {
    state = const AsyncValue.loading();
    try {
      await apiClient.delete('/products/$productId');
      _ref.invalidate(adminProductsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleAvailability(int productId) async {
    state = const AsyncValue.loading();
    try {
      await apiClient.patch('/products/$productId/toggle');
      _ref.invalidate(adminProductsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<List<int>> _readBytes(String path) async {
    final file = XFile(path);
    return (await file.readAsBytes()).toList();
  }
}

final productActionsProvider =
StateNotifierProvider<ProductActionsNotifier, AsyncValue<void>>(
        (ref) => ProductActionsNotifier(ref));

// ── Admin Categories ──────────────────────────────────────────
final adminCategoriesProvider =
FutureProvider<List<AdminCategory>>((ref) async {
  final res = await apiClient.get('/categories');
  final list = res['categories'] as List? ?? [];
  return list
      .cast<Map<String, dynamic>>()
      .map(AdminCategory.fromJson)
      .toList();
});