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
  late MapAnimationHelper _mapAnimationHelper;
  final ValueNotifier<double> _zoomNotifier = ValueNotifier(13.0);
  final ValueNotifier<double> _rotationNotifier = ValueNotifier(0.0);
  bool _mapReady = false;

  void stopAnimation() {
    _mapAnimationHelper.stop();
  }

  void animatedMapMove(ll.LatLng destLocation, double destZoom) {
    _mapAnimationHelper.move(destLocation, destZoom);
  }

  @override
  void initState() {
    super.initState();
    _mapAnimationHelper = MapAnimationHelper(
      mapController: _mapController,
      vsync: this,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    // Use the notifier value
    if (_zoomNotifier.value < 4) return const SizedBox.shrink();

    final camera = _mapController.camera;
    // Calculate dynamic bottom padding to avoid the floating card or buttons
    double bottomPadding = 150.0;
    if (widget.selectedMission != null) {
      bottomPadding = 230.0; // Card is open (mini-pill)
    }

    List<Widget> indicators = [];

    // User Indicator
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

    // Mission Indicators (Only when filter is ON)
    if (widget.showRegisteredOnly) {
      int missionIdx = 1; // Start from 1 as user is index 0
      for (final mission in missions) {
        // only show for filtered missions
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
                  // Filter missions based on toggle
                  final displayMissions = widget.showRegisteredOnly
                      ? missionProvider.missions
                            .where((m) => m.isRegistered)
                            .toList()
                      : missionProvider.missions;

                  final markers = displayMissions.map((mission) {
                    final point = _parseGps(mission.locationGps);
                    // Use a slightly larger fixed size for the container, content scales inside
                    // Actually, Flutter Map markers need a size.
                    // If we change size, we rebuild list.
                    // For perf, let's keep size responsive but maybe optimize?
                    // We can listen to zoomNotifier to rebuild markers?
                    // No, that rebuilds the whole list.
                    // Let's use a "Max Size" approach and scale down inside.
                    // Max width ~150, Max height ~65.
                    return Marker(
                      key: ValueKey(mission.id),
                      point: point,
                      width: 160, // Max potential width
                      height: 80, // Max potential height
                      alignment: Alignment.center,
                      rotate: true,
                      child: GestureDetector(
                        onTap: () {
                          if (widget.onMissionSelected != null) {
                            widget.onMissionSelected!(mission);
                          }
                          animatedMapMove(point, 16.0);
                        },
                        child: SemanticMarker(
                          mission: mission,
                          zoomNotifier: _zoomNotifier,
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
                            // Update notifiers cheaply
                            _zoomNotifier.value = pos.zoom;
                            _rotationNotifier.value = pos.rotation;
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.civic',
                          ),
                          if (loc.currentPosition != null)
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: loc.currentPosition!,
                                  width: 120, // Max size
                                  height: 120,
                                  rotate: false,
                                  child: UserLocationMarker(
                                    position: loc.currentPosition!,
                                    zoomNotifier: _zoomNotifier,
                                    rotationNotifier: _rotationNotifier,
                                    showCone: true,
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
