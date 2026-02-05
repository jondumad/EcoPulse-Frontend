import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'auth_service.dart';
import '../models/mission_model.dart';

class MissionService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String get baseUrl => AuthService.baseUrl;

  Future<List<Mission>> getMissions({String? category, String? search}) async {
    final token = await _storage.read(key: 'jwt_token');

    final queryParams = <String, String>{};
    if (category != null) queryParams['category'] = category;
    if (search != null) queryParams['search'] = search;

    final uri = Uri.parse(
      '$baseUrl/missions',
    ).replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Mission.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load missions');
    }
  }

  Future<Mission> getMissionById(int id) async {
    final token = await _storage.read(key: 'jwt_token');
    final response = await http.get(
      Uri.parse('$baseUrl/missions/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return Mission.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load mission details');
    }
  }

  Future<bool> registerForMission(int missionId) async {
    final token = await _storage.read(key: 'jwt_token');
    final response = await http.post(
      Uri.parse('$baseUrl/missions/$missionId/register'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return true;
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Registration failed');
    }
  }

  Future<bool> cancelRegistration(int missionId) async {
    final token = await _storage.read(key: 'jwt_token');
    final response = await http.delete(
      Uri.parse('$baseUrl/missions/$missionId/register'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Cancellation failed');
    }
  }

  Future<Mission> createMission(Map<String, dynamic> missionData) async {
    final token = await _storage.read(key: 'jwt_token');
    final response = await http.post(
      Uri.parse('$baseUrl/missions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(missionData),
    );

    if (response.statusCode == 201) {
      return Mission.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create mission');
    }
  }

  Future<List<Map<String, dynamic>>> getMissionRegistrations(
    int missionId,
  ) async {
    final token = await _storage.read(key: 'jwt_token');
    final response = await http.get(
      Uri.parse('$baseUrl/missions/$missionId/registrations'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load mission registrations');
    }
  }

  Future<Mission> updateMissionStatus(int missionId, String status) async {
    final token = await _storage.read(key: 'jwt_token');
    final response = await http.put(
      Uri.parse('$baseUrl/missions/$missionId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode == 200) {
      return Mission.fromJson(jsonDecode(response.body));
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Failed to update mission status');
    }
  }

  Future<void> manualCheckIn(int missionId, int userId) async {
    final token = await _storage.read(key: 'jwt_token');
    final response = await http.post(
      Uri.parse(
        '$baseUrl/attendance/missions/$missionId/participants/$userId/check-in',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Failed to check in participant');
    }
  }

  Future<void> manualComplete(int missionId, int userId) async {
    final token = await _storage.read(key: 'jwt_token');
    final response = await http.post(
      Uri.parse(
        '$baseUrl/attendance/missions/$missionId/participants/$userId/complete',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(
        errorData['error'] ?? 'Failed to mark participant as completed',
      );
    }
  }

  Future<Mission> updateMission(
    int missionId,
    Map<String, dynamic> updateData,
  ) async {
    final token = await _storage.read(key: 'jwt_token');
    final response = await http.put(
      Uri.parse('$baseUrl/missions/$missionId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(updateData),
    );

    if (response.statusCode == 200) {
      return Mission.fromJson(jsonDecode(response.body));
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Failed to update mission');
    }
  }

  Future<List<Category>> getCategories() async {
    final token = await _storage.read(key: 'jwt_token');
    final url = '$baseUrl/missions/categories';
    debugPrint('Fetching categories from: $url');

    try {
      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('Categories response status: ${response.statusCode}');
      debugPrint('Categories response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Category.fromJson(json)).toList();
      } else {
        throw Exception(
          'Failed to load categories (Status: ${response.statusCode})',
        );
      }
    } catch (e) {
      debugPrint('Categories fetch error: $e');
      throw Exception('Failed to load categories: $e');
    }
  }
}
