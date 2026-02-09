import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static String get baseUrl {
    if (kReleaseMode) {
      return 'https://chronic-sharia-fonbl-93682891.koyeb.app/api';
    }

    // For local development

    return 'http://localhost:3000/api';
  }

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? _inMemoryToken;

  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
    String role,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': name,
              'email': email,
              'password': password,
              'roleName': role,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        if (data['token'] != null) {
          _inMemoryToken = data['token'];
          // Persist by default for registration or could be optional
          await _storage.write(key: 'jwt_token', value: data['token']);
        }
        return {'success': true, 'user': data['user'], 'token': data['token']};
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Registration failed',
        };
      }
    } on http.ClientException {
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
      };
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Request timed out. Please try again.',
      };
    } catch (e) {
      return {'success': false, 'message': 'An unexpected error occurred: $e'};
    }
  }

  Future<Map<String, dynamic>> login(
    String email,
    String password, {
    bool rememberMe = false,
  }) async {
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
          _inMemoryToken = data['token'];
          if (rememberMe) {
            await _storage.write(key: 'jwt_token', value: data['token']);
          } else {
            // If they previously had a token and unchecked remember me, should we clear it?
            // Yes, for security, if they explicitly don't want to be remembered this time.
            await _storage.delete(key: 'jwt_token');
          }
        }
        return {'success': true, 'user': data['user'], 'token': data['token']};
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Login failed. Check credentials.',
        };
      }
    } on http.ClientException {
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
      };
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Login timed out. Server might be busy.',
      };
    } catch (e) {
      debugPrint('Login error: $e');
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<User?> getProfile() async {
    try {
      final token = await getToken(); // Use modified getToken
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
        // If the token is invalid or expired, clear it
        if (response.statusCode == 401) {
          await logout();
        }
        return null;
      }
    } catch (e) {
      debugPrint('Profile fetch error: $e');
      return null;
    }
  }

  Future<void> logout() async {
    _inMemoryToken = null;
    await _storage.delete(key: 'jwt_token');
  }

  Future<Map<String, dynamic>?> getUserStats() async {
    try {
      final token = await getToken();
      if (token == null) return null;

      final response = await http
          .get(
            Uri.parse('$baseUrl/users/stats'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('User stats fetch error: $e');
      return null;
    }
  }

  Future<String?> getToken() async {
    if (_inMemoryToken != null) return _inMemoryToken;
    _inMemoryToken = await _storage.read(key: 'jwt_token');
    return _inMemoryToken;
  }

  String? getTokenSync() => _inMemoryToken;

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/forgot-password'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Request failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> resetPassword(
    String token,
    String newPassword,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/reset-password'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'token': token, 'newPassword': newPassword}),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Reset failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }
}
