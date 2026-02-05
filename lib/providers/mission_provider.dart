import 'package:flutter/material.dart';
import '../models/mission_model.dart';
import '../services/mission_service.dart';

class MissionProvider with ChangeNotifier {
  final MissionService _missionService = MissionService();

  List<Mission> _missions = [];
  List<Category> _categories = [];
  bool _isLoading = false;
  String? _error;

  List<Mission> get missions => _missions;
  List<Category> get categories => _categories;
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

  Future<void> fetchCategories() async {
    try {
      _categories = await _missionService.getCategories();
      notifyListeners();
    } catch (e) {
      // Silently fail or log, as categories aren't critical to block everything
      print('Error fetching categories: $e');
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

  Future<List<Map<String, dynamic>>> fetchRegistrations(int missionId) async {
    // We don't necessarily need to store this in the provider state if it's specific to one screen,
    // but the pattern suggests keeping logic here.
    try {
      return await _missionService.getMissionRegistrations(missionId);
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  Future<void> updateMission(
    int missionId,
    Map<String, dynamic> updateData,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _missionService.updateMission(missionId, updateData);
      await fetchMissions(); // Refresh the list
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateMissionStatus(int missionId, String status) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _missionService.updateMissionStatus(missionId, status);
      await fetchMissions(); // Refresh the list
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> manualCheckIn(int missionId, int userId) async {
    try {
      await _missionService.manualCheckIn(missionId, userId);
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  Future<void> manualComplete(int missionId, int userId) async {
    try {
      await _missionService.manualComplete(missionId, userId);
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }
}
