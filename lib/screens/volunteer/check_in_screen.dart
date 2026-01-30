import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../../providers/attendance_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/eco_pulse_widgets.dart';

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
  StreamSubscription<ServiceStatus>? _serviceStatusStream;
  bool _isInRange = false;
  int _distance = 0;
  bool _isLoadingLocation = true;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _initLocation();
    try {
      _serviceStatusStream = Geolocator.getServiceStatusStream().listen((
        status,
      ) {
        if (status == ServiceStatus.enabled) {
          _initLocation();
        }
      });
    } catch (_) {
      // Service status stream not supported on this platform
    }
  }

  Future<void> _initLocation() async {
    if (mounted) {
      setState(() {
        _locationError = null;
        _isLoadingLocation = true;
      });
    }

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        setState(() {
          _locationError = 'Location services are disabled.';
          _isLoadingLocation = false;
        });
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          setState(() {
            _locationError = 'Location permission denied.';
            _isLoadingLocation = false;
          });
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() {
          _locationError = 'Location permissions are permanently denied.';
          _isLoadingLocation = false;
        });
      }
      return;
    }

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
    _serviceStatusStream?.cancel();
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
          SizedBox(
            height: 250,
            child: Stack(
              children: [
                _isLoadingLocation
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text(
                              'Ascertaining location...',
                              style: TextStyle(fontFamily: 'JetBrains Mono'),
                            ),
                          ],
                        ),
                      )
                    : _locationError != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.location_off,
                                size: 48,
                                color: EcoColors.terracotta,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _locationError!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: EcoColors.ink),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _initLocation,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _buildMap(),

                // Overlay Status Info
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isInRange ? Icons.check_circle : Icons.location_on,
                          color: _isInRange
                              ? EcoColors.forest
                              : EcoColors.terracotta,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isInRange ? 'In Range ✓' : '$_distance meters away',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'JetBrains Mono',
                          ),
                        ),
                      ],
                    ),
                  ),
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
                        fit: BoxFit.cover,
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
                      Positioned.fill(
                        child: CustomPaint(
                          painter: ScannerOverlay(
                            AppTheme.primaryGreen.withValues(alpha: 0.5),
                          ),
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

  Widget _buildMap() {
    final parts = widget.missionGps.split(',');
    final missionLatLng = parts.length == 2
        ? ll.LatLng(
            double.tryParse(parts[0]) ?? 0,
            double.tryParse(parts[1]) ?? 0,
          )
        : const ll.LatLng(0, 0);

    final userLatLng = _currentPosition != null
        ? ll.LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : missionLatLng;

    return FlutterMap(
      options: MapOptions(initialCenter: missionLatLng, initialZoom: 16.0),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.civic',
        ),
        CircleLayer(
          circles: [
            CircleMarker(
              point: missionLatLng,
              radius: 100, // 100 meters
              useRadiusInMeter: true,
              color: EcoColors.forest.withValues(alpha: 0.1),
              borderColor: EcoColors.forest,
              borderStrokeWidth: 2,
            ),
          ],
        ),
        MarkerLayer(
          markers: [
            // Mission Marker
            Marker(
              point: missionLatLng,
              width: 30,
              height: 30,
              child: const Icon(Icons.flag, color: EcoColors.forest),
            ),
            // User Marker
            if (_currentPosition != null)
              Marker(
                point: userLatLng,
                width: 20,
                height: 20,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.fromBorderSide(
                      BorderSide(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
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
