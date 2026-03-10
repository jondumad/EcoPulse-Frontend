import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../../theme/app_theme.dart';
import '../../widgets/eco_pulse_widgets.dart';
import '../map/user_location_marker.dart';
import '../map/off_screen_indicator.dart';

class CheckInMap extends StatelessWidget {
  final MapController mapController;
  final ll.LatLng missionLatLng;
  final ll.LatLng? currentPosition;
  final double currentZoom;
  final ValueNotifier<double> zoomNotifier;
  final ValueNotifier<double> rotationNotifier;
  final bool mapReady;
  final Function(ll.LatLng, double) onAnimatedMove;
  final double bottomPadding;

  const CheckInMap({
    super.key,
    required this.mapController,
    required this.missionLatLng,
    this.currentPosition,
    required this.currentZoom,
    required this.zoomNotifier,
    required this.rotationNotifier,
    required this.mapReady,
    required this.onAnimatedMove,
    required this.bottomPadding,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: missionLatLng,
                initialZoom: 16.0,
                minZoom: 3.0,
                maxZoom: 18.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.ecopulse',
                ),
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: missionLatLng,
                      radius: 100,
                      useRadiusInMeter: true,
                      color: AppTheme.forest.withValues(alpha: 0.05),
                      borderColor: AppTheme.forest.withValues(alpha: 0.3),
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    // Mission Marker
                    Marker(
                      point: missionLatLng,
                      width: currentZoom >= 14 ? 40 : 20,
                      height: currentZoom >= 14 ? 40 : 20,
                      rotate: true,
                      child: currentZoom >= 14
                          ? Container(
                              decoration: const BoxDecoration(
                                color: AppTheme.forest,
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
                                color: AppTheme.forest,
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
                        point: currentPosition!,
                        width: 120,
                        height: 120,
                        rotate: false,
                        child: UserLocationMarker(
                          position: currentPosition!,
                          zoomNotifier: zoomNotifier,
                          rotationNotifier: rotationNotifier,
                          showCone: true,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            _buildOffScreenIndicators(constraints),
          ],
        );
      },
    );
  }

  Widget _buildOffScreenIndicators(BoxConstraints constraints) {
    if (!mapReady) return const SizedBox.shrink();

    // Use the camera directly from the map controller
    final camera = mapController.camera;
    if (camera.zoom == 0) return const SizedBox.shrink();

    List<Widget> indicators = [];

    // Mission Indicator
    indicators.add(
      MapOffScreenIndicator(
        position: missionLatLng,
        color: AppTheme.forest,
        icon: Icons.flag,
        camera: camera,
        constraints: constraints,
        bottomPadding: bottomPadding,
        index: 0,
        onTap: () => onAnimatedMove(missionLatLng, 16.0),
      ),
    );

    // User Indicator
    if (currentPosition != null) {
      indicators.add(
        MapOffScreenIndicator(
          position: currentPosition!,
          color: AppTheme.violet,
          icon: Icons.person,
          camera: camera,
          constraints: constraints,
          bottomPadding: bottomPadding,
          index: 1,
          offsetIfOverlapping: true,
          onTap: () => onAnimatedMove(currentPosition!, 16.0),
        ),
      );
    }

    return Stack(children: indicators);
  }
}
