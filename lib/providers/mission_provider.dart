import 'package:flutter/material.dart';
import '../models/mission_model.dart';
import '../services/mission_service.dart';

class MissionProvider with ChangeNotifier {
  final MissionService _missionService = MissionService();

  List<Mission> _missions = [];
  bool _isLoading = false;
  String? _error;

  List<Mission> get missions => _missions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchMissions({String? category, String? search}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _missions = await _missionService.getMissions(
        category: category,
        search: search,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleRegistration(
    int missionId,
    bool currentlyRegistered,
  ) async {
    _error = null;
    notifyListeners();

    try {
      bool success;
      if (currentlyRegistered) {
        success = await _missionService.cancelRegistration(missionId);
      } else {
        success = await _missionService.registerForMission(missionId);
      }

      if (success) {
        // Refresh the specific mission or the whole list
        // For simplicity, refetch the missions list
        await fetchMissions();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> createMission(Map<String, dynamic> missionData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _missionService.createMission(missionData);
      await fetchMissions(); // Refresh list
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
