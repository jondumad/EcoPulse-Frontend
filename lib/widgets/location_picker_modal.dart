import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:geocoding/geocoding.dart' as geo;
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/location_provider.dart';
import '../theme/app_theme.dart';
import '../utils/map_utils.dart';
import 'eco_pulse_widgets.dart';

class LocationPickerModal extends StatefulWidget {
  const LocationPickerModal({super.key});

  @override
  State<LocationPickerModal> createState() => _LocationPickerModalState();
}

class _LocationPickerModalState extends State<LocationPickerModal>
    with TickerProviderStateMixin {
  ll.LatLng _pickedLocation = const ll.LatLng(-6.2088, 106.8456);
  final MapController _mapController = MapController();
  late MapAnimationHelper _mapAnimationHelper;
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<double> _zoomNotifier = ValueNotifier(15.0);

  String? _selectedAddress;
  bool _isLoading = false;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _mapAnimationHelper = MapAnimationHelper(
      mapController: _mapController,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _mapAnimationHelper.dispose();
    _zoomNotifier.dispose();
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    if (!_mapReady) return;

    final locProvider = Provider.of<LocationProvider>(context, listen: false);
    if (locProvider.currentPosition != null) {
      _updateLocation(locProvider.currentPosition!);
    } else {
      await _determinePosition();
    }
  }

  Future<void> _determinePosition() async {
    setState(() => _isLoading = true);
    try {
      final locProvider = Provider.of<LocationProvider>(context, listen: false);

      if (locProvider.currentPosition != null) {
        _updateLocation(locProvider.currentPosition!);
      }

      await locProvider.determinePosition();

      if (locProvider.currentPosition != null && mounted) {
        _updateLocation(locProvider.currentPosition!);
      }
    } catch (e) {
      // Error
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _updateLocation(ll.LatLng latLng) {
    setState(() {
      _pickedLocation = latLng;
    });
    _animatedMapMove(latLng, 16.0);
    _updateAddress(latLng);
  }

  void _animatedMapMove(ll.LatLng destLocation, double destZoom) {
    if (!_mapReady) return;
    _mapAnimationHelper.move(
      destLocation,
      destZoom,
      duration: const Duration(milliseconds: 800),
    );
    _zoomNotifier.value = destZoom;
  }

  Future<void> _updateAddress(ll.LatLng point) async {
    try {
      List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final name = [
          p.street,
          p.subLocality,
          p.locality,
          p.administrativeArea,
        ].where((s) => s != null && s.isNotEmpty).join(', ');

        if (mounted) {
          setState(() {
            _selectedAddress = name;
          });
        }
      }
    } catch (e) {
      // fail silently
    }
  }

  Future<void> _searchLocation() async {
    final query = _searchController.text;
    if (query.isEmpty) return;

    setState(() => _isLoading = true);
    FocusManager.instance.primaryFocus?.unfocus();

    try {
      List<geo.Location> locations = await geo.locationFromAddress(query);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        final latLng = ll.LatLng(loc.latitude, loc.longitude);
        _updateLocation(latLng);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Location not found")));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Search failed: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: EcoColors.clay,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.terracotta.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: AppTheme.terracotta,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Select Location',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.ink,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: IconButton(
                        key: const ValueKey('my_location_btn'),
                        onPressed: _isLoading ? null : _determinePosition,
                        icon: Semantics(
                          label: "Use Current Location",
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Opacity(
                                opacity: _isLoading ? 0 : 1,
                                child: const Icon(
                                  Icons.my_location,
                                  size: 20,
                                  color: AppTheme.forest,
                                ),
                              ),
                              if (_isLoading)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.forest,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      key: const ValueKey('picker_close_btn'),
                      onPressed: () => Navigator.pop(context),
                      icon: Semantics(
                        label: 'Close Picker',
                        child: const Icon(Icons.close),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.ink,
                        ),
                        decoration: InputDecoration(
                          hintText: "Search for a place...",
                          hintStyle: GoogleFonts.inter(
                            color: AppTheme.ink.withValues(alpha: 0.4),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(Icons.search, size: 20),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) => _searchLocation(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Material(
                      color: AppTheme.forest,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: _searchLocation,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 56,
                          height: 56,
                          alignment: Alignment.center,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.search, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _pickedLocation,
                        initialZoom: 15.0,
                        minZoom: 3.0,
                        maxZoom: 18.0,
                        cameraConstraint: CameraConstraint.contain(
                          bounds: LatLngBounds(
                            const ll.LatLng(-85.05, -180.0),
                            const ll.LatLng(85.05, 180.0),
                          ),
                        ),
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all,
                        ),
                        onTap: (tapPosition, point) {
                          FocusManager.instance.primaryFocus?.unfocus();
                          setState(() {
                            _pickedLocation = point;
                          });
                          _updateAddress(point);
                        },
                        onMapReady: () {
                          if (mounted) {
                            setState(() => _mapReady = true);
                            _initLocation();
                          }
                        },
                        onPositionChanged: (pos, hasGesture) {
                          if (hasGesture) {
                            _mapAnimationHelper.stop(force: true);
                          }
                          _zoomNotifier.value = pos.zoom;
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.ecopulse',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _pickedLocation,
                              width: 60,
                              height: 60,
                              rotate: false,
                              child: ValueListenableBuilder<double>(
                                valueListenable: _zoomNotifier,
                                builder: (context, zoom, child) {
                                  final double scale = (zoom / 15.0).clamp(
                                    0.6,
                                    1.3,
                                  );
                                  return Transform.scale(
                                    scale: scale,
                                    child: const Icon(
                                      Icons.location_on,
                                      size: 60,
                                      color: EcoColors.terracotta,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (_selectedAddress != null)
                      Positioned(
                        bottom: 20,
                        left: 20,
                        right: 20,
                        child: EcoPulseCard(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.forest.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.place,
                                  color: AppTheme.forest,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _selectedAddress!,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: AppTheme.ink,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: EcoPulseButton(
                label: 'Confirm Location',
                onPressed: () => Navigator.pop(context, {
                  'latLng': _pickedLocation,
                  'address': _selectedAddress,
                }),
                icon: Icons.check_circle_outline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}