import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../services/auth_service.dart';

class BadgeProvider with ChangeNotifier {
  List<BadgeInfo> _allBadges = [];
  bool _isLoading = false;

  List<BadgeInfo> get allBadges => _allBadges;
  bool get isLoading => _isLoading;

  final AuthService _authService = AuthService();

  Future<void> fetchAllBadges() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _authService.getToken();
      if (token == null) return;

      final response = await http
          .get(
            Uri.parse('${AuthService.baseUrl}/badges'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _allBadges = data.map((b) => BadgeInfo.fromJson(b)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching badges: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
