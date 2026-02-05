import 'package:flutter/material.dart';

class NavProvider extends ChangeNotifier {
  int _selectedIndex = 1; // Default to Home

  int get selectedIndex => _selectedIndex;

  void setIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }
}
