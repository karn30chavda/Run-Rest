import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/storage_service.dart';

enum AppThemeMode {
  system,
  light,
  dark,
  amoled;

  String get displayName {
    switch (this) {
      case AppThemeMode.system:
        return 'System Default';
      case AppThemeMode.light:
        return 'Light Theme';
      case AppThemeMode.dark:
        return 'Dark Charcoal';
      case AppThemeMode.amoled:
        return 'AMOLED Pure Black';
    }
  }
}

class ThemeProvider extends ChangeNotifier {
  final StorageService _storage;
  AppThemeMode _mode = AppThemeMode.dark;
  Color _accentColor = const Color(0xFF10B981); // Emerald

  static const List<Color> availableAccents = [
    Color(0xFF10B981), // Emerald
    Color(0xFF06B6D4), // Cyan
    Color(0xFFF97316), // Coral Orange
    Color(0xFF8B5CF6), // Royal Purple
    Color(0xFFF59E0B), // Solar Amber
    Color(0xFFEF4444), // Crimson
    Color(0xFF14B8A6), // Teal
  ];

  ThemeProvider(this._storage) {
    _loadFromStorage();
  }

  AppThemeMode get mode => _mode;
  Color get accentColor => _accentColor;

  void _loadFromStorage() {
    final modeStr = _storage.loadThemeMode();
    _mode = AppThemeMode.values.firstWhere(
      (m) => m.name == modeStr,
      orElse: () => AppThemeMode.dark,
    );
    final accentVal = _storage.loadAccentColorValue();
    _accentColor = Color(accentVal);
    notifyListeners();
  }

  void setThemeMode(AppThemeMode newMode) {
    if (_mode == newMode) return;
    _mode = newMode;
    _storage.saveThemeMode(newMode.name);
    notifyListeners();
  }

  void setAccentColor(Color color) {
    if (_accentColor == color) return;
    _accentColor = color;
    _storage.saveAccentColorValue(color.toARGB32());
    notifyListeners();
  }

  ThemeData getLightTheme() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _accentColor,
        brightness: Brightness.light,
        primary: _accentColor,
        surface: const Color(0xFFF8FAF9),
      ),
      scaffoldBackgroundColor: const Color(0xFFF1F4F2),
      cardColor: Colors.white,
    );

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE2E8E4), width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }

  ThemeData getDarkTheme() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _accentColor,
        brightness: Brightness.dark,
        primary: _accentColor,
        surface: const Color(0xFF19221C),
      ),
      scaffoldBackgroundColor: const Color(0xFF101713),
      cardColor: const Color(0xFF19221C),
    );

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      cardTheme: CardThemeData(
        color: const Color(0xFF19221C),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF2B3A30), width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }

  ThemeData getAmoledTheme() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _accentColor,
        brightness: Brightness.dark,
        primary: _accentColor,
        surface: const Color(0xFF0A0A0A),
      ),
      scaffoldBackgroundColor: Colors.black,
      cardColor: const Color(0xFF0F0F0F),
    );

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      cardTheme: CardThemeData(
        color: const Color(0xFF0E0E0E),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.shade900, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }

  ThemeMode getThemeMode() {
    switch (_mode) {
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
      case AppThemeMode.amoled:
        return ThemeMode.dark;
    }
  }

  ThemeData getActiveTheme(BuildContext context) {
    if (_mode == AppThemeMode.amoled) {
      return getAmoledTheme();
    }
    if (_mode == AppThemeMode.light) {
      return getLightTheme();
    }
    if (_mode == AppThemeMode.dark) {
      return getDarkTheme();
    }
    final isDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    return isDark ? getDarkTheme() : getLightTheme();
  }
}
