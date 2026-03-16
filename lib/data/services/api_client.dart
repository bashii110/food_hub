import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';

/// Production-ready API Client
/// - Versioned base URL (/api/v1)
/// - Automatic JWT attachment
/// - Token refresh on 401
/// - Consistent ApiException
class ApiClient {
  // ── Base URL ────────────────────────────────────────────────
  // Change to your server:
  //   Android emulator : http://10.0.2.2:8000/api/v1
  //   iOS simulator    : http://localhost:8000/api/v1
  //   Physical device  : http://YOUR_LAN_IP:8000/api/v1
  //   Production       : https://api.yourdomain.com/api/v1
  // static const String baseUrl = 'http:// 192.168.100.21:8000/api';
  static const String baseUrl = ApiConfig.baseUrl;



  String? _token;
  bool _isRefreshing = false;

  // ── Token Management ────────────────────────────────────────
  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  Future<String?> getToken() async {
    _token ??= (await SharedPreferences.getInstance()).getString('jwt_token');
    return _token;
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  // ── HTTP Methods ────────────────────────────────────────────
  Future<Map<String, dynamic>> get(String path,
      {Map<String, String>? queryParams}) async {
    return _request('GET', path, queryParams: queryParams);
  }

  Future<Map<String, dynamic>> post(String path,
      {Map<String, dynamic>? body}) async {
    return _request('POST', path, body: body);
  }

  Future<Map<String, dynamic>> put(String path,
      {Map<String, dynamic>? body}) async {
    return _request('PUT', path, body: body);
  }

  Future<Map<String, dynamic>> patch(String path,
      {Map<String, dynamic>? body}) async {
    return _request('PATCH', path, body: body);
  }

  Future<Map<String, dynamic>> delete(String path) async {
    return _request('DELETE', path);
  }

  // ── Core Request ────────────────────────────────────────────
  Future<Map<String, dynamic>> _request(
      String method,
      String path, {
        Map<String, dynamic>? body,
        Map<String, String>? queryParams,
      }) async {
    var uri = Uri.parse('$baseUrl$path');
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    final token = await getToken();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    http.Response response;

    try {
      switch (method) {
        case 'GET':
          response = await http.get(uri, headers: headers).timeout(
            const Duration(seconds: 30),
          );
          break;
        case 'POST':
          response = await http
              .post(uri,
              headers: headers,
              body: body != null ? json.encode(body) : null)
              .timeout(const Duration(seconds: 30));
          break;
        case 'PUT':
          response = await http
              .put(uri,
              headers: headers,
              body: body != null ? json.encode(body) : null)
              .timeout(const Duration(seconds: 30));
          break;
        case 'PATCH':
          response = await http
              .patch(uri,
              headers: headers,
              body: body != null ? json.encode(body) : null)
              .timeout(const Duration(seconds: 30));
          break;
        case 'DELETE':
          response =
          await http.delete(uri, headers: headers).timeout(const Duration(seconds: 30));
          break;
        default:
          throw ApiException(statusCode: 0, message: 'Unsupported HTTP method: $method');
      }

      // Auto-refresh on 401 (once only)
      if (response.statusCode == 401 && !_isRefreshing && token != null) {
        _isRefreshing = true;
        try {
          final refreshed = await _refreshToken();
          if (refreshed) {
            _isRefreshing = false;
            return _request(method, path, body: body, queryParams: queryParams);
          }
        } catch (_) {
          await clearToken();
        } finally {
          _isRefreshing = false;
        }
      }

      return _handleResponse(response);
    } on SocketException {
      throw const ApiException(
        statusCode: 0,
        message: 'No internet connection. Please check your network.',
      );
    } on http.ClientException catch (e) {
      throw ApiException(statusCode: 0, message: 'Connection error: ${e.message}');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(statusCode: 0, message: 'Network error: ${e.toString()}');
    }
  }

  // ── Multipart Upload ────────────────────────────────────────
  Future<Map<String, dynamic>> postMultipart(
      String path,
      Map<String, String> fields,
      Map<String, List<int>> files, {
        String method = 'POST',
      }) async {
    final uri = Uri.parse('$baseUrl$path');
    final token = await getToken();

    final request = http.MultipartRequest(method == 'PUT' ? 'POST' : method, uri);

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
    }

    // Laravel needs _method=PUT for multipart updates
    if (method == 'PUT') {
      request.fields['_method'] = 'PUT';
    }

    request.fields.addAll(fields);

    for (final entry in files.entries) {
      final ext = _guessExtension(entry.value);
      request.files.add(
        http.MultipartFile.fromBytes(
          entry.key,
          entry.value,
          filename: '${entry.key}.$ext',
        ),
      );
    }

    try {
      final streamed = await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamed);
      return _handleResponse(response);
    } on SocketException {
      throw const ApiException(statusCode: 0, message: 'No internet connection.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(statusCode: 0, message: 'Upload failed: ${e.toString()}');
    }
  }

  // ── Response Handler ────────────────────────────────────────
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.body.isEmpty) {
      if (response.statusCode >= 200 && response.statusCode < 300) return {};
      throw ApiException(
          statusCode: response.statusCode, message: 'Empty response');
    }

    Map<String, dynamic> data;
    try {
      data = json.decode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(
          statusCode: response.statusCode,
          message: 'Invalid response format from server');
    }

    if (response.statusCode >= 400) {
      throw ApiException(
        statusCode: response.statusCode,
        message: data['message'] as String? ?? 'Request failed',
        errors: data['errors'] as Map<String, dynamic>?,
      );
    }

    return data;
  }

  // ── Token Refresh ────────────────────────────────────────────
  Future<bool> _refreshToken() async {
    try {
      final token = await getToken();
      if (token == null) return false;

      final uri = Uri.parse('$baseUrl/auth/refresh');
      final response = await http.post(uri, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final newToken = data['token'] as String?;
        if (newToken != null) {
          await setToken(newToken);
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  // ── Helpers ─────────────────────────────────────────────────
  String _guessExtension(List<int> bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) return 'jpg';
    if (bytes.length >= 4 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) return 'png';
    return 'jpg';
  }
}

// ── ApiException ─────────────────────────────────────────────
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? errors;

  const ApiException({
    required this.statusCode,
    required this.message,
    this.errors,
  });

  /// Returns the first validation error message if available
  String get firstError {
    if (errors != null && errors!.isNotEmpty) {
      final first = errors!.values.first;
      if (first is List && first.isNotEmpty) return first.first.toString();
    }
    return message;
  }

  /// Returns all validation errors as a flat string
  String get allErrors {
    if (errors != null && errors!.isNotEmpty) {
      return errors!.values
          .map((e) => (e as List).join(', '))
          .join('\n');
    }
    return message;
  }

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isValidationError => statusCode == 422;
  bool get isServerError => statusCode >= 500;
  bool get isNetworkError => statusCode == 0;

  @override
  String toString() => message;
}

// ── Singleton ────────────────────────────────────────────────
final ApiClient apiClient = ApiClient();