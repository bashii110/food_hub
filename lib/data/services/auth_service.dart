// auth_service.dart
// NOTE: Authentication state is fully managed by authProvider (JWT token via
// SharedPreferences). This file is kept as a thin wrapper for any legacy
// code that still references AuthService.

import '../services/api_client.dart';

class AuthService {
  /// Returns true if a JWT token is stored locally.
  static Future<bool> isLoggedIn() async {
    final token = await apiClient.getToken();
    return token != null && token.isNotEmpty;
  }

  /// Clears the stored token (used on logout).
  static Future<void> logout() async {
    await apiClient.clearToken();
  }
}