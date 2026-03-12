import 'package:flutter/material.dart';
import '../../main.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:google_fonts/google_fonts.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/mission_provider.dart';
import '../../providers/location_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/eco_pulse_widgets.dart';
import '../../widgets/atoms/eco_button.dart';
import '../../widgets/eco_app_bar.dart';
import '../../utils/map_utils.dart';

// Componentised sub-widgets
import '../../widgets/check_in/check_in_map.dart';
import '../../widgets/check_in/check_in_scanner.dart';
import '../../widgets/check_in/check_in_panels.dart';
import '../../widgets/check_in/check_in_overlays.dart';

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
  late MapAnimationHelper _mapAnimationHelper;
  final MobileScannerController controller = MobileScannerController();
  bool _isProcessing = false;
  bool _isInRange = false;
  final bool _mapReady = false;
  int _distance = 0;
  bool _isScanning = false;
  bool _isNavExpanded = false;
  final double _currentZoom = 16.0;
  final ValueNotifier<double> _zoomNotifier = ValueNotifier(16.0);
  final ValueNotifier<double> _rotationNotifier = ValueNotifier(0.0);
  LocationProvider? _locProvider;

  void _animatedMapMove(ll.LatLng destLocation, double destZoom) {
    _mapAnimationHelper.move(destLocation, destZoom);
  }

  @override
  void initState() {
    super.initState();
    _mapAnimationHelper = MapAnimationHelper(
      mapController: _mapController,
      vsync: this,
    );

    final loc = Provider.of<LocationProvider>(context, listen: false);
    _locProvider = loc;

    loc.startListening();
    if (loc.currentPosition != null) {
      _updateGeofence(loc.currentPosition);
    } else {
      loc.determinePosition().then((_) {
        if (mounted) _updateGeofence(loc.currentPosition);
      });
    }

    loc.addListener(_onLocationChanged);
  }

  void _onLocationChanged() {
    final loc = _locProvider;
    if (loc != null && mounted) {
      _updateGeofence(loc.currentPosition);
    }
  }

  @override
  void dispose() {
    final loc = _locProvider;
    if (loc != null) {
      loc.removeListener(_onLocationChanged);
    }
    _mapAnimationHelper.dispose();
    _zoomNotifier.dispose();
    _rotationNotifier.dispose();
    controller.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _updateGeofence(ll.LatLng? position) {
    if (position == null || widget.missionGps.isEmpty || _isProcessing) return;

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

    final newInRange = distance <= 100;
    final roundedDistance = distance.round();

    if (newInRange != _isInRange || (roundedDistance - _distance).abs() > 5) {
      if (mounted) {
        setState(() {
          _distance = roundedDistance;
          _isInRange = newInRange;
          if (!_isInRange && _isScanning && !_isProcessing) {
            _isScanning = false;
          }
        });
      }
    }
  }

  void _showEcoSnackBar(
    BuildContext context,
    String message, {
    bool isError = true,
  }) {
    if (!mounted) return;
    EcoPulseApp.scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
    EcoPulseApp.scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: isError ? AppTheme.terracotta : AppTheme.forest,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  Future<void> _handleCheckIn(String qrToken) async {
    final loc = Provider.of<LocationProvider>(context, listen: false);
    final attendanceProvider = Provider.of<AttendanceProvider>(
      context,
      listen: false,
    );

    if (_isProcessing || !_isInRange) return;

    setState(() => _isProcessing = true);

    try {
      await controller.stop();
    } catch (e) {
      debugPrint('Error stopping scanner: $e');
    }

    if (!mounted) return;

    try {
      final userGps =
          '${loc.currentPosition?.latitude},${loc.currentPosition?.longitude}';

      final result = await attendanceProvider.checkIn(
        widget.missionId,
        qrToken,
        userGps,
      );

      if (!mounted) return;

      if (result['isEarly'] == true) {
        await EcoDialog.show(
          context,
          title: 'You are Early!',
          subtitle: 'We have notified the coordinator that you are here. Please wait for them to start the mission.',
          icon: const Icon(Icons.timer_outlined, color: AppTheme.amber),
          child: const SizedBox.shrink(),
          actions: [
            EcoPulseButton(
              label: 'Okay, I\'ll Wait',
              isSmall: true,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
        if (!mounted) return;
        Navigator.pop(context);
      } else {
        _showEcoSnackBar(
          context,
          'Check-in successful! Impact recorded.',
          isError: false,
        );
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showEcoSnackBar(context, 'Verification failed: ${e.toString()}');
        setState(() => _isProcessing = false);
        try {
          await controller.start();
        } catch (startErr) {
          debugPrint('Error restarting scanner: $startErr');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: EcoAppBar(
        isTransparent: true,
        titleWidget: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color.fromRGBO(0, 0, 0, 0.06)),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.04),
                offset: Offset(0, 2),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'MISSION VERIFICATION',
                style: EcoText.monoSM(context).copyWith(
                  color: AppTheme.ink.withValues(alpha: 0.4),
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.missionTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: EcoText.displayMD(context).copyWith(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Consumer<LocationProvider>(
            builder: (context, loc, _) {
              if (loc.isLoading) return const CheckInLoadingOverlay();
              if (loc.error != null) {
                return CheckInErrorOverlay(
                  error: loc.error!,
                  onRetry: loc.determinePosition,
                );
              }

              final parts = widget.missionGps.split(',');
              final missionLatLng = parts.length == 2
                  ? ll.LatLng(
                      double.tryParse(parts[0]) ?? 0,
                      double.tryParse(parts[1]) ?? 0,
                    )
                  : const ll.LatLng(0, 0);

              double bottomPadding = 180.0;
              if (_isScanning) {
                bottomPadding = 510.0;
              } else if (_isInRange) {
                bottomPadding = 390.0;
              } else if (_isNavExpanded) {
                bottomPadding = 560.0;
              }

              return CheckInMap(
                mapController: _mapController,
                missionLatLng: missionLatLng,
                currentPosition: loc.currentPosition,
                currentZoom: _currentZoom,
                zoomNotifier: _zoomNotifier,
                rotationNotifier: _rotationNotifier,
                mapReady: _mapReady,
                onAnimatedMove: _animatedMapMove,
                bottomPadding: bottomPadding,
              );
            },
          ),

          Positioned(
            left: 16,
            right: 16,
            bottom: 32,
            child: SafeArea(
              child: AnimatedSize(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutBack,
                child: CheckInContextualPanel(
                  isScanning: _isScanning,
                  isInRange: _isInRange,
                  isNavExpanded: _isNavExpanded,
                  distance: _distance,
                  missionGps: widget.missionGps,
                  onToggleNav: () =>
                      setState(() => _isNavExpanded = !_isNavExpanded),
                  onAnimatedMapMove: _animatedMapMove,
                  buildActionButton: _buildActionButton,
                  buildStepItem: _buildStepItem,
                  onStartVerification: () => setState(() => _isScanning = true),
                  scannerWidget: CheckInScanner(
                    controller: controller,
                    isProcessing: _isProcessing,
                    onDetect: _handleCheckIn,
                    onClose: () => setState(() => _isScanning = false),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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
                  ? AppTheme.forest.withValues(alpha: 0.1)
                  : AppTheme.ink.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDone ? Icons.check : icon,
              size: 16,
              color: isDone
                  ? AppTheme.forest
                  : AppTheme.ink.withValues(alpha: 0.4),
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
                    color: isDone ? AppTheme.forest : AppTheme.ink,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppTheme.ink.withValues(alpha: 0.5),
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
      onTap: () {
        if (label == 'Directions') {
          _showEcoSnackBar(context, 'Opening External Maps...', isError: false);
        } else if (label.contains('Contact Coordinator')) {
          _showEcoSnackBar(
            context,
            'Coordinator notified of your location.',
            isError: false,
          );
        } else {
          onTap();
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.ink.withValues(alpha: 0.1)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: isFullWidth
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppTheme.ink),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
