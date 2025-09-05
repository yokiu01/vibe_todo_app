import 'package:flutter/material.dart';
import '../models/theme_config.dart';

class ThemeProvider with ChangeNotifier {
  AppTheme _currentTheme = AppTheme.white;
  bool _isDarkMode = false;

  AppTheme get currentTheme => _currentTheme;
  bool get isDarkMode => _isDarkMode;

  ThemeData get lightTheme {
    final config = ThemeConfig.getTheme(AppTheme.white);
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Color(int.parse(config.accentColor.substring(1), radix: 16) + 0xFF000000),
        brightness: Brightness.light,
        primary: Color(int.parse(config.primaryColor.substring(1), radix: 16) + 0xFF000000),
        surface: Color(int.parse(config.surfaceColor.substring(1), radix: 16) + 0xFF000000),
        background: Color(int.parse(config.backgroundColor.substring(1), radix: 16) + 0xFF000000),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: const CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    );
  }

  ThemeData get darkTheme {
    final config = ThemeConfig.getTheme(AppTheme.dark);
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Color(int.parse(config.accentColor.substring(1), radix: 16) + 0xFF000000),
        brightness: Brightness.dark,
        primary: Color(int.parse(config.primaryColor.substring(1), radix: 16) + 0xFF000000),
        surface: Color(int.parse(config.surfaceColor.substring(1), radix: 16) + 0xFF000000),
        background: Color(int.parse(config.backgroundColor.substring(1), radix: 16) + 0xFF000000),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: const CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    );
  }

  void setTheme(AppTheme theme) {
    _currentTheme = theme;
    _isDarkMode = theme == AppTheme.dark;
    notifyListeners();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _currentTheme = _isDarkMode ? AppTheme.dark : AppTheme.white;
    notifyListeners();
  }
}
