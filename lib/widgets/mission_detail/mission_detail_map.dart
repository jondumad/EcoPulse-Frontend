import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;

/// A read-only embedded map tile showing the mission's GPS coordinates with a
/// red pin marker. Returns an empty widget when no valid GPS string is provided.
class MissionDetailMap extends StatelessWidget {
  /// GPS string in the format `"lat,lng"` (e.g. `"3.1412,101.6865"`).
  final String? gps;

  const MissionDetailMap({super.key, this.gps});

  @override
  Widget build(BuildContext context) {
    if (gps == null || !gps!.contains(',')) return const SizedBox.shrink();

    final coords = gps!.split(',');
    final lat = double.tryParse(coords[0].trim()) ?? 0;
    final lng = double.tryParse(coords[1].trim()) ?? 0;

    return Container(
      height: 180,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IgnorePointer(
          child: FlutterMap(
            options: MapOptions(
              initialCenter: ll.LatLng(lat, lng),
              initialZoom: 15,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.ecopulse.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: ll.LatLng(lat, lng),
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
