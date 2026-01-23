import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'auth_service.dart';

class AttendanceService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String get baseUrl => AuthService.baseUrl;

  Future<Map<String, dynamic>> validateLocation(int missionId, String userGps) async {
    final token = await _storage.read(key: 'jwt_token');
    final response = await http.post(
      Uri.parse('$baseUrl/attendance/validate-location'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'missionId': missionId,
        'userGps': userGps,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to validate location');
    }
  }

  Future<Map<String, dynamic>> getQRCode(int missionId) async {
    final token = await _storage.read(key: 'jwt_token');
    final response = await http.get(
      Uri.parse('$baseUrl/attendance/missions/$missionId/qr-code'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Failed to get QR code');
    }
  }

  Future<Map<String, dynamic>> checkIn(int missionId, String qrToken, String userGps) async {
    final token = await _storage.read(key: 'jwt_token');
    final response = await http.post(
      Uri.parse('$baseUrl/attendance/check-in'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'missionId': missionId,
        'qrToken': qrToken,
        'userGps': userGps,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Failed to check in');
    }
  }

  Future<Map<String, dynamic>> checkOut(int missionId) async {
    final token = await _storage.read(key: 'jwt_token');
    final response = await http.post(
      Uri.parse('$baseUrl/attendance/check-out'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'missionId': missionId,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Failed to check out');
    }
  }

  Future<Map<String, dynamic>?> getCurrentAttendance() async {
    final token = await _storage.read(key: 'jwt_token');
    final response = await http.get(
      Uri.parse('$baseUrl/attendance/current'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      if (response.body.isEmpty || response.body == 'null') return null;
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get current attendance');
    }
  }

  Future<List<dynamic>> getPendingVerifications() async {
    final token = await _storage.read(key: 'jwt_token');
    final response = await http.get(
      Uri.parse('$baseUrl/attendance/pending'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load pending verifications');
    }
  }

  Future<bool> verifyAttendance(int attendanceId, String status) async {
    final token = await _storage.read(key: 'jwt_token');
    final response = await http.put(
      Uri.parse('$baseUrl/attendance/$attendanceId/verify'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'status': status,
      }),
    );

    return response.statusCode == 200;
  }
}
