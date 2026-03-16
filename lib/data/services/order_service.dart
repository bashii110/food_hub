import 'api_client.dart';

class OrderService {
  /// Place a new order (prices are calculated server-side)
  static Future<Map<String, dynamic>> placeOrder({
    required List<Map<String, dynamic>> items,
    required String deliveryAddress,
    required String paymentMethod,
    String? customerName,
    String? phone,
    String? notes,
  }) async {
    final response = await apiClient.post('/orders', body: {
      'items': items,
      'delivery_address': deliveryAddress,
      'payment_method': paymentMethod,
      if (customerName != null && customerName.isNotEmpty)
        'customer_name': customerName,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });

    return response['order'] as Map<String, dynamic>;
  }

  /// Get current user's orders (paginated)
  static Future<List<Map<String, dynamic>>> getMyOrders({
    String? status,
    int page = 1,
  }) async {
    final response = await apiClient.get(
      '/orders',
      queryParams: {
        'page': page.toString(),
        if (status != null) 'status': status,
      },
    );

    // API returns paginated response: { data: [...], ... }
    final raw = response['data'] ?? response['orders'] ?? [];
    return (raw as List).cast<Map<String, dynamic>>();
  }

  /// Get single order detail
  static Future<Map<String, dynamic>> getOrder(int orderId) async {
    final response = await apiClient.get('/orders/$orderId');
    return response['order'] as Map<String, dynamic>;
  }

  /// Cancel an order
  static Future<void> cancelOrder(int orderId, {String? reason}) async {
    await apiClient.post('/orders/$orderId/cancel', body: {
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    });
  }

  /// Upload payment proof screenshot
  static Future<void> uploadPaymentProof({
    required int orderId,
    required List<int> imageBytes,
    String? reference,
    String? method,
  }) async {
    await apiClient.postMultipart(
      '/orders/$orderId/payment/proof',
      {
        if (reference != null && reference.isNotEmpty) 'reference': reference,
        if (method != null) 'method': method,
      },
      {'screenshot': imageBytes},
    );
  }
}