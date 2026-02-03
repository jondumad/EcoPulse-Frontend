import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/notification_model.dart';
import 'auth_service.dart';

class NotificationService {
  String get baseUrl => '${AuthService.baseUrl}/notifications';
  final AuthService _authService = AuthService();

  Future<List<NotificationModel>> getNotifications() async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('No token found');

    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => NotificationModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch notifications');
    }
  }

  Future<void> markAsRead(int id) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('No token found');

    final response = await http.patch(
      Uri.parse('$baseUrl/$id/read'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark notification as read');
    }
  }

  Future<void> markAllAsRead() async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('No token found');

    final response = await http.patch(
      Uri.parse('$baseUrl/read-all'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark all notifications as read');
    }
  }
}
