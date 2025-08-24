import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// アプリ全体のダーク / ライト設定を保持・保存するプロバイダー
class ThemeNotifier extends ChangeNotifier {
  static const _prefKey = 'theme_mode';
  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  ThemeNotifier() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(_prefKey);
    if (saved != null) {
      _mode = ThemeMode.values[saved];
      notifyListeners();
    }
  }

  Future<void> update(ThemeMode newMode) async {
    _mode = newMode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt(_prefKey, newMode.index); // 保持
  }
}
