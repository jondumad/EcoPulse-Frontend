import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  // Check token on app start
  Future<void> initAuth() async {
    _setLoading(true);
    await refreshProfile();
    _setLoading(false);
  }

  Future<void> refreshProfile() async {
    final user = await _authService.getProfile();
    if (user != null) {
      _user = user;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    _setLoading(true);
    try {
      final result = await _authService.login(email, password);

      if (result['success']) {
        _user = User.fromJson(result['user']);
        notifyListeners();
      }
      return result;
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
    String role,
  ) async {
    _setLoading(true);
    try {
      final result = await _authService.register(name, email, password, role);

      if (result['success']) {
        _user = User.fromJson(result['user']);
        notifyListeners();
      }
      return result;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
