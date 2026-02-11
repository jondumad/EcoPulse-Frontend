import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';
import '../theme/app_theme.dart';
import 'eco_pulse_widgets.dart';

class LocationPickerModal extends StatefulWidget {
  const LocationPickerModal({super.key});

  @override
  State<LocationPickerModal> createState() => _LocationPickerModalState();
}

class _LocationPickerModalState extends State<LocationPickerModal> {
  ll.LatLng _pickedLocation = const ll.LatLng(-6.2088, 106.8456);
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  String? _selectedAddress;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initLocation();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    final locProvider = Provider.of<LocationProvider>(context, listen: false);
    if (locProvider.currentPosition != null) {
      setState(() {
        _pickedLocation = locProvider.currentPosition!;
      });
      _mapController.move(_pickedLocation, 15.0);
      _updateAddress(_pickedLocation);
    } else {
      await _determinePosition();
    }
  }

  Future<void> _determinePosition() async {
    setState(() => _isLoading = true);
    try {
      bool serviceEnabled = await geolocator.GeolocatorPlatform.instance
          .isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoading = false);
        return;
      }

      geolocator.LocationPermission permission =
          await geolocator.GeolocatorPlatform.instance.checkPermission();
      if (permission == geolocator.LocationPermission.denied) {
        permission = await geolocator.GeolocatorPlatform.instance
            .requestPermission();
        if (permission == geolocator.LocationPermission.denied) {
          setState(() => _isLoading = false);
          return;
        }
      }

      if (permission == geolocator.LocationPermission.deniedForever) {
        setState(() => _isLoading = false);
        return;
      }

      final position =
          await geolocator.GeolocatorPlatform.instance.getCurrentPosition();
      final latLng = ll.LatLng(position.latitude, position.longitude);

      setState(() {
        _pickedLocation = latLng;
        _isLoading = false;
      });

      _mapController.move(latLng, 15.0);
      _updateAddress(latLng);
    } catch (e) {
      setState(() => _isLoading = false);
    }
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

        setState(() {
          _selectedAddress = name;
        });
      }
    } catch (e) {
      // Silently fail
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

        setState(() {
          _pickedLocation = latLng;
          _isLoading = false;
        });

        _mapController.move(latLng, 15.0);
        _updateAddress(latLng);
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Location not found")),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Search failed: $e")),
        );
      }
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
                        style: EcoText.displayMD(context).copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.my_location),
                      onPressed: _determinePosition,
                      tooltip: "Use Current Location",
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: "Search for a place...",
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
                              : const Icon(
                                  Icons.search,
                                  color: Colors.white,
                                ),
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
                        onTap: (tapPosition, point) {
                          setState(() {
                            _pickedLocation = point;
                          });
                          _updateAddress(point);
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.civic',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _pickedLocation,
                              width: 50,
                              height: 50,
                              child: const Icon(
                                Icons.location_on,
                                color: EcoColors.terracotta,
                                size: 50,
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
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 12,
                                color: Colors.black.withValues(alpha: 0.1),
                              ),
                            ],
                          ),
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
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
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
