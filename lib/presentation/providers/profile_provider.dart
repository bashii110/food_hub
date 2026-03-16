import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/api_client.dart';
import '../providers/auth_provider.dart';

// ══════════════════════════════════════════════════════════════
// USER PROFILE MODEL
// ══════════════════════════════════════════════════════════════
class UserProfile {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? address;
  final String? imageUrl;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    this.imageUrl,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      imageUrl: json['image'] as String?,
    );
  }
}

// ══════════════════════════════════════════════════════════════
// PROFILE PROVIDER
//
// KEY FIX: watches authProvider so when the user logs out or a
// different account logs in, this provider automatically
// re-evaluates and fetches the correct user's profile.
// Previously it only checked for a token, meaning the cached
// result from User A would still show after User B logged in.
// ══════════════════════════════════════════════════════════════
final profileProvider = FutureProvider<UserProfile?>((ref) async {
  // Watch auth state — this is what makes the provider re-run
  // whenever the logged-in user changes (login, logout, switch account).
  final authState = ref.watch(authProvider);

  // Still loading auth — wait
  if (authState.isLoading) return null;

  // Get the current user from auth state
  final currentUser = authState.value?.user;

  // Not authenticated — return null immediately, no API call needed
  if (currentUser == null) return null;

  try {
    final response = await apiClient.get('/auth/me');
    final userData = response.containsKey('user')
        ? response['user'] as Map<String, dynamic>
        : response;
    return UserProfile.fromJson(userData);
  } on ApiException catch (e) {
    // 401 = token expired or logged out — return null silently
    if (e.statusCode == 401 || e.statusCode == 0) return null;
    rethrow;
  } catch (_) {
    return null;
  }
});