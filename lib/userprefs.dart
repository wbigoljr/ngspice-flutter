// Author: Wilfredo Bigol Jr.
// Description: This is a Flutter app demonstrating the usage of NGSpice shared library using Dart FFI.

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class ThemePreferences {
  static const darkModeThemeKey = "darkThemeKey";

  setTheme(bool value) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setBool(darkModeThemeKey, value);
  }

  getTheme() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return sharedPreferences.getBool(darkModeThemeKey) ?? false;
  }
}

class ThemeNotifier extends ChangeNotifier {

  late bool _isDark;
  late ThemePreferences _preferences;
  bool get isDark => _isDark;

  ThemeData _themeData;

  ThemeNotifier(this._themeData) {
    _isDark = false;
    _preferences = ThemePreferences();
    getPreferences();
  }

  ThemeData get themeData => _themeData;

  void setTheme(ThemeData theme, bool isDark) {
    _themeData = theme;
    _preferences.setTheme(isDark);
    notifyListeners();
  }
  
  getPreferences() async {
    _isDark = await _preferences.getTheme();
    notifyListeners();
  }
}