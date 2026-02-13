import 'package:flutter/material.dart';
import '../services/attendance_service.dart';

class AttendanceProvider with ChangeNotifier {
  final AttendanceService _service = AttendanceService();
  Map<String, dynamic>? _currentAttendance;
  bool _isLoading = false;

  Map<String, dynamic>? get currentAttendance => _currentAttendance;
  bool get isLoading => _isLoading;

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    try {
      _currentAttendance = await _service.getCurrentAttendance();
    } catch (e) {
      _currentAttendance = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> checkIn(
    int missionId,
    String qrToken,
    String userGps,
  ) async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await _service.checkIn(missionId, qrToken, userGps);
      _currentAttendance = result['attendance'];
      await refresh(); // To get mission details
      return result;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> checkOut(int missionId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.checkOut(missionId);
      _currentAttendance = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> validateLocation(
    int missionId,
    String userGps,
  ) async {
    return await _service.validateLocation(missionId, userGps);
  }

  Future<Map<String, dynamic>> getQRCode(int missionId) async {
    return await _service.getQRCode(missionId);
  }

  Future<List<dynamic>> getPendingVerifications() async {
    return await _service.getPendingVerifications();
  }

  Future<bool> verifyAttendance(int attendanceId, String status) async {
    final success = await _service.verifyAttendance(attendanceId, status);
    return success;
  }

  Future<bool> manualCheckIn(int missionId, int userId, String reason) async {
    return await _service.manualCheckIn(missionId, userId, reason);
  }

  Future<bool> manualComplete(int missionId, int userId, String reason) async {
    return await _service.manualComplete(missionId, userId, reason);
  }
}
