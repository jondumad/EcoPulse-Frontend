import 'package:flutter/material.dart';
import 'base_provider.dart';

class NavProvider extends BaseProvider {
  int _selectedIndex = 1; // Default to Home

  int get selectedIndex => _selectedIndex;

  void setIndex(int index) {
    _selectedIndex = index;
    safeNotifyListeners();
  }
}
