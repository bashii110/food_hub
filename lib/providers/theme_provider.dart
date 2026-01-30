import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  final Box settingsBox;
  static const String _themeKey = 'theme_mode';

  ThemeNotifier(this.settingsBox) : super(ThemeMode.system) {
    _loadTheme();
  }

  void _loadTheme() {
    final savedTheme = settingsBox.get(_themeKey, defaultValue: 'system');
    state = _themeModeFromString(savedTheme);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await settingsBox.put(_themeKey, _themeModeToString(mode));
  }

  Future<void> toggleTheme() async {
    final newMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(newMode);
  }

  ThemeMode _themeModeFromString(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      default:
        return 'system';
    }
  }
}

final themeModeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  final settingsBox = Hive.box('settings');
  return ThemeNotifier(settingsBox);
});