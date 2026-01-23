import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../providers/attendance_provider.dart';
import '../../theme/app_theme.dart';

class CheckInScreen extends StatefulWidget {
  final int missionId;
  final String missionTitle;
  final String missionGps;

  const CheckInScreen({
    super.key,
    required this.missionId,
    required this.missionTitle,
    required this.missionGps,
  });

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool _isProcessing = false;
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;
  bool _isInRange = false;
  int _distance = 0;
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5,
          ),
        ).listen((Position position) {
          if (mounted) {
            setState(() {
              _currentPosition = position;
              _isLoadingLocation = false;
              _updateGeofence(position);
            });
          }
        });
  }

  void _updateGeofence(Position position) {
    if (widget.missionGps.isEmpty) return;
    final parts = widget.missionGps.split(',');
    if (parts.length != 2) return;
    final mLat = double.tryParse(parts[0]);
    final mLon = double.tryParse(parts[1]);
    if (mLat == null || mLon == null) return;

    final distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      mLat,
      mLon,
    );

    setState(() {
      _distance = distance.round();
      _isInRange = distance <= 100; // 100 meters
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    controller.dispose();
    super.dispose();
  }

  Future<void> _handleCheckIn(String qrToken) async {
    if (!_isInRange || _isProcessing) return;

    setState(() => _isProcessing = true);
    try {
      final userGps =
          '${_currentPosition?.latitude},${_currentPosition?.longitude}';
      await Provider.of<AttendanceProvider>(
        context,
        listen: false,
      ).checkIn(widget.missionId, qrToken, userGps);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully checked in!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Check-in failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Check-In: ${widget.missionTitle}')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: AppTheme.primaryGreen.withValues(alpha: 0.1),
            child: _isLoadingLocation
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      Icon(
                        _isInRange ? Icons.check_circle : Icons.location_on,
                        size: 48,
                        color: _isInRange ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isInRange ? 'In Range ✓' : '$_distance meters away',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (!_isInRange)
                        const Text(
                          'Move closer to the mission location to scan QR',
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
          ),
          Expanded(
            child: !_isInRange
                ? const Center(child: Text('Scanning disabled until in range.'))
                : Stack(
                    children: [
                      MobileScanner(
                        controller: controller,
                        onDetect: (capture) {
                          final List<Barcode> barcodes = capture.barcodes;
                          for (final barcode in barcodes) {
                            if (barcode.rawValue != null) {
                              _handleCheckIn(barcode.rawValue!);
                              break;
                            }
                          }
                        },
                      ),
                      CustomPaint(
                        painter: ScannerOverlay(
                          AppTheme.primaryGreen.withValues(alpha: 0.5),
                        ),
                      ),
                      if (_isProcessing)
                        const Center(child: CircularProgressIndicator()),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class ScannerOverlay extends CustomPainter {
  final Color borderColor;
  ScannerOverlay(this.borderColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    const scanArea = 250.0;
    final left = (size.width - scanArea) / 2;
    final top = (size.height - scanArea) / 2;
    final rect = Rect.fromLTWH(left, top, scanArea, scanArea);

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()
          ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(12))),
      ),
      paint,
    );

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(12)),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
