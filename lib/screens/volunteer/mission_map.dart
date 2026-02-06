import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../providers/location_provider.dart';
import '../../providers/mission_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../models/mission_model.dart';
import '../../widgets/eco_pulse_widgets.dart';
import 'mission_detail_screen.dart';

class MissionMap extends StatefulWidget {
  final Mission? selectedMission;
  final ValueChanged<Mission?>? onMissionSelected;
  final bool showRegisteredOnly;

  const MissionMap({
    super.key,
    this.selectedMission,
    this.onMissionSelected,
    this.showRegisteredOnly = false,
  });

  @override
  State<MissionMap> createState() => MissionMapState();
}

class MissionMapState extends State<MissionMap> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  double _currentZoom = 13.0;
  double _currentRotation = 0.0;
  bool _mapReady = false;
  AnimationController? _animationController;

  void stopAnimation() {
    if (_animationController != null) {
      _animationController!.stop();
      _animationController!.dispose();
      _animationController = null;
    }
  }

  void animatedMapMove(ll.LatLng destLocation, double destZoom) {
    stopAnimation();

    final camera = _mapController.camera;
    final currentZoom = camera.zoom;
    // Don't zoom out if we're already closer than destZoom
    final effectiveZoom = currentZoom > destZoom ? currentZoom : destZoom;

    final latTween = Tween<double>(
      begin: camera.center.latitude,
      end: destLocation.latitude,
    );
    final lngTween = Tween<double>(
      begin: camera.center.longitude,
      end: destLocation.longitude,
    );
    final zoomTween = Tween<double>(begin: currentZoom, end: effectiveZoom);

    _animationController = AnimationController(
      duration: const Duration(
        milliseconds: 1500,
      ), // Slightly slower for elegance
      vsync: this,
    );

    // Both use easeInOutQuart for a long, soft 'tail' deceleration
    final Animation<double> panAnimation = CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeInOutQuart,
    );

    final Animation<double> zoomAnimation = CurvedAnimation(
      parent: _animationController!,
      // Zoom starts 15% into the move, and both finish together
      curve: const Interval(0.15, 1.0, curve: Curves.easeInOutQuart),
    );

    _animationController!.addListener(() {
      _mapController.move(
        ll.LatLng(
          latTween.evaluate(panAnimation),
          lngTween.evaluate(panAnimation),
        ),
        zoomTween.evaluate(zoomAnimation),
      );
    });

    _animationController!.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        _animationController?.dispose();
        _animationController = null;
      }
    });

    _animationController!.forward();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loc = Provider.of<LocationProvider>(context, listen: false);
      if (loc.currentPosition != null) {
        animatedMapMove(loc.currentPosition!, 15.0);
        setState(() {
          _currentZoom = 15.0;
          _currentRotation = 0.0;
        });
      } else {
        loc.determinePosition().then((_) {
          if (mounted && loc.currentPosition != null) {
            animatedMapMove(loc.currentPosition!, 15.0);
            setState(() {
              _currentZoom = 15.0;
              _currentRotation = 0.0;
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    stopAnimation();
    super.dispose();
  }

  ll.LatLng _parseGps(String? gps) {
    if (gps == null || gps.isEmpty) {
      return const ll.LatLng(-6.2088, 106.8456); // Jakarta default
    }
    final parts = gps.split(',');
    if (parts.length != 2) return const ll.LatLng(-6.2088, 106.8456);
    return ll.LatLng(
      double.tryParse(parts[0]) ?? -6.2088,
      double.tryParse(parts[1]) ?? 106.8456,
    );
  }

  Widget _buildSemanticMarker(Mission mission, double zoom, double rotation) {
    // Transition t: 14.0 -> 15.0 for expansion
    double t = (zoom - 14.0).clamp(0.0, 1.0);
    // Icon visibility t: 11.0 -> 12.0
    // Mini-dot visibility for far zoom (10 -> 12)
    double dotT = (zoom - 10.0).clamp(0.0, 1.0);

    final color = _getCategoryColor(mission.categories.firstOrNull?.name);
    final double tiltAngle = (rotation * 3.14159 / 180).clamp(-0.2, 0.2);

    return Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001) // perspective
        ..rotateY(tiltAngle)
        ..scale(
          0.5 + (0.5 * dotT),
          0.5 + (0.5 * dotT),
          0.5 + (0.5 * dotT),
        ), // Extra shrink at low zoom
      alignment: Alignment.center,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: FittedBox(
          fit: BoxFit.contain,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 8 + (2 * t),
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(t > 0.5 ? 12 : 24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: dotT),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1 * dotT),
                      blurRadius: 4 * dotT,
                      offset: Offset(0, 4 * t),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon fades out at very far zoom
                    Opacity(
                      opacity: dotT,
                      child: Transform.scale(
                        scale: 0.8 + (0.2 * t),
                        child: Text(
                          mission.categories.firstOrNull?.icon ?? '📍',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                    // Text expands via clipping and animated width
                    if (t > 0.01)
                      ClipRect(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          widthFactor: t,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Opacity(
                              opacity: t,
                              child: Text(
                                mission.title.length > 14
                                    ? '${mission.title.substring(0, 14)}...'
                                    : mission.title,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.clip,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Caret also fades in and grows
              if (t > 0.1)
                Opacity(
                  opacity: t,
                  child: CustomPaint(
                    size: Size(12 * t, 6 * t),
                    painter: _MarkerCaretPainter(color: color),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOffScreenIndicators(
    BoxConstraints constraints,
    List<Mission> missions,
    ll.LatLng? userLatLng,
  ) {
    if (!_mapReady) return const SizedBox.shrink();
    // If zoom is too far out (world view), don't show indicators to avoid clutter/confusion
    if (_currentZoom < 4) return const SizedBox.shrink();

    final camera = _mapController.camera;
    // Calculate dynamic bottom padding to avoid the floating card or buttons
    double bottomPadding = 150.0;
    if (widget.selectedMission != null) {
      bottomPadding = 230.0; // Card is open (mini-pill)
    }

    List<Widget> indicators = [];

    // User Indicator
    if (userLatLng != null) {
      final userIndicator = _getIndicatorWidget(
        userLatLng,
        camera,
        constraints,
        EcoColors.violet,
        Icons.person,
        bottomPadding,
        isUser: true,
      );
      if (userIndicator != null) indicators.add(userIndicator);
    }

    // Mission Indicators (Only when filter is ON)
    if (widget.showRegisteredOnly) {
      for (final mission in missions) {
        // only show for filtered missions
        if (!mission.isRegistered) continue;

        final missionLatLng = _parseGps(mission.locationGps);
        final indicator = _getIndicatorWidget(
          missionLatLng,
          camera,
          constraints,
          EcoColors.forest,
          Icons.flag,
          bottomPadding,
          offsetIfOverlapping: indicators.isNotEmpty,
        );
        if (indicator != null) indicators.add(indicator);
      }
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
    bool isUser = false,
  }) {
    final screenPoint = camera.latLngToScreenOffset(point);

    const horizontalPadding = 50.0; // Increased to be less close to sides
    const topPadding = 70.0; // Reduced to be closer to top (less gap)

    final safeZone = Rect.fromLTRB(
      0,
      0,
      constraints.maxWidth,
      constraints.maxHeight,
    );

    // Indicator logic: Show if outside visible safe zone
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

    Offset finalPos = edgePoint;
    if (offsetIfOverlapping) {
      finalPos = Offset(
        edgePoint.dx + (math.cos(angle + math.pi / 2) * 20),
        edgePoint.dy + (math.sin(angle + math.pi / 2) * 20),
      );
    }

    return Positioned(
      left: finalPos.dx - 22,
      top: finalPos.dy - 22,
      child: GestureDetector(
        onTap: () => animatedMapMove(point, 16.0),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Transform.translate(
                offset: Offset(math.cos(angle) * 26, math.sin(angle) * 26),
                child: Transform.rotate(
                  angle: angle + (math.pi / 2),
                  child: CustomPaint(
                    size: const Size(12, 8),
                    painter: _PointerPainter(color),
                  ),
                ),
              ),
              Container(
                width: 40,
                height: 40,
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
                child: Icon(icon, color: Colors.white, size: 20),
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

  Color _getCategoryColor(String? category) {
    switch (category) {
      case 'Environmental':
        return EcoColors.forest;
      case 'Social':
        return EcoColors.violet;
      case 'Educational':
        return AppTheme.ink;
      case 'Health':
        return EcoColors.terracotta;
      default:
        return EcoColors.forest;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          color: Colors.white,
          child: Stack(
            children: [
              Consumer2<MissionProvider, LocationProvider>(
                builder: (context, missionProvider, loc, child) {
                  // Filter missions based on toggle
                  final displayMissions = widget.showRegisteredOnly
                      ? missionProvider.missions
                            .where((m) => m.isRegistered)
                            .toList()
                      : missionProvider.missions;

                  final markers = displayMissions.map((mission) {
                    final point = _parseGps(mission.locationGps);
                    // Transition t: 14.0 -> 15.0 for expansion
                    double t = (_currentZoom - 14.0).clamp(0.0, 1.0);
                    // Overall scale factor - much looser floor (0.3)
                    double scaleFactor = (_currentZoom / 15.0).clamp(0.3, 1.5);

                    // Dynamic width: 45 (icon) -> 150 (full label)
                    final double width = (45 + (105 * t)) * scaleFactor;
                    // Dynamic height: 45 (dot) -> 65 (full label)
                    final double height = (45 + (20 * t)) * scaleFactor;

                    return Marker(
                      key: ValueKey(mission.id),
                      point: point,
                      width: width,
                      height: height,
                      alignment: Alignment
                          .bottomCenter, // Tip of the caret at the point
                      rotate: true, // Keep markers upright when map rotates
                      child: GestureDetector(
                        onTap: () {
                          if (widget.onMissionSelected != null) {
                            widget.onMissionSelected!(mission);
                          }
                          animatedMapMove(point, 16.0);
                        },
                        child: _buildSemanticMarker(
                          mission,
                          _currentZoom,
                          _currentRotation,
                        ),
                      ),
                    );
                  }).toList();

                  return Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter:
                              loc.currentPosition ??
                              const ll.LatLng(-6.2088, 106.8456),
                          initialZoom: 13.0,
                          minZoom: 3.0, // Loosened max zoom out
                          maxZoom: 18.0,
                          interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.all, // Allow rotation
                          ),
                          onTap: (_, _) {
                            if (widget.onMissionSelected != null) {
                              widget.onMissionSelected!(null);
                            }
                          },
                          onMapReady: () {
                            if (mounted) {
                              setState(() => _mapReady = true);
                            }
                          },
                          onPositionChanged: (pos, hasGesture) {
                            if (hasGesture) {
                              stopAnimation();
                            }
                            // Update zoom/rotation for other UI elements (markers, etc.)
                            // but only trigger setState if they actually changed to reduce load
                            if (_currentZoom != pos.zoom ||
                                _currentRotation != pos.rotation) {
                              setState(() {
                                _currentZoom = pos.zoom;
                                _currentRotation = pos.rotation;
                              });
                            }
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.civic',
                          ),
                          // Current Location Layer (Scale-Aware)
                          if (loc.currentPosition != null)
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: loc.currentPosition!,
                                  width:
                                      80 * (_currentZoom / 15).clamp(0.5, 1.5),
                                  height:
                                      80 * (_currentZoom / 15).clamp(0.5, 1.5),
                                  rotate: true, // Keep location marker upright
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Translucent Accuracy/Pulse Ring
                                      TweenAnimationBuilder<double>(
                                        tween: Tween(begin: 0.0, end: 1.0),
                                        duration: const Duration(seconds: 2),
                                        curve: Curves.easeInOut,
                                        builder: (context, value, child) {
                                          return Container(
                                            width: 40 + (20 * value),
                                            height: 40 + (20 * value),
                                            decoration: BoxDecoration(
                                              color: AppTheme.violet.withValues(
                                                alpha: 0.15 * (1 - value),
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                          );
                                        },
                                        onEnd:
                                            () {}, // Handled by standard pulses or just left static-ish
                                      ),
                                      // Shadow/Glow
                                      Container(
                                        width: 18,
                                        height: 18,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppTheme.violet.withValues(
                                                alpha: 0.3,
                                              ),
                                              blurRadius: 10,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Core Indicator
                                      Container(
                                        width: 14,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          color: AppTheme.violet,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          // Missions Clustering Layer
                          MarkerClusterLayerWidget(
                            options: MarkerClusterLayerOptions(
                              maxClusterRadius: 45,
                              size: const Size(40, 40),
                              alignment: Alignment.center,
                              padding: const EdgeInsets.all(50),
                              maxZoom: 15,
                              markers: markers,
                              builder: (context, markers) {
                                return Container(
                                  decoration: BoxDecoration(
                                    color: EcoColors.forest,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      markers.length.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              },
                              onClusterTap: (cluster) {
                                final missionIds = cluster.markers
                                    .map(
                                      (m) => (m.key as ValueKey<int>?)?.value,
                                    )
                                    .where((id) => id != null)
                                    .toSet();

                                if (missionIds.isEmpty) return;

                                final allMissions =
                                    Provider.of<MissionProvider>(
                                      context,
                                      listen: false,
                                    ).missions;
                                final clusterMissions = allMissions
                                    .where((m) => missionIds.contains(m.id))
                                    .toList();

                                showModalBottomSheet(
                                  context: context,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    ),
                                  ),
                                  builder: (context) {
                                    return Container(
                                      padding: const EdgeInsets.all(16),
                                      constraints: BoxConstraints(
                                        maxHeight:
                                            MediaQuery.of(context).size.height *
                                            0.5,
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${clusterMissions.length} Missions Here',
                                            style: EcoText.headerMD(context),
                                          ),
                                          const SizedBox(height: 16),
                                          Flexible(
                                            child: ListView.separated(
                                              shrinkWrap: true,
                                              itemCount: clusterMissions.length,
                                              separatorBuilder: (_, _) =>
                                                  const Divider(),
                                              itemBuilder: (context, index) {
                                                final mission =
                                                    clusterMissions[index];
                                                return ListTile(
                                                  title: Text(
                                                    mission.title,
                                                    style: EcoText.bodyBoldMD(
                                                      context,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  subtitle: Text(
                                                    mission.locationName,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  trailing: Text(
                                                    '+${mission.pointsValue} pts',
                                                    style: const TextStyle(
                                                      color: EcoColors.forest,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  onTap: () {
                                                    Navigator.pop(context);
                                                    if (widget
                                                            .onMissionSelected !=
                                                        null) {
                                                      widget.onMissionSelected!(
                                                        mission,
                                                      );
                                                    }
                                                    // Optional: slightly move map to center marker if needed
                                                    // _mapController.move(_parseGps(mission.locationGps), 15.0);
                                                  },
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      // Off-Screen Indicators (Using Stream for smooth performance without full builds)
                      StreamBuilder<MapEvent>(
                        stream: _mapController.mapEventStream,
                        builder: (context, _) {
                          return _buildOffScreenIndicators(
                            constraints,
                            missionProvider.missions,
                            loc.currentPosition,
                          );
                        },
                      ),
                    ],
                  );
                },
              ),

              // detail card removed - now handled by parent (MissionHub) for better coordination

              // location and filter buttons removed - now handled by parent (MissionHub)
            ],
          ),
        );
      },
    );
  }

  // Helper to manual trigger map move from Hub
  Future<void> triggerMyLocation() async {
    final loc = Provider.of<LocationProvider>(context, listen: false);
    // Immediately halt any active glide/fling or program migration
    stopAnimation();
    _mapController.move(
      _mapController.camera.center,
      _mapController.camera.zoom,
    );

    try {
      await loc.determinePosition();
      if (loc.currentPosition != null && mounted) {
        animatedMapMove(loc.currentPosition!, 15.0);
      }
    } catch (_) {}
  }
}

class _MarkerCaretPainter extends CustomPainter {
  final Color color;
  _MarkerCaretPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final borderPath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0);

    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
