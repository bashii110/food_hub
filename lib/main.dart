import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_hub/presentation/providers/theme_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'app_root.dart';
import 'components/theme/apptheme.dart';

// BUGFIX (was silently deleting every user's cart on every cold start):
// this key marks the one-time Hive cart migration as done. It must only
// ever run once per install.
const String _kCartMigrationDoneKey = 'cart_v2_migration_done';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  // Settings box has to be open first — the one-time migration flag below
  // lives in it.
  final settingsBox = await Hive.openBox('settings');

  // ── One-time migration: wipe stale Hive cart box files ────────────
  // This covers:
  //   'cart'        — the old shared box (no user isolation)
  //   'cart_1'      — per-user boxes that may have been written
  //   'cart_2'        by an old TypeAdapter and are now unreadable
  //   'cart_N' ...
  //
  // BUGFIX: this used to run unconditionally on every single app launch,
  // which meant every user's cart was silently emptied every time they
  // restarted the app. It is now gated behind a flag stored in the
  // settings box so it only ever runs once per install, exactly as a
  // migration should.
  if (settingsBox.get(_kCartMigrationDoneKey, defaultValue: false) != true) {
    await _deleteAllStaleCartBoxes();
    await settingsBox.put(_kCartMigrationDoneKey, true);
  }

  // BUGFIX: cart_provider.dart resolves the cart's Hive box name as
  // 'cart_<userId>', falling back to 'cart_guest' whenever there is no
  // logged-in user yet (which is true for a moment on every cold start,
  // while authProvider is still resolving the session, and for anyone
  // browsing before logging in). cartRepositoryProvider() throws a
  // StateError if that box isn't already open — and nothing was ever
  // opening 'cart_guest'. Depending on how/where that exception surfaces,
  // it can look exactly like "the cart got wiped" even though the actual
  // per-user cart data on disk is untouched. Open it here unconditionally
  // so that path can never throw, regardless of timing.
  if (!Hive.isBoxOpen('cart_guest')) {
    await Hive.openBox<dynamic>('cart_guest');
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const ProviderScope(child: MyApp()));
}

/// Deletes the old shared 'cart' box AND any 'cart_<userId>' boxes
/// that may have been created with the old TypeAdapter.
/// After this runs, Hive will create fresh plain-Map boxes on next open.
/// Only ever invoked once — see the migration guard in main() above.
Future<void> _deleteAllStaleCartBoxes() async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final boxDir = Directory(dir.path);

    // List every file in the Hive directory
    final files = boxDir.listSync();

    for (final file in files) {
      if (file is File) {
        final name = file.uri.pathSegments.last; // e.g. "cart.hive", "cart_1.hive"
        // Match 'cart.hive', 'cart.lock', 'cart_1.hive', 'cart_1.lock', etc.
        if (name.startsWith('cart') &&
            (name.endsWith('.hive') || name.endsWith('.lock'))) {
          try {
            await file.delete();
          } catch (_) {}
        }
      }
    }
  } catch (_) {
    // Never crash on cleanup failure
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Food Delivery',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const AppRoot(),
    );
  }
}
