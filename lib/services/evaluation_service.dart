import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/evaluation_model.dart';
import 'auth_service.dart';

class EvaluationService {
  static String get baseUrl => '${AuthService.baseUrl}/evaluations';

  static Future<List<EvaluationCategory>> getCategories(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/categories'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => EvaluationCategory.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load evaluation categories');
    }
  }

  static Future<List<VolunteerSummary>> getVolunteers(String token, {int? missionId}) async {
    final url = missionId != null 
        ? '$baseUrl/volunteers?missionId=$missionId'
        : '$baseUrl/volunteers';
        
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => VolunteerSummary.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load volunteers for evaluation');
    }
  }

  static Future<void> submitEvaluation({
    required String token,
    required int evaluateeId,
    required int missionId,
    required String comments,
    required List<Map<String, dynamic>> items,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/sessions'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'evaluateeId': evaluateeId,
        'missionId': missionId,
        'comments': comments,
        'items': items,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to submit evaluation: ${response.body}');
    }
  }

  static Future<List<EvaluationSession>> getMyEvaluations(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/my-evaluations'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => EvaluationSession.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load evaluations list');
    }
  }
}
