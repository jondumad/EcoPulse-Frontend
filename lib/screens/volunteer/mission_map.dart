import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:provider/provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/mission_provider.dart';
import '../../models/mission_model.dart';
import '../../widgets/eco_pulse_widgets.dart';
import 'mission_detail_screen.dart';

class MissionMap extends StatefulWidget {
  const MissionMap({super.key});

  @override
  State<MissionMap> createState() => _MissionMapState();
}

class _MissionMapState extends State<MissionMap> {
  Mission? _selectedMission;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loc = Provider.of<LocationProvider>(context, listen: false);
      if (loc.currentPosition != null) {
        _mapController.move(loc.currentPosition!, 15.0);
      } else {
        loc.determinePosition().then((_) {
          if (mounted && loc.currentPosition != null) {
            _mapController.move(loc.currentPosition!, 15.0);
          }
        });
      }
    });
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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Stack(
        children: [
          Consumer<MissionProvider>(
            builder: (context, provider, _) {
              final loc = Provider.of<LocationProvider>(context);
              final markers = provider.missions.map((mission) {
                final point = _parseGps(mission.locationGps);
                return Marker(
                  key: ValueKey(mission.id),
                  point: point,
                  width: 120,
                  height: 40,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedMission = mission;
                      });
                      _mapController.move(point, 15.0);
                    },
                    child: EcoPulseTag(
                      label: mission.title.length > 10
                          ? '${mission.title.substring(0, 10)}...'
                          : mission.title,
                    ),
                  ),
                );
              }).toList();

              // Add current location marker
              if (loc.currentPosition != null) {
                markers.add(
                  Marker(
                    point: loc.currentPosition!,
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.7),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                );
              }

              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter:
                      loc.currentPosition ?? const ll.LatLng(-6.2088, 106.8456),
                  initialZoom: 13.0,
                  minZoom: 5.0,
                  maxZoom: 18.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                  onTap: (_, _) => setState(() => _selectedMission = null),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.civic',
                  ),
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
                            border: Border.all(color: Colors.white, width: 2),
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
                            .map((m) => (m.key as ValueKey<int>?)?.value)
                            .where((id) => id != null)
                            .toSet();

                        if (missionIds.isEmpty) return;

                        final allMissions = Provider.of<MissionProvider>(
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
                                    MediaQuery.of(context).size.height * 0.5,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                        final mission = clusterMissions[index];
                                        return ListTile(
                                          title: Text(
                                            mission.title,
                                            style: EcoText.bodyBoldMD(context),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          subtitle: Text(
                                            mission.locationName,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          trailing: Text(
                                            '+${mission.pointsValue} pts',
                                            style: const TextStyle(
                                              color: EcoColors.forest,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          onTap: () {
                                            Navigator.pop(context);
                                            setState(() {
                                              _selectedMission = mission;
                                            });
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
              );
            },
          ),

          // Detail Card Popup
          if (_selectedMission != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: EcoPulseCard(
                variant: CardVariant.paper,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _selectedMission!.title,
                            style: EcoText.displayMD(context),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () =>
                              setState(() => _selectedMission = null),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedMission!.locationName,
                      style: EcoText.bodyMD(context),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '+${_selectedMission!.pointsValue} PTS',
                          style: const TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontWeight: FontWeight.bold,
                            color: EcoColors.forest,
                          ),
                        ),
                        EcoPulseButton(
                          label: 'View Details',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MissionDetailScreen(
                                  mission: _selectedMission!,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // Find My Location Button (New)
          Positioned(
            top: 110,
            right: 20,
            child: Consumer<LocationProvider>(
              builder: (context, loc, _) => FloatingActionButton.small(
                heroTag: 'my_location_btn',
                backgroundColor: Colors.white,
                onPressed: () async {
                  await loc.determinePosition();
                  if (loc.currentPosition != null) {
                    _mapController.move(loc.currentPosition!, 15.0);
                  }
                },
                child: const Icon(Icons.my_location, color: EcoColors.ink),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
