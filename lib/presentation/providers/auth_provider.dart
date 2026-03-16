import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../data/services/api_client.dart';

// ── AppUser model ─────────────────────────────────────────────
class AppUser {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? address;
  final String? profileImageUrl;
  final bool isActive;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.address,
    this.profileImageUrl,
    this.isActive = true,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: (json['id'] as num).toInt(),
    name: json['name'] as String,
    email: json['email'] as String,
    role: json['role'] as String? ?? 'user',
    phone: json['phone'] as String?,
    address: json['address'] as String?,
    profileImageUrl: json['profile_image'] as String?,
    isActive: json['is_active'] as bool? ?? true,
  );

  bool get isAdmin => role == 'admin';
  bool get isStaff => role == 'admin' || role == 'staff';
  bool get isRider => role == 'rider';

  AppUser copyWith({
    String? name,
    String? phone,
    String? address,
    String? profileImageUrl,
  }) =>
      AppUser(
        id: id,
        name: name ?? this.name,
        email: email,
        role: role,
        phone: phone ?? this.phone,
        address: address ?? this.address,
        profileImageUrl: profileImageUrl ?? this.profileImageUrl,
        isActive: isActive,
      );
}

// ── Auth State ────────────────────────────────────────────────
enum AuthStatus { idle, loading, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final AppUser? user;
  final String? error;

  const AuthState({
    this.status = AuthStatus.idle,
    this.user,
    this.error,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    String? error,
  }) =>
      AuthState(
        status: status ?? this.status,
        user: user ?? this.user,
        error: error,
      );
}

// ── Hive cart box helper ──────────────────────────────────────
Future<void> _openCartBox(int userId) async {
  final boxName = 'cart_$userId';
  if (!Hive.isBoxOpen(boxName)) {
    await Hive.openBox<dynamic>(boxName);
  }
}

Future<void> _closeCartBox(int userId) async {
  final boxName = 'cart_$userId';
  if (Hive.isBoxOpen(boxName)) {
    await Hive.box<dynamic>(boxName).close();
  }
}

// ── AuthNotifier ──────────────────────────────────────────────
class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    // Restore session on app start
    final token = await apiClient.getToken();
    if (token == null) {
      return const AuthState(status: AuthStatus.unauthenticated);
    }

    try {
      final res = await apiClient.get('/auth/me');
      final user = AppUser.fromJson(res['user'] as Map<String, dynamic>);

      // ── Re-open this user's cart box for the restored session ──
      await _openCartBox(user.id);

      return AuthState(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      await apiClient.clearToken();
      return const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  // ── Register ─────────────────────────────────────────────────
  Future<void> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    state = const AsyncValue.data(AuthState(status: AuthStatus.loading));
    try {
      final res = await apiClient.post('/auth/register', body: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      });

      await apiClient.setToken(res['token'] as String);
      final user = AppUser.fromJson(res['user'] as Map<String, dynamic>);

      // ── Open cart box for the newly registered user ────────────
      await _openCartBox(user.id);

      state = AsyncValue.data(
          AuthState(status: AuthStatus.authenticated, user: user));
    } on ApiException catch (e) {
      state = AsyncValue.data(AuthState(
          status: AuthStatus.unauthenticated, error: e.firstError));
    } catch (e) {
      state = AsyncValue.data(AuthState(
          status: AuthStatus.unauthenticated, error: e.toString()));
    }
  }

  // ── Login ─────────────────────────────────────────────────────
  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.data(AuthState(status: AuthStatus.loading));
    try {
      final res = await apiClient.post('/auth/login', body: {
        'email': email,
        'password': password,
      });

      await apiClient.setToken(res['token'] as String);
      final user = AppUser.fromJson(res['user'] as Map<String, dynamic>);

      // ── Open this user's isolated cart box ─────────────────────
      await _openCartBox(user.id);

      state = AsyncValue.data(
          AuthState(status: AuthStatus.authenticated, user: user));
    } on ApiException catch (e) {
      state = AsyncValue.data(AuthState(
          status: AuthStatus.unauthenticated, error: e.message));
    } catch (e) {
      state = AsyncValue.data(AuthState(
          status: AuthStatus.unauthenticated, error: e.toString()));
    }
  }

  // ── Logout ────────────────────────────────────────────────────
  Future<void> logout() async {
    // ── Close this user's cart box before clearing session ────────
    final userId = state.value?.user?.id;
    if (userId != null) {
      await _closeCartBox(userId);
    }

    try {
      await apiClient.post('/auth/logout');
    } catch (_) {}
    await apiClient.clearToken();
    state = const AsyncValue.data(
        AuthState(status: AuthStatus.unauthenticated));
  }

  // ── Update Profile ────────────────────────────────────────────
  Future<String?> updateProfile({
    String? name,
    String? phone,
    String? address,
    String? currentPassword,
    String? newPassword,
    List<int>? profileImageBytes,
  }) async {
    try {
      Map<String, dynamic> result;

      if (profileImageBytes != null) {
        final fields = <String, String>{
          if (name != null) 'name': name,
          if (phone != null) 'phone': phone,
          if (address != null) 'address': address,
          if (currentPassword != null) 'current_password': currentPassword,
          if (newPassword != null) 'new_password': newPassword,
          if (newPassword != null) 'new_password_confirmation': newPassword,
          '_method': 'PUT',
        };
        result = await apiClient.postMultipart(
          '/auth/profile',
          fields,
          {'profile_image': profileImageBytes},
        );
      } else {
        final body = <String, dynamic>{
          if (name != null) 'name': name,
          if (phone != null) 'phone': phone,
          if (address != null) 'address': address,
          if (currentPassword != null) 'current_password': currentPassword,
          if (newPassword != null) 'new_password': newPassword,
          if (newPassword != null) 'new_password_confirmation': newPassword,
        };
        result = await apiClient.put('/auth/profile', body: body);
      }

      final user = AppUser.fromJson(result['user'] as Map<String, dynamic>);
      state = AsyncValue.data(
          AuthState(status: AuthStatus.authenticated, user: user));
      return null; // success
    } on ApiException catch (e) {
      return e.firstError;
    } catch (e) {
      return e.toString();
    }
  }

  // ── Forgot Password ───────────────────────────────────────────
  Future<String> forgotPassword({required String email}) async {
    try {
      final res = await apiClient
          .post('/auth/forgot-password', body: {'email': email});
      return res['message'] as String? ?? 'Reset link sent';
    } on ApiException catch (e) {
      return e.message;
    }
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);