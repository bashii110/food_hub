import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../presentation/providers/auth_provider.dart';
import '../presentation/providers/profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),

        // Only show error for real server errors (500 etc.)
        // 401 is handled silently by returning null from the provider
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64,
                  color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              const Text('Failed to load profile'),
              const SizedBox(height: 8),
              Text(error.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => ref.invalidate(profileProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),

        data: (profile) {
          // null means logged out — show nothing (AppRoot will redirect)
          if (profile == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final phone = profile.phone;
          final address = profile.address;
          final hasPhone = phone != null && phone.isNotEmpty;
          final hasAddress = address != null && address.isNotEmpty;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),

                // ── AVATAR ──────────────────────────────────
                _Avatar(
                  imageUrl: profile.imageUrl, // uses imageUrl directly
                  name: profile.name,
                ),

                const SizedBox(height: 20),

                // ── NAME ────────────────────────────────────
                Text(
                  profile.name,
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),

                // ── EMAIL ───────────────────────────────────
                Text(
                  profile.email,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
                ),

                const SizedBox(height: 32),

                // ── DETAILS CARD ────────────────────────────
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      if (hasPhone)
                        _DetailTile(
                          icon: Icons.phone_outlined,
                          label: 'Phone',
                          value: phone!,
                        ),
                      if (hasAddress) ...[
                        if (hasPhone) const Divider(height: 1, indent: 56),
                        _DetailTile(
                          icon: Icons.location_on_outlined,
                          label: 'Address',
                          value: address!,
                        ),
                      ],
                      if (hasPhone || hasAddress)
                        const Divider(height: 1, indent: 56),
                      _DetailTile(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: profile.email,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // ── LOGOUT BUTTON ────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .error
                          .withOpacity(0.1),
                      foregroundColor:
                      Theme.of(context).colorScheme.error,
                      padding:
                      const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.logout_outlined),
                    label: const Text('Logout',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      final confirmed = await _confirmLogout(context);
                      if (!confirmed) return;

                      // Call logout first — clears token + updates authProvider
                      await ref.read(authProvider.notifier).logout();

                      // ProfileScreen is pushed on top of HomeScreen via
                      // Navigator.push, so AppRoot rebuilding is not visible
                      // until we pop back. Pop everything so AppRoot shows.
                      if (context.mounted) {
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
                      }
                    },
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}

/* ─────────────────────────────────────────────────────────────
   HELPER WIDGETS
   ───────────────────────────────────────────────────────────── */

class _Avatar extends StatelessWidget {
  const _Avatar({required this.imageUrl, required this.name});

  final String? imageUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    final hasImage = url != null && url.isNotEmpty;

    return CircleAvatar(
      radius: 60,
      backgroundColor:
      Theme.of(context).colorScheme.primary.withOpacity(0.2),
      backgroundImage: hasImage ? NetworkImage(url) : null,
      onBackgroundImageError: hasImage ? (_, __) {} : null,
      child: hasImage
          ? null
          : Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withOpacity(0.6),
          )),
      subtitle: Text(value,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontWeight: FontWeight.w600)),
    );
  }
}

Future<bool> _confirmLogout(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Logout'),
      content: const Text('Are you sure you want to log out?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error),
          child: const Text('Logout'),
        ),
      ],
    ),
  );
  return result ?? false;
}