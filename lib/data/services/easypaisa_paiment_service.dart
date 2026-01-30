import 'dart:convert';
import 'package:crypto/crypto.dart';

class EasypaisaPaymentService {
  // Test credentials (replace with your actual credentials)
  static const String storeId = 'YOUR_STORE_ID';
  static const String secretKey = 'YOUR_SECRET_KEY';

  // URLs
  static const String sandboxUrl = 'https://easypay-api.test.easypaisa.com.pk/easypay/Index.jsf';
  static const String productionUrl = 'https://easypay.easypaisa.com.pk/easypay/Index.jsf';

  static const bool isProduction = false;

  static String get baseUrl => isProduction ? productionUrl : sandboxUrl;

  /// Generate transaction ID
  static String generateOrderRefNum() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'EP$timestamp';
  }

  /// Generate date in Easypaisa format (YYYYMMDD)
  static String getFormattedDate() {
    final now = DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}';
  }

  /// Generate expiry date (tomorrow)
  static String getExpiryDate() {
    final expiry = DateTime.now().add(const Duration(days: 1));
    return '${expiry.year}${expiry.month.toString().padLeft(2, '0')}'
        '${expiry.day.toString().padLeft(2, '0')}';
  }

  /// Generate secure hash
  static String generateHash(Map<String, String> params) {
    String hashString = '';

    // Build hash string in specific order
    hashString += params['amount'] ?? '';
    hashString += params['orderRefNum'] ?? '';
    hashString += params['paymentMethod'] ?? '';
    hashString += params['storeId'] ?? '';
    hashString += params['transactionDateTime'] ?? '';
    hashString += params['transactionExpiryDateTime'] ?? '';
    hashString += secretKey;

    // Generate SHA256
    final bytes = utf8.encode(hashString);
    final digest = sha256.convert(bytes);

    return digest.toString();
  }

  /// Create payment parameters
  static Map<String, String> createPaymentParams({
    required double amount,
    required String customerMobile,
    required String customerEmail,
    String? orderId,
  }) {
    final orderRefNum = orderId ?? generateOrderRefNum();
    final dateTime = getFormattedDate();
    final expiryDateTime = getExpiryDate();

    // Amount should be in PKR (no conversion needed)
    final amountStr = amount.toStringAsFixed(2);

    final params = {
      'storeId': storeId,
      'amount': amountStr,
      'postBackURL': 'https://your-website.com/payment/easypaisa/callback',
      'orderRefNum': orderRefNum,
      'expiryDate': expiryDateTime,
      'merchantHashedReq': '',
      'autoRedirect': '1',
      'paymentMethod': 'MA_PAYMENT_METHOD',
      'emailAddress': customerEmail,
      'mobileNumber': customerMobile,
    };

    // Generate and add hash
    params['merchantHashedReq'] = generateHash(params);

    return params;
  }
}