import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/api_client.dart';

// ── Model ─────────────────────────────────────────────────────
class PaymentSetting {
  final String method;
  final String accountNumber;
  final String accountName;
  final String? instructions;

  const PaymentSetting({
    required this.method,
    required this.accountNumber,
    required this.accountName,
    this.instructions,
  });

  factory PaymentSetting.fromJson(Map<String, dynamic> json) {
    return PaymentSetting(
      method:        json['method']         as String,
      accountNumber: json['account_number'] as String,
      accountName:   json['account_name']   as String,
      instructions:  json['instructions']   as String?,
    );
  }

  // Label shown in UI
  String get label {
    switch (method) {
      case 'jazzcash':      return 'JazzCash';
      case 'easypaisa':     return 'Easypaisa';
      case 'bank_transfer': return 'Bank Transfer';
      default:              return method;
    }
  }
}

// ── Provider ──────────────────────────────────────────────────
// Public endpoint — no auth needed, fetched fresh on every checkout open.
final paymentSettingsProvider =
FutureProvider<List<PaymentSetting>>((ref) async {
  try {
    final res = await apiClient.get('/payment-settings');
    final list = res['data'] as List? ?? [];
    return list
        .cast<Map<String, dynamic>>()
        .map(PaymentSetting.fromJson)
        .toList();
  } catch (_) {
    return [];
  }
});

// ── Admin provider (fetches all including inactive) ───────────
final adminPaymentSettingsProvider =
FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await apiClient.get('/admin/payment-settings');
  final list = res['data'] as List? ?? [];
  return list.cast<Map<String, dynamic>>();
});