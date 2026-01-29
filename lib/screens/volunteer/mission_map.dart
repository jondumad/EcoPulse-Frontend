import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:provider/provider.dart';
import '../../providers/mission_provider.dart';
import '../../models/mission_model.dart';
import '../../widgets/eco_pulse_widgets.dart';
import 'mission_detail_screen.dart';
import 'mission_list_screen.dart';

class MissionMap extends StatefulWidget {
  final VoidCallback? onToggleView;
  const MissionMap({super.key, this.onToggleView});

  @override
  State<MissionMap> createState() => _MissionMapState();
}

class _MissionMapState extends State<MissionMap> {
  Mission? _selectedMission;
  final MapController _mapController = MapController();

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
              final markers = provider.missions.map((mission) {
                final point = _parseGps(mission.locationGps);
                return Marker(
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

              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: const ll.LatLng(-6.2088, 106.8456),
                  initialZoom: 13.0,
                  onTap: (_, _) => setState(() => _selectedMission = null),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.civic',
                  ),
                  MarkerLayer(markers: markers),
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

          // Floating Action to go back to list if needed
          Positioned(
            top: 50,
            right: 20,
            child: FloatingActionButton.small(
              backgroundColor: Colors.white,
              onPressed: () {
                if (widget.onToggleView != null) {
                  widget.onToggleView!();
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MissionListScreen(),
                    ),
                  );
                }
              },
              child: const Icon(Icons.list, color: EcoColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}
