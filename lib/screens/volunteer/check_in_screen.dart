import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:google_fonts/google_fonts.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/location_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/eco_pulse_widgets.dart';
import '../../widgets/eco_app_bar.dart';

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

class _CheckInScreenState extends State<CheckInScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final MobileScannerController controller = MobileScannerController();
  bool _isProcessing = false;
  bool _isInRange = false;
  bool _mapReady = false;
  int _distance = 0;
  bool _isScanning = false;
  bool _isNavExpanded = false;
  double _currentZoom = 16.0;
  double _currentRotation = 0.0;

  AnimationController? _animationController;

  void _animatedMapMove(ll.LatLng destLocation, double destZoom) {
    if (_animationController?.isAnimating ?? false) {
      _animationController!.stop();
    }

    final camera = _mapController.camera;
    final latTween = Tween<double>(
      begin: camera.center.latitude,
      end: destLocation.latitude,
    );
    final lngTween = Tween<double>(
      begin: camera.center.longitude,
      end: destLocation.longitude,
    );
    final zoomTween = Tween<double>(begin: camera.zoom, end: destZoom);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    final Animation<double> animation = CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeInOutCubic,
    );

    _animationController!.addListener(() {
      _mapController.move(
        ll.LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    _animationController!.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        _animationController!.dispose();
        _animationController = null;
      }
    });

    _animationController!.forward();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initLocation();
    });
  }

  void _initLocation() {
    final loc = Provider.of<LocationProvider>(context, listen: false);
    loc.startListening();
    if (loc.currentPosition != null) {
      _updateGeofence(loc.currentPosition);
    } else {
      loc.determinePosition().then((_) {
        if (mounted) _updateGeofence(loc.currentPosition);
      });
    }
  }

  void _updateGeofence(ll.LatLng? position) {
    if (position == null || widget.missionGps.isEmpty) return;

    final parts = widget.missionGps.split(',');
    if (parts.length != 2) return;
    final mLat = double.tryParse(parts[0]);
    final mLon = double.tryParse(parts[1]);
    if (mLat == null || mLon == null) return;

    final distance = const ll.Distance().as(
      ll.LengthUnit.Meter,
      position,
      ll.LatLng(mLat, mLon),
    );

    setState(() {
      _distance = distance.round();
      _isInRange = distance <= 100; // 100 meters
      // Auto-close scanner if we move out of range
      if (!_isInRange && _isScanning) {
        _isScanning = false;
      }
    });
  }

  void _showEcoSnackBar(
    BuildContext context,
    String message, {
    bool isError = true,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: isError ? EcoColors.terracotta : EcoColors.forest,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _handleCheckIn(String qrToken) async {
    final loc = Provider.of<LocationProvider>(context, listen: false);
    if (!_isInRange || _isProcessing) return;

    setState(() => _isProcessing = true);
    try {
      final userGps =
          '${loc.currentPosition?.latitude},${loc.currentPosition?.longitude}';
      await Provider.of<AttendanceProvider>(
        context,
        listen: false,
      ).checkIn(widget.missionId, qrToken, userGps);

      if (mounted) {
        _showEcoSnackBar(
          context,
          'Check-in successful! Impact recorded.',
          isError: false,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showEcoSnackBar(context, 'Verification failed: ${e.toString()}');
      }
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocationProvider>(
      builder: (context, loc, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _updateGeofence(loc.currentPosition);
        });

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: EcoAppBar(
            height: 100,
            backgroundColor: Colors.transparent,
            titleWidget: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'MISSION VERIFICATION',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: EcoColors.ink.withValues(alpha: 0.5),
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      widget.missionTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.fraunces(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: EcoColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: Stack(
            fit: StackFit.expand,
            children: [
              // Full Screen Map
              if (loc.isLoading)
                const _LoadingOverlay()
              else if (loc.error != null)
                _ErrorOverlay(error: loc.error!, onRetry: loc.determinePosition)
              else
                _buildMap(loc.currentPosition),

              // Dynamic Verification Panel
              Positioned(
                left: 16,
                right: 16,
                bottom: 32,
                child: SafeArea(
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutBack,
                    child: _buildContextualPanel(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContextualPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _getCurrentStateWidget(),
        ),
      ),
    );
  }

  Widget _getCurrentStateWidget() {
    if (_isScanning) {
      return _buildScanningState();
    } else if (_isInRange) {
      return _buildProximityState();
    } else {
      return _buildNavigationState();
    }
  }

  Widget _buildNavigationState() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _isNavExpanded = !_isNavExpanded),
        child: Container(
          key: const ValueKey('nav_state'),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: EcoColors.terracotta.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.location_on_outlined,
                      color: EcoColors.terracotta,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'APPROACH SITE',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: EcoColors.ink.withValues(alpha: 0.5),
                            letterSpacing: 1.0,
                          ),
                        ),
                        Text(
                          '$_distance meters away',
                          style: GoogleFonts.fraunces(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: EcoColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 300),
                    turns: _isNavExpanded ? 0.25 : 0,
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: EcoColors.ink.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
              if (_isNavExpanded) ...[
                const SizedBox(height: 24),
                // Feature: Verification Steps
                _buildSectionHeader('YOUR PROGRESS'),
                const SizedBox(height: 12),
                _buildStepItem(
                  'Reach Site',
                  'Walk to the coordinate point',
                  _isInRange,
                  icon: Icons.directions_walk,
                ),
                // Proximity Progress Bar (Visual Feature)
                if (!_isInRange)
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 48,
                      top: 4,
                      bottom: 12,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (1000 - _distance.clamp(0, 1000)) / 900,
                        backgroundColor: EcoColors.ink.withValues(alpha: 0.05),
                        valueColor: const AlwaysStoppedAnimation(
                          EcoColors.terracotta,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ),
                _buildStepItem(
                  'Locate Coordinator',
                  'Find the mission flag/QR code',
                  false,
                  icon: Icons.qr_code_scanner,
                ),
                _buildStepItem(
                  'Verify Scan',
                  'Scanner unlocks automatically',
                  false,
                  icon: Icons.verified_user_outlined,
                ),

                const SizedBox(height: 24),
                _buildSectionHeader('QUICK ACTIONS'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        'Directions',
                        Icons.map_outlined,
                        () {
                          // Simulated external link logic
                          _showEcoSnackBar(
                            context,
                            'Opening External Maps...',
                            isError: false,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        'Locate Flag',
                        Icons.flag_outlined,
                        () {
                          final parts = widget.missionGps.split(',');
                          if (parts.length == 2) {
                            _animatedMapMove(
                              ll.LatLng(
                                double.tryParse(parts[0]) ?? 0,
                                double.tryParse(parts[1]) ?? 0,
                              ),
                              16.0,
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  'Need Help? Contact Coordinator',
                  Icons.support_agent,
                  () => _showEcoSnackBar(
                    context,
                    'Coordinator notified of your location.',
                    isError: false,
                  ),
                  isFullWidth: true,
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: EcoColors.ink.withValues(alpha: 0.4),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Divider(color: EcoColors.ink.withValues(alpha: 0.1))),
      ],
    );
  }

  Widget _buildStepItem(
    String title,
    String subtitle,
    bool isDone, {
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDone
                  ? EcoColors.forest.withValues(alpha: 0.1)
                  : EcoColors.ink.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDone ? Icons.check : icon,
              size: 16,
              color: isDone
                  ? EcoColors.forest
                  : EcoColors.ink.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: isDone ? EcoColors.forest : EcoColors.ink,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: EcoColors.ink.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    VoidCallback onTap, {
    bool isFullWidth = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: EcoColors.ink.withValues(alpha: 0.1)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: isFullWidth
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: EcoColors.ink),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: EcoColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProximityState() {
    return Container(
      key: const ValueKey('prox_state'),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: EcoColors.forest.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              size: 32,
              color: EcoColors.forest,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'You have arrived!',
            style: GoogleFonts.fraunces(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: EcoColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You are within range of the coordination point. Ready to verify?',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: EcoColors.ink.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: EcoPulseButton(
              label: 'START VERIFICATION',
              onPressed: () => setState(() => _isScanning = true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanningState() {
    return Container(
      key: const ValueKey('scan_state'),
      height: 400, // Fixed height for scanner
      color: Colors.black,
      child: Stack(
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
          // Heritage Overlay
          CustomPaint(
            painter: ScannerOverlay(
              _isProcessing ? EcoColors.violet : EcoColors.forest,
            ),
            child: Container(),
          ),
          // Close Button
          Positioned(
            top: 16,
            right: 16,
            child: GestureDetector(
              onTap: () => setState(() => _isScanning = false),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ),
          // Loading Indicator
          if (_isProcessing)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      'Verifying...',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Hint Text
          if (!_isProcessing)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Scan the Mission QR Code',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMap(ll.LatLng? currentPosition) {
    final parts = widget.missionGps.split(',');
    final missionLatLng = parts.length == 2
        ? ll.LatLng(
            double.tryParse(parts[0]) ?? 0,
            double.tryParse(parts[1]) ?? 0,
          )
        : const ll.LatLng(0, 0);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: missionLatLng,
                initialZoom: 16.0,
                minZoom: 3.0,
                maxZoom: 18.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
                onMapEvent: (event) {
                  if (mounted) setState(() {});
                },
                onMapReady: () {
                  if (mounted) setState(() => _mapReady = true);
                },
                onPositionChanged: (pos, hasGesture) {
                  if (pos.zoom != _currentZoom ||
                      pos.rotation != _currentRotation) {
                    setState(() {
                      _currentZoom = pos.zoom;
                      _currentRotation = pos.rotation;
                    });
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.civic',
                ),
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: missionLatLng,
                      radius: 100,
                      useRadiusInMeter: true,
                      color: EcoColors.forest.withValues(alpha: 0.05),
                      borderColor: EcoColors.forest.withValues(alpha: 0.3),
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    // Mission Marker
                    Marker(
                      point: missionLatLng,
                      width: _currentZoom >= 14 ? 40 : 20,
                      height: _currentZoom >= 14 ? 40 : 20,
                      rotate: true,
                      child: _currentZoom >= 14
                          ? Container(
                              decoration: const BoxDecoration(
                                color: EcoColors.forest,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.flag,
                                color: Colors.white,
                                size: 20,
                              ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                color: EcoColors.forest,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                    ),
                    // User Marker
                    if (currentPosition != null)
                      Marker(
                        point: currentPosition,
                        width: _currentZoom >= 14 ? 30 : 15,
                        height: _currentZoom >= 14 ? 30 : 15,
                        rotate: true,
                        child: _currentZoom >= 14
                            ? Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: AppTheme.violet.withValues(
                                        alpha: 0.2,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: EcoColors.violet,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: EcoColors.violet,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                      ),
                  ],
                ),
              ],
            ),
            _buildOffScreenIndicators(
              constraints,
              missionLatLng,
              currentPosition,
            ),
          ],
        );
      },
    );
  }

  Widget _buildOffScreenIndicators(
    BoxConstraints constraints,
    ll.LatLng missionLatLng,
    ll.LatLng? userLatLng,
  ) {
    if (!_mapReady) return const SizedBox.shrink();
    final camera = _mapController.camera;
    if (camera.zoom == 0) return const SizedBox.shrink();

    // Calculate dynamic bottom padding to avoid the floating card
    double bottomPadding = 180.0; // Collapsed Nav
    if (_isScanning) {
      bottomPadding = 460.0;
    } else if (_isInRange) {
      bottomPadding = 320.0;
    } else if (_isNavExpanded) {
      bottomPadding = 560.0;
    }

    List<Widget> indicators = [];

    // Mission Indicator
    final missionIndicator = _getIndicatorWidget(
      missionLatLng,
      camera,
      constraints,
      EcoColors.forest,
      Icons.flag,
      bottomPadding,
    );
    if (missionIndicator != null) indicators.add(missionIndicator);

    // User Indicator
    if (userLatLng != null) {
      final userIndicator = _getIndicatorWidget(
        userLatLng,
        camera,
        constraints,
        EcoColors.violet,
        Icons.person,
        bottomPadding,
        offsetIfOverlapping:
            missionIndicator != null, // Simple boolean flag for now
      );
      if (userIndicator != null) indicators.add(userIndicator);
    }

    return Stack(children: indicators);
  }

  Widget? _getIndicatorWidget(
    ll.LatLng point,
    MapCamera camera,
    BoxConstraints constraints,
    Color color,
    IconData icon,
    double bottomPadding, {
    bool offsetIfOverlapping = false,
  }) {
    final screenPoint = camera.latLngToScreenOffset(point);

    const horizontalPadding = 45.0;
    const topPadding = 120.0; // Below App Bar

    final safeZone = Rect.fromLTRB(
      0,
      topPadding - 20, // Slight buffer
      constraints.maxWidth,
      constraints.maxHeight - bottomPadding + 20, // Buffer near card
    );

    // Indicator logic: Show if outside visible safe zone (not just strictly off-screen)
    if (safeZone.contains(screenPoint)) return null;

    final center = Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);

    final rect = Rect.fromLTRB(
      horizontalPadding,
      topPadding,
      constraints.maxWidth - horizontalPadding,
      constraints.maxHeight - bottomPadding,
    );

    final edgePoint = _calculateIntersection(center, screenPoint, rect);
    final angle = math.atan2(
      screenPoint.dy - center.dy,
      screenPoint.dx - center.dx,
    );

    // Apply basic offset if requested to avoid overlapping
    // In a real scenario, we'd check distance between indicators.
    // Here we assume if 'overlapping' flag is true, we shift it slightly.
    Offset finalPos = edgePoint;
    if (offsetIfOverlapping) {
      // Shift slightly to the right/down to "stack" it visually
      // A simple offset avoids perfect coverage
      finalPos = Offset(edgePoint.dx + 12, edgePoint.dy + 12);
    }

    final bool isZoomedOut = camera.zoom < 14;

    return Positioned(
      left: finalPos.dx - 22,
      top: finalPos.dy - 22,
      child: GestureDetector(
        onTap: () => _animatedMapMove(point, 16.0),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Arrow Indicator (Behind the circle visually if desired, or just positioned)
              Transform.translate(
                offset: Offset(
                  math.cos(angle) * 26, // Distance from center
                  math.sin(angle) * 26,
                ),
                child: Transform.rotate(
                  angle: angle + (math.pi / 2),
                  child: CustomPaint(
                    size: const Size(12, 8),
                    painter: _PointerPainter(color),
                  ),
                ),
              ),
              // Main Circle - changes when zoomed out
              Container(
                width: isZoomedOut ? 24 : 40,
                height: isZoomedOut ? 24 : 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: isZoomedOut
                    ? null
                    : Icon(icon, color: Colors.white, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Offset _calculateIntersection(Offset center, Offset point, Rect rect) {
    final dx = point.dx - center.dx;
    final dy = point.dy - center.dy;

    if (dx == 0 && dy == 0) return center;

    double tMin = double.infinity;

    if (dx > 0) {
      tMin = math.min(tMin, (rect.right - center.dx) / dx);
    } else if (dx < 0) {
      tMin = math.min(tMin, (rect.left - center.dx) / dx);
    }

    if (dy > 0) {
      tMin = math.min(tMin, (rect.bottom - center.dy) / dy);
    } else if (dy < 0) {
      tMin = math.min(tMin, (rect.top - center.dy) / dy);
    }

    return Offset(center.dx + tMin * dx, center.dy + tMin * dy);
  }
}

class _PointerPainter extends CustomPainter {
  final Color color;
  _PointerPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(strokeWidth: 2, color: EcoColors.forest),
          SizedBox(height: 16),
          Text(
            'Triangulating Signal...',
            style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ErrorOverlay extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorOverlay({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
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
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: EcoColors.ink),
            ),
            const SizedBox(height: 16),
            EcoPulseButton(
              label: 'RETRY POSITIONING',
              onPressed: onRetry,
              isSmall: true,
            ),
          ],
        ),
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
      ..color = Colors.black.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    const scanArea = 220.0;
    final left = (size.width - scanArea) / 2;
    final top = (size.height / 2) - (scanArea / 2);
    final rect = Rect.fromLTWH(left, top, scanArea, scanArea);

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()
          ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(32))),
      ),
      paint,
    );

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    // Draw corners only for a premium look
    const cornerLength = 30.0;
    final path = Path();

    // Top Left
    path.moveTo(left, top + cornerLength);
    path.lineTo(left, top);
    path.lineTo(left + cornerLength, top);

    // Top Right
    path.moveTo(left + scanArea - cornerLength, top);
    path.lineTo(left + scanArea, top);
    path.lineTo(left + scanArea, top + cornerLength);

    // Bottom Right
    path.moveTo(left + scanArea, top + scanArea - cornerLength);
    path.lineTo(left + scanArea, top + scanArea);
    path.lineTo(left + scanArea - cornerLength, top + scanArea);

    // Bottom Left
    path.moveTo(left + cornerLength, top + scanArea);
    path.lineTo(left, top + scanArea);
    path.lineTo(left, top + scanArea - cornerLength);

    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
