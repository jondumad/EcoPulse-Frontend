import 'package:flutter/material.dart';
import '../services/attendance_service.dart';
import 'mission_provider.dart';
import 'base_provider.dart';

class AttendanceProvider extends BaseProvider {
  final AttendanceService _service = AttendanceService();
  final MissionProvider? missionProvider;
  Map<String, dynamic>? currentAttendance;
  bool _isLoading = false;

  AttendanceProvider({this.missionProvider});

  bool get isLoading => _isLoading;

  Future<void> refresh() async {
    _isLoading = true;
    safeNotifyListeners();
    try {
      currentAttendance = await _service.getCurrentAttendance();
    } catch (e) {
      currentAttendance = null;
    } finally {
      _isLoading = false;
      safeNotifyListeners();
    }
  }

  Future<Map<String, dynamic>> checkIn(
    int missionId,
    String qrToken,
    String userGps,
  ) async {
    _isLoading = true;
    safeNotifyListeners();
    try {
      final result = await _service.checkIn(missionId, qrToken, userGps);
      currentAttendance = result['attendance'];

      // Refresh both providers for global sync
      await refresh();
      if (missionProvider != null) {
        await missionProvider!.fetchMissions(forceRefresh: true);
      }

      return result;
    } finally {
      _isLoading = false;
      safeNotifyListeners();
    }
  }

  Future<void> checkOut(int missionId) async {
    _isLoading = true;
    safeNotifyListeners();
    try {
      await _service.checkOut(missionId);
      currentAttendance = null;

      // Ensure mission list reflects checkout (points, status)
      if (missionProvider != null) {
        await missionProvider!.fetchMissions(forceRefresh: true);
      }
    } finally {
      _isLoading = false;
      safeNotifyListeners();
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
