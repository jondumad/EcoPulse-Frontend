import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';

class AuthService {
  static String get baseUrl {
    if (kReleaseMode) {
      return 'https://chronic-sharia-fonbl-93682891.koyeb.app/api';
    }
    // Using localhost works for Web and Physical Android devices (via adb reverse tcp:3000 tcp:3000)
    return 'http://localhost:3000/api';
  }

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
    String role,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'roleName': role,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        if (data['token'] != null) {
          await _storage.write(key: 'jwt_token', value: data['token']);
        }
        return {'success': true, 'user': data['user'], 'token': data['token']};
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      debugPrint('Attempting login to: $baseUrl/auth/login');
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('Login response status: ${response.statusCode}');
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data['token'] != null) {
          await _storage.write(key: 'jwt_token', value: data['token']);
        }
        return {'success': true, 'user': data['user'], 'token': data['token']};
      } else {
        return {'success': false, 'message': data['error'] ?? 'Login failed'};
      }
    } catch (e) {
      debugPrint('Login error: $e');
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<User?> getProfile() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) return null;

      debugPrint('Refreshing profile from: $baseUrl/auth/me');
      final response = await http
          .get(
            Uri.parse('$baseUrl/auth/me'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('Profile response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('Profile fetch error: $e');
      return null;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }
}
