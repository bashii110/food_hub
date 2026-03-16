import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_hub/presentation/providers/theme_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'app_root.dart';
import 'components/theme/apptheme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  // ── Wipe ALL stale Hive cart box files ────────────────────────
  // This covers:
  //   'cart'        — the old shared box (no user isolation)
  //   'cart_1'      — per-user boxes that may have been written
  //   'cart_2'        by an old TypeAdapter and are now unreadable
  //   'cart_N' ...
  // Safe to run every launch — if files don't exist it's a no-op.
  await _deleteAllStaleCartBoxes();

  // Only settings is opened at startup.
  // Per-user cart boxes are opened in auth_provider on login/session restore.
  await Hive.openBox('settings');

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