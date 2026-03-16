import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'home/splash_screen.dart';
import 'presentation/auth/login_screen.dart';
import 'home/homescreen.dart';
import 'home/admin/admin_dashboard_screen.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/food_provider_api.dart';

/// AppRoot — Authentication-aware router.
///
/// Routes:
///   Loading              → SplashScreen
///   Error / No user      → LoginScreen
///   role: admin | staff  → AdminDashboardScreen
///   role: user | rider   → HomeScreen
class AppRoot extends ConsumerWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authProvider);

    return authAsync.when(
      loading: () => const SplashScreen(),
      error: (_, __) => const LoginScreen(),
      data: (state) {
        if (!state.isAuthenticated || state.user == null) {
          // ── Reset search & category so next user starts clean ──
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(searchQueryProvider.notifier).state = '';
            ref.read(selectedCategoryProvider.notifier).state = 'All';
          });
          return const LoginScreen();
        }

        final role = state.user!.role;

        // Blocked user — force logout, show login
        if (!state.user!.isActive) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(authProvider.notifier).logout();
          });
          return const LoginScreen();
        }

        if (role == 'admin' || role == 'staff') {
          return const AdminDashboardScreen();
        }

        return const HomeScreen();
      },
    );
  }
}