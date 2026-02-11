import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

class HeadingUtils {
  /// Applies a low-pass filter to a stream of values.
  /// Higher alpha (0.0 to 1.0) means more weight to the new value (less smoothing).
  static double lowPass(double newValue, double oldValue, double alpha) {
    return oldValue + alpha * (newValue - oldValue);
  }

  /// Calculates the shortest angular distance between two headings.
  static double angularDistance(double a, double b) {
    double diff = (b - a + 180) % 360 - 180;
    return diff < -180 ? diff + 360 : diff;
  }

  /// Correctly averages angles by handling the 360/0 wraparound.
  /// Uses circular mean logic (sum of sines and cosines).
  static double averageAngles(List<double> angles) {
    if (angles.isEmpty) return 0.0;
    
    double sinSum = 0;
    double cosSum = 0;
    
    for (double angle in angles) {
      double rad = angle * (math.pi / 180.0);
      sinSum += math.sin(rad);
      cosSum += math.cos(rad);
    }
    
    double avgRad = math.atan2(sinSum, cosSum);
    double avgDeg = avgRad * (180.0 / math.pi);
    
    return (avgDeg + 360) % 360;
  }

  /// Calculates the bearing (heading) between two coordinates.
  static double calculateBearing(LatLng start, LatLng end) {
    double lat1 = start.latitude * (math.pi / 180.0);
    double lon1 = start.longitude * (math.pi / 180.0);
    double lat2 = end.latitude * (math.pi / 180.0);
    double lon2 = end.longitude * (math.pi / 180.0);

    double dLon = lon2 - lon1;

    double y = math.sin(dLon) * math.cos(lat2);
    double x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    double bearingRad = math.atan2(y, x);
    return (bearingRad * (180.0 / math.pi) + 360) % 360;
  }

  /// Smoothly interpolates between two angles handling wraparound.
  static double lerpAngle(double a, double b, double t) {
    double diff = angularDistance(a, b);
    return (a + diff * t + 360) % 360;
  }
}

/// A simple moving average buffer for angular data.
class AngularBuffer {
  final int size;
  final List<double> _buffer = [];

  AngularBuffer({this.size = 10});

  void add(double angle) {
    _buffer.add(angle);
    if (_buffer.length > size) {
      _buffer.removeAt(0);
    }
  }

  double get average => HeadingUtils.averageAngles(_buffer);
  
  bool get isFull => _buffer.length >= size;
  bool get isEmpty => _buffer.isEmpty;
}
