import 'package:flutter/material.dart';

enum UserRole {
  caregiver,
  patient,
}

enum AppLanguage {
  english,
  hindi,
}

class AppStateProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool _isHighContrast = false;
  UserRole _currentRole = UserRole.caregiver;
  AppLanguage _language = AppLanguage.english;
  double _fontScale = 1.0;

  ThemeMode get themeMode => _themeMode;
  bool get isHighContrast => _isHighContrast;
  UserRole get currentRole => _currentRole;
  AppLanguage get language => _language;
  double get fontScale => _fontScale;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void toggleHighContrast(bool value) {
    _isHighContrast = value;
    if (value) {
      _fontScale = 1.15;
    } else {
      _fontScale = 1.0;
    }
    notifyListeners();
  }

  void switchRole(UserRole role) {
    _currentRole = role;
    if (role == UserRole.patient) {
      _fontScale = 1.1; // Slightly larger for patient readability
    } else {
      _fontScale = 1.0;
    }
    notifyListeners();
  }

  void setLanguage(AppLanguage lang) {
    _language = lang;
    notifyListeners();
  }

  void setFontScale(double scale) {
    _fontScale = scale;
    notifyListeners();
  }
}
