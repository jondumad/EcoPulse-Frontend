import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_compass/flutter_compass.dart';

class LocationProvider with ChangeNotifier {
  LatLng? _currentPosition;
  bool _isLoading = false;
  String? _error;
  StreamSubscription<Position>? _positionSubscription;
  
  // Compass state
  double? _heading;
  double? _headingAccuracy;
  StreamSubscription<CompassEvent>? _compassSubscription;

  LatLng? get currentPosition => _currentPosition;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double? get heading => _heading;
  double? get headingAccuracy => _headingAccuracy;

  Future<void> init() async {
    await determinePosition();
    startListening();
    startCompassListening();
  }

  void startCompassListening() {
    _compassSubscription?.cancel();
    _compassSubscription = FlutterCompass.events?.listen((event) {
      // Detailed logging to pinpoint unreliability
      if (_headingAccuracy != event.accuracy) {
        debugPrint('Compass Accuracy Update: ${event.accuracy} (Heading: ${event.heading})');
        
        if (event.accuracy == -1) {
          debugPrint('Compass Alert: Sensor reported -1 (Hardware/Permission issue)');
        } else if (event.accuracy != null && event.accuracy! > 45) {
          debugPrint('Compass Alert: Accuracy dropped below threshold (> 45)');
        }
      }

      _heading = event.heading;
      _headingAccuracy = event.accuracy;
      notifyListeners();
    });
  }

  void stopCompassListening() {
    _compassSubscription?.cancel();
    _compassSubscription = null;
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

      // 1. Try to get last known position first (incredibly fast)
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        _currentPosition = LatLng(
          (lastKnown.latitude as num).toDouble(),
          (lastKnown.longitude as num).toDouble(),
        );
        notifyListeners(); // Update UI immediately with cached position
      }

      // 2. Request fresh position with timeout and medium accuracy for speed
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium, // Much faster than high
          timeLimit: Duration(seconds: 5), // Don't wait forever
        ),
      );
      _currentPosition = LatLng(
        (position.latitude as num).toDouble(),
        (position.longitude as num).toDouble(),
      );
    } catch (e) {
      // Only set error if we don't have any position at all
      if (_currentPosition == null) {
        _error = e.toString();
      }
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
          _currentPosition = LatLng(
            (position.latitude as num).toDouble(),
            (position.longitude as num).toDouble(),
          );
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
