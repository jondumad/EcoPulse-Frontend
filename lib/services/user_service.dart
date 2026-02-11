import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class UserService {
  final AuthService _authService = AuthService();

  String get baseUrl => AuthService.baseUrl;

  Future<List<dynamic>> getAllUsers({String? search, int? roleId}) async {
    final token = await _authService.getToken();
    final queryParams = <String, String>{};
    if (search != null) queryParams['search'] = search;
    if (roleId != null) queryParams['roleId'] = roleId.toString();

    final uri = Uri.parse('$baseUrl/users').replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load users');
    }
  }
}
