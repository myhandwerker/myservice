// lib/modules/settings/theme_notifier.dart

import 'package:flutter/material.dart';

class ThemeNotifier extends ChangeNotifier {
  ThemeData _themeData; // Uygulamanın şu anki tema verisi

  // Kurucu: Başlangıç tema verisini alır
  ThemeNotifier(this._themeData);

  // themeData getter: Tema verisini dışarıya açar
  ThemeData get themeData => _themeData;

  // Temayı yeni bir ThemeData nesnesiyle güncelleyen metod
  void updateThemeData(ThemeData newThemeData) {
    _themeData = newThemeData;
    notifyListeners(); // Tema değiştiğinde dinleyicilere haber ver
  }
}
