import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class JazzCashPaymentService {
  // Test credentials (replace with your actual credentials)
  static const String merchantId = 'YOUR_MERCHANT_ID';
  static const String password = 'YOUR_PASSWORD';
  static const String integritySalt = 'YOUR_INTEGRITY_SALT';

  // URLs
  static const String sandboxUrl = 'https://sandbox.jazzcash.com.pk/CustomerPortal/transactionmanagement/merchantform/';
  static const String productionUrl = 'https://payments.jazzcash.com.pk/CustomerPortal/transactionmanagement/merchantform/';

  static const bool isProduction = false; // Set to true for production

  static String get baseUrl => isProduction ? productionUrl : sandboxUrl;

  /// Generate transaction ID
  static String generateTxnRefNo() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'T$timestamp';
  }

  /// Generate date/time in JazzCash format
  static String getFormattedDateTime() {
    final now = DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}'
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
  }

  /// Generate expiry date/time (1 hour from now)
  static String getExpiryDateTime() {
    final expiry = DateTime.now().add(const Duration(hours: 1));
    return '${expiry.year}${expiry.month.toString().padLeft(2, '0')}'
        '${expiry.day.toString().padLeft(2, '0')}'
        '${expiry.hour.toString().padLeft(2, '0')}'
        '${expiry.minute.toString().padLeft(2, '0')}'
        '${expiry.second.toString().padLeft(2, '0')}';
  }

  /// Generate secure hash
  static String generateHash(Map<String, String> params) {
    // Sort parameters alphabetically
    final sortedKeys = params.keys.toList()..sort();

    // Build hash string
    String hashString = integritySalt + '&';
    for (final key in sortedKeys) {
      if (params[key]!.isNotEmpty) {
        hashString += '${params[key]}&';
      }
    }
    hashString = hashString.substring(0, hashString.length - 1);

    // Generate HMAC SHA256
    final key = utf8.encode(integritySalt);
    final bytes = utf8.encode(hashString);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(bytes);

    return digest.toString();
  }

  /// Create payment parameters
  static Map<String, String> createPaymentParams({
    required double amount,
    required String customerEmail,
    required String customerMobile,
    String? orderId,
  }) {
    final txnRefNo = orderId ?? generateTxnRefNo();
    final dateTime = getFormattedDateTime();
    final expiryDateTime = getExpiryDateTime();

    // Convert amount to paisa (multiply by 100)
    final amountInPaisa = (amount * 100).toInt().toString();

    final params = {
      'pp_Version': '1.1',
      'pp_TxnType': 'MWALLET',
      'pp_Language': 'EN',
      'pp_MerchantID': merchantId,
      'pp_SubMerchantID': '',
      'pp_Password': password,
      'pp_BankID': 'TBANK',
      'pp_ProductID': 'RETL',
      'pp_TxnRefNo': txnRefNo,
      'pp_Amount': amountInPaisa,
      'pp_TxnCurrency': 'PKR',
      'pp_TxnDateTime': dateTime,
      'pp_BillReference': txnRefNo,
      'pp_Description': 'Food Delivery Payment',
      'pp_TxnExpiryDateTime': expiryDateTime,
      'pp_ReturnURL': 'https://your-website.com/payment/callback',
      'pp_SecureHash': '',
      'ppmpf_1': customerEmail,
      'ppmpf_2': customerMobile,
      'ppmpf_3': '',
      'ppmpf_4': '',
      'ppmpf_5': '',
    };

    // Generate and add secure hash
    final tempParams = Map<String, String>.from(params);
    tempParams.remove('pp_SecureHash');
    params['pp_SecureHash'] = generateHash(tempParams);

    return params;
  }
}