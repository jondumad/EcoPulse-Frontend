import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/mission_model.dart';
import '../services/mission_service.dart';

class MissionProvider with ChangeNotifier {
  final MissionService _missionService = MissionService();

  List<Mission> _missions = [];
  List<Category> _categories = [];
  bool _isLoading = false;
  String? _error;
  LatLng? _userLocation;

  List<Mission> get missions => _missions;
  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  LatLng? get userLocation => _userLocation;

  void updateUserLocation(LatLng? location) {
    if (_userLocation != location) {
      _userLocation = location;
      notifyListeners();
    }
  }

  // Filter & Sort State
  String _searchQuery = '';
  String _sortOption = 'Date'; // 'Date', 'Fill Rate', 'Status'
  final Set<String> _activeFilters = {'All'};
  // Default to showing relevant stuff

  DateTime? _lastFetchTime;
  bool _lastFetchMine = false;
  static const Duration _cacheDuration = Duration(minutes: 5);

  List<Mission>? _upcomingMissionsCache;
  List<Mission>? _recommendedMissionsCache;

  List<Mission> get upcomingMissions {
    if (_upcomingMissionsCache != null) return _upcomingMissionsCache!;
    _upcomingMissionsCache =
        _missions.where((m) => m.isRegistered && m.status == 'Open').toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));
    return _upcomingMissionsCache!;
  }

  List<Mission> get recommendedMissions {
    if (_recommendedMissionsCache != null) return _recommendedMissionsCache!;
    _recommendedMissionsCache = _missions
        .where((m) => m.status == 'Open' && !m.isRegistered)
        .take(10)
        .toList();
    return _recommendedMissionsCache!;
  }

  void _clearCaches() {
    _upcomingMissionsCache = null;
    _recommendedMissionsCache = null;
  }

  List<Mission> get filteredMissions {
    // ... existing filtering logic (keeping it for the Mission Hub)
    final filtered = _missions.where((m) {
      // 1. Search Filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesTitle = m.title.toLowerCase().contains(query);
        final matchesLocation = m.locationName.toLowerCase().contains(query);
        if (!matchesTitle && !matchesLocation) return false;
      }

      // 2. Status/Type Filter
      if (_activeFilters.contains('All') || _activeFilters.isEmpty) return true;

      bool matchesStatus = false;
      if (_activeFilters.contains('Emergency') && m.isEmergency) {
        matchesStatus = true;
      } else if (_activeFilters.contains('Active') &&
          (m.status == 'Open' || m.status == 'InProgress')) {
        matchesStatus = true;
      } else if (_activeFilters.contains('Completed') &&
          m.status == 'Completed') {
        matchesStatus = true;
      } else if (_activeFilters.contains('Cancelled') &&
          m.status == 'Cancelled') {
        matchesStatus = true;
      }

      return matchesStatus;
    }).toList();

    // 3. Sorting
    filtered.sort((a, b) {
      switch (_sortOption) {
        case 'Volunteer fill rate':
          final aRate = (a.maxVolunteers != null && a.maxVolunteers! > 0)
              ? a.currentVolunteers / a.maxVolunteers!
              : 0.0;
          final bRate = (b.maxVolunteers != null && b.maxVolunteers! > 0)
              ? b.currentVolunteers / b.maxVolunteers!
              : 0.0;
          return bRate.compareTo(aRate); // Higher rate first

        case 'Distance':
          if (_userLocation == null) return 0;

          double getDistance(Mission m) {
            if (m.locationGps == null || m.locationGps!.isEmpty) {
              return double.infinity;
            }
            try {
              final parts = m.locationGps!.split(',');
              if (parts.length != 2) return double.infinity;
              final lat = double.parse(parts[0].trim());
              final lng = double.parse(parts[1].trim());
              return const Distance().as(
                LengthUnit.Meter,
                _userLocation!,
                LatLng(lat, lng),
              );
            } catch (_) {
              return double.infinity;
            }
          }

          return getDistance(a).compareTo(getDistance(b));

        case 'Status':
          // Custom order: Emergency -> Open -> InProgress -> Completed -> Cancelled
          final statusOrder = {
            'Emergency': 0,
            'Open': 1,
            'InProgress': 2,
            'Completed': 3,
            'Cancelled': 4,
          };

          final aScore = a.isEmergency ? 0 : (statusOrder[a.status] ?? 5);
          final bScore = b.isEmergency ? 0 : (statusOrder[b.status] ?? 5);
          return aScore.compareTo(bScore);

        case 'Date':
        default:
          return a.startTime.compareTo(b.startTime);
      }
    });

    return filtered;
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSortOption(String option) {
    _sortOption = option;
    notifyListeners();
  }

  void toggleFilter(String filter) {
    if (filter == 'All') {
      _activeFilters.clear();
      _activeFilters.add('All');
    } else {
      _activeFilters.remove('All');
      if (_activeFilters.contains(filter)) {
        _activeFilters.remove(filter);
      } else {
        _activeFilters.add(filter);
      }

      if (_activeFilters.isEmpty) {
        _activeFilters.add('All');
      }
    }
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _activeFilters.clear();
    _activeFilters.add('All');
    notifyListeners();
  }

  bool isFilterActive(String filter) {
    if (filter == 'All') {
      return _activeFilters.contains('All') || _activeFilters.isEmpty;
    }
    return _activeFilters.contains(filter);
  }

  String get currentSort => _sortOption;

  Future<void> fetchMissions({
    String? category,
    String? search,
    bool mine = false,
    bool forceRefresh = false,
  }) async {
    // Cache check
    if (!forceRefresh &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheDuration &&
        _missions.isNotEmpty &&
        category == null &&
        search == null &&
        _lastFetchMine == mine) {
      return; // Return cached data
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _missions = await _missionService.getMissions(
        category: category,
        search: search,
        mine: mine,
      );
      _clearCaches();
      _lastFetchTime = DateTime.now();
      _lastFetchMine = mine;
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
      debugPrint('Error fetching categories: $e');
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
        await fetchMissions(forceRefresh: true);
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
      await fetchMissions(forceRefresh: true); // Refresh list
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
      _clearCaches();
      await fetchMissions(forceRefresh: true); // Refresh the list
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
      await fetchMissions(forceRefresh: true); // Refresh the list
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

  Future<void> batchAction(List<int> ids, String action) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _missionService.batchAction(ids, action);
      await fetchMissions(forceRefresh: true);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> duplicateMission(int missionId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _missionService.duplicateMission(missionId);
      await fetchMissions(forceRefresh: true);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> inviteToMission(int missionId) async {
    try {
      return await _missionService.inviteToMission(missionId);
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  Future<void> contactVolunteers(int missionId, String message) async {
    try {
      await _missionService.contactVolunteers(missionId, message);
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }
}
