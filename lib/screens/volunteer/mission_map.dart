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
import '../../models/mission_model.dart';
import '../../widgets/eco_pulse_widgets.dart';
import '../../utils/map_utils.dart';
import '../../widgets/map/user_location_marker.dart';
import '../../widgets/map/semantic_marker.dart';
import '../../widgets/map/off_screen_indicator.dart';

class MissionMap extends StatefulWidget {
  final Mission? selectedMission;
  final ValueChanged<Mission?>? onMissionSelected;
  final bool showRegisteredOnly;
  final List<Mission>? missionsOverride;
  final bool centerOnMission;
  const MissionMap({
    super.key,
    this.selectedMission,
    this.onMissionSelected,
    this.showRegisteredOnly = false,
    this.missionsOverride,
    this.centerOnMission = false,
  });
  @override
  State<MissionMap> createState() => MissionMapState();
}

class MissionMapState extends State<MissionMap> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  late MapAnimationHelper _mapAnimationHelper;
  final ValueNotifier<double> _zoomNotifier = ValueNotifier(13.0);
  final ValueNotifier<double> _rotationNotifier = ValueNotifier(0.0);
  bool _mapReady = false;

  void stopAnimation() {
    _mapAnimationHelper.stop();
  }

  void animatedMapMove(ll.LatLng destLocation, [double? destZoom]) {
    double targetZoom;
    if (destZoom != null) {
      targetZoom = destZoom;
    } else {
      final currentZoom = _mapController.camera.zoom;
      if (currentZoom > 17.0) {
        targetZoom = 16.0;
      } else if (currentZoom < 14.0) {
        targetZoom = 15.5;
      } else {
        targetZoom = currentZoom;
      }
    }
    _mapAnimationHelper.move(destLocation, targetZoom);
  }

  @override
  void initState() {
    super.initState();
    _mapAnimationHelper = MapAnimationHelper(
      mapController: _mapController,
      vsync: this,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.centerOnMission && widget.selectedMission != null) {
        final point = _parseGps(widget.selectedMission!.locationGps);
        animatedMapMove(point, 16.0);
        _zoomNotifier.value = 16.0;
        return;
      }
      final loc = Provider.of<LocationProvider>(context, listen: false);
      if (loc.currentPosition != null) {
        animatedMapMove(loc.currentPosition!, 15.0);
        _zoomNotifier.value = 15.0;
      } else {
        loc.determinePosition().then((_) {
          if (mounted && loc.currentPosition != null) {
            animatedMapMove(loc.currentPosition!, 15.0);
            _zoomNotifier.value = 15.0;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _mapAnimationHelper.dispose();
    _zoomNotifier.dispose();
    _rotationNotifier.dispose();
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

  Widget _buildOffScreenIndicators(
    BoxConstraints constraints,
    List<Mission> missions,
    ll.LatLng? userLatLng,
  ) {
    if (!_mapReady) return const SizedBox.shrink();
    if (_zoomNotifier.value < 4) return const SizedBox.shrink();

    final camera = _mapController.camera;
    double bottomPadding = 150.0;
    if (widget.selectedMission != null) {
      bottomPadding = 230.0;
    }

    List<Widget> indicators = [];

    if (userLatLng != null) {
      indicators.add(
        MapOffScreenIndicator(
          position: userLatLng,
          color: EcoColors.violet,
          icon: Icons.person,
          camera: camera,
          constraints: constraints,
          bottomPadding: bottomPadding,
          onTap: () => animatedMapMove(userLatLng, 16.0),
        ),
      );
    }

    if (widget.showRegisteredOnly) {
      int missionIdx = 1;
      for (final mission in missions) {
        if (!mission.isRegistered) continue;
        final missionLatLng = _parseGps(mission.locationGps);
        indicators.add(
          MapOffScreenIndicator(
            position: missionLatLng,
            color: EcoColors.forest,
            icon: Icons.flag,
            camera: camera,
            constraints: constraints,
            bottomPadding: bottomPadding,
            index: missionIdx++,
            offsetIfOverlapping: true,
            onTap: () => animatedMapMove(missionLatLng, 16.0),
          ),
        );
      }
    }

    return Stack(children: indicators);
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
                  // Use missionsOverride if provided, otherwise fall back to all missions
                  final sourceMissions = widget.missionsOverride ?? missionProvider.missions;

                  final displayMissions = widget.showRegisteredOnly
                      ? sourceMissions
                            .where((m) => m.isRegistered)
                            .toList()
                      : sourceMissions;

                  final markers = displayMissions.map((mission) {
                    final point = _parseGps(mission.locationGps);
                    return Marker(
                      key: ValueKey(mission.id),
                      point: point,
                      width: 160,
                      height: 80,
                      alignment: Alignment.center,
                      rotate: true,
                      child: SemanticMarker(
                        mission: mission,
                        zoomNotifier: _zoomNotifier,
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
                          minZoom: 3.0,
                          maxZoom: 18.0,
                          // Restrict panning to prevent scrolling beyond poles
                          cameraConstraint: CameraConstraint.contain(
                            bounds: LatLngBounds(
                              const ll.LatLng(-85.05, -180.0),
                              const ll.LatLng(85.05, 180.0),
                            ),
                          ),
                          interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.all,
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
                            _zoomNotifier.value = pos.zoom;
                            _rotationNotifier.value = pos.rotation;
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.civic',
                            tileDisplay: const TileDisplay.fadeIn(),
                            panBuffer: 1,
                            keepBuffer: 2,
                          ),
                          if (loc.currentPosition != null)
                            TweenAnimationBuilder<ll.LatLng>(
                              tween: LatLngTween(
                                end: loc.currentPosition!,
                                begin: ll.LatLng(-6.2088, 106.8456),
                              ),
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                              builder: (context, animatedPos, _) {
                                return MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: animatedPos,
                                      width: 120,
                                      height: 120,
                                      rotate: false,
                                      child: UserLocationMarker(
                                        position: animatedPos,
                                        zoomNotifier: _zoomNotifier,
                                        rotationNotifier: _rotationNotifier,
                                        showCone: true,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),

                          MarkerClusterLayerWidget(
                            options: MarkerClusterLayerOptions(
                              maxClusterRadius: 45,
                              size: const Size(40, 40),
                              alignment: Alignment.center,
                              padding: const EdgeInsets.all(50),
                              maxZoom: 15,
                              markers: markers,
                              onMarkerTap: (marker) {
                                final key = marker.key;
                                if (key is ValueKey<int>) {
                                  final mission = missionProvider.missions
                                      .firstWhere((m) => m.id == key.value);
                                  if (widget.onMissionSelected != null) {
                                    widget.onMissionSelected!(mission);
                                  }
                                  animatedMapMove(marker.point);
                                }
                              },
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
                                    .map((m) {
                                      final key = m.key;
                                      if (key is ValueKey<int>) {
                                        return key.value;
                                      }
                                      return null;
                                    })
                                    .whereType<int>()
                                    .toSet();

                                if (missionIds.isEmpty) return;

                                final clusterMissions = missionProvider.missions
                                    .where((m) => missionIds.contains(m.id))
                                    .toList();

                                _showClusterSummary(context, clusterMissions);
                              },
                            ),
                          ),
                        ],
                      ),
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
            ],
          ),
        );
      },
    );
  }

  void _showClusterSummary(BuildContext context, List<Mission> missions) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.clay,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppTheme.ink.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                '${missions.length} Missions in this area',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.ink,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: missions.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _buildClusterMissionItem(context, missions[index]);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildClusterMissionItem(BuildContext context, Mission mission) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        if (widget.onMissionSelected != null) {
          widget.onMissionSelected!(mission);
        }
        animatedMapMove(_parseGps(mission.locationGps));
      },
      child: EcoPulseCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: EcoColors.forest.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  mission.categories.firstOrNull?.icon ?? '📍',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mission.title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.ink,
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 10,
                        color: AppTheme.ink.withValues(alpha: 0.4),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          mission.locationName,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.ink.withValues(alpha: 0.5),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: EcoColors.forest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '+${mission.pointsValue} PTS',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.people_outline_rounded,
                        size: 11,
                        color: AppTheme.ink.withValues(alpha: 0.4),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${mission.currentVolunteers}/${mission.maxVolunteers ?? "∞"}',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 10,
                        color: AppTheme.ink.withValues(alpha: 0.4),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${mission.startTime.day}/${mission.startTime.month}',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 12,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> triggerMyLocation() async {
    final loc = Provider.of<LocationProvider>(context, listen: false);
    stopAnimation();

    if (loc.currentPosition != null) {
      animatedMapMove(loc.currentPosition!);
      loc.determinePosition();
      return;
    }

    try {
      await loc.determinePosition();
      if (loc.currentPosition != null && mounted) {
        animatedMapMove(loc.currentPosition!);
      }
    } catch (_) {}
  }
}
