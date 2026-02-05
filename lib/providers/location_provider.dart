import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationProvider with ChangeNotifier {
  LatLng? _currentPosition;
  bool _isLoading = false;
  String? _error;
  StreamSubscription<Position>? _positionSubscription;

  LatLng? get currentPosition => _currentPosition;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> init() async {
    await determinePosition();
    startListening();
  }

  Future<void> determinePosition() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _error = 'Location services are disabled.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _error = 'Location permissions are denied.';
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _error = 'Location permissions are permanently denied.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      _currentPosition = LatLng(position.latitude, position.longitude);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void startListening() {
    _positionSubscription?.cancel();
    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen((Position position) {
          _currentPosition = LatLng(position.latitude, position.longitude);
          notifyListeners();
        });
  }

  void stopListening() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }

  String getDistanceLabel(String? missionGps) {
    if (_currentPosition == null || missionGps == null || missionGps.isEmpty) {
      return 'Nearby';
    }

    try {
      final parts = missionGps.split(',');
      if (parts.length != 2) return 'Nearby';

      final missionLatLng = LatLng(
        double.parse(parts[0].trim()),
        double.parse(parts[1].trim()),
      );

      final distance = const Distance().as(
        LengthUnit.Meter,
        _currentPosition!,
        missionLatLng,
      );

      if (distance < 1000) {
        return '${distance.round()}m';
      } else {
        return '${(distance / 1000).toStringAsFixed(1)}km';
      }
    } catch (e) {
      return 'Nearby';
    }
  }
}
