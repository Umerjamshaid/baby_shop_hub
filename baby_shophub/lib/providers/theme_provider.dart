import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ThemeProvider with ChangeNotifier {
  ThemeData _currentTheme = AppTheme.lightTheme;
  ThemeMode _themeMode = ThemeMode.system;

  ThemeData get currentTheme => _currentTheme;
  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
      _currentTheme = AppTheme.darkTheme;
    } else {
      _themeMode = ThemeMode.light;
      _currentTheme = AppTheme.lightTheme;
    }
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    if (mode == ThemeMode.dark) {
      _currentTheme = AppTheme.darkTheme;
    } else {
      _currentTheme = AppTheme.lightTheme;
    }
    notifyListeners();
  }
}
