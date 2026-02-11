import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../utils/heading_utils.dart';

class LocationProvider with ChangeNotifier {
  LatLng? _currentPosition;
  bool _isLoading = false;
  String? _error;
  StreamSubscription<Position>? _positionSubscription;
  
  // Sensors & Fusion State
  double? _rawMagnetometerHeading;
  double? _headingAccuracy;
  double _fusedHeading = 0.0;
  double _currentSpeed = 0.0;
  
  // Buffers & History
  final ListQueue<Position> _trajectoryBuffer = ListQueue<Position>(5);
  final AngularBuffer _headingBuffer = AngularBuffer(size: 8);
  
  // Subscriptions
  StreamSubscription<CompassEvent>? _compassSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;

  LatLng? get currentPosition => _currentPosition;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get heading => _fusedHeading;
  double? get headingAccuracy => _headingAccuracy;
  double get speed => _currentSpeed;

  Future<void> init() async {
    await determinePosition();
    startListening();
    startCompassListening();
    startGyroListening();
  }

  void startCompassListening() {
    _compassSubscription?.cancel();
    _compassSubscription = FlutterCompass.events?.listen((event) {
      _rawMagnetometerHeading = event.heading;
      _headingAccuracy = event.accuracy;
      _updateFusion();
    });
  }

  void startGyroListening() {
    _gyroSubscription?.cancel();
    // Gyroscope helps with rapid updates between GPS/Magnetometer samples
    _gyroSubscription = gyroscopeEventStream().listen((event) {
      // event.z is rotational velocity around vertical axis on most phones
      // This is a simplified "dead reckoning" update
      double deltaZ = event.z * (180 / 3.14159) * 0.02; // degrees per 20ms sample
      _fusedHeading = (_fusedHeading - deltaZ + 360) % 360;
      notifyListeners();
    });
  }

  void _updateFusion() {
    double targetHeading = _fusedHeading;

    // RULE 1: GPS Bearing takes priority at speed (> 1.5 m/s)
    if (_currentSpeed > 1.5 && _trajectoryBuffer.length >= 2) {
      final last = _trajectoryBuffer.last;
      final prev = _trajectoryBuffer.elementAt(_trajectoryBuffer.length - 2);
      targetHeading = HeadingUtils.calculateBearing(
        LatLng(prev.latitude, prev.longitude),
        LatLng(last.latitude, last.longitude),
      );
    } 
    // RULE 2: Use calibrated Magnetometer when slow or stationary
    else if (_rawMagnetometerHeading != null) {
      // Only trust magnetometer if accuracy is "acceptable" (< 45)
      if (_headingAccuracy != null && _headingAccuracy! > 0 && _headingAccuracy! < 45) {
        targetHeading = _rawMagnetometerHeading!;
      } else {
        // If uncalibrated, we blend very slowly with the raw compass
        targetHeading = HeadingUtils.lerpAngle(_fusedHeading, _rawMagnetometerHeading!, 0.05);
      }
    }

    _headingBuffer.add(targetHeading);
    
    // Low-pass filter for final output
    _fusedHeading = HeadingUtils.lerpAngle(_fusedHeading, _headingBuffer.average, 0.2);
    notifyListeners();
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

      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        _currentPosition = LatLng(lastKnown.latitude, lastKnown.longitude);
        _updateTrajectory(lastKnown);
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 5),
        ),
      );
      _currentPosition = LatLng(position.latitude, position.longitude);
      _updateTrajectory(position);
    } catch (e) {
      if (_currentPosition == null) _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _updateTrajectory(Position position) {
    _currentSpeed = position.speed;
    
    _trajectoryBuffer.addLast(position);
    if (_trajectoryBuffer.length > 5) {
      _trajectoryBuffer.removeFirst();
    }
    _updateFusion();
  }

  void startListening() {
    _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      _currentPosition = LatLng(position.latitude, position.longitude);
      _updateTrajectory(position);
      notifyListeners();
    });
  }

  void stopListening() {
    _positionSubscription?.cancel();
    _compassSubscription?.cancel();
    _gyroSubscription?.cancel();
    _positionSubscription = null;
    _compassSubscription = null;
    _gyroSubscription = null;
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
