import 'package:flutter/material.dart';
import 'package:frontend/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart' as geolocator;
import '../../providers/mission_provider.dart';
import '../../providers/location_provider.dart';
import '../../widgets/eco_pulse_widgets.dart';

class CreateMissionScreen extends StatefulWidget {
  const CreateMissionScreen({super.key});

  @override
  State<CreateMissionScreen> createState() => _CreateMissionScreenState();
}

class _CreateMissionScreenState extends State<CreateMissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationNameController = TextEditingController();
  final _pointsController = TextEditingController(text: '100');
  final _maxVolunteersController = TextEditingController(text: '10');

  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 11, minute: 0);

  String _priority = 'Normal';
  bool _isEmergency = false;
  final List<int> _selectedCategoryIds = [1]; // Environmental by default
  ll.LatLng? _selectedLocation;

  @override
  Widget build(BuildContext context) {
    return EcoPulseLayout(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Mission Basics Section
              _buildSectionLabel('MISSION BASICS'),
              EcoPulseCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Mission Title'),
                    TextFormField(
                      controller: _titleController,
                      style: AppTheme.lightTheme.textTheme.displaySmall,
                      decoration: const InputDecoration(
                        hintText: 'e.g., Riverside Cleanup',
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 24),
                    _buildFieldLabel('Description'),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText:
                            'What needs to be done? What should volunteers bring?',
                        alignLabelWithHint: true,
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Location & Time Section
              _buildSectionLabel('LOCATION & TIME'),
              EcoPulseCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Location'),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _locationNameController,
                            decoration: const InputDecoration(
                              hintText: 'Enter location name',
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _showLocationPicker,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppTheme.clay,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color.fromRGBO(0, 0, 0, 0.06),
                              ),
                            ),
                            child: const Icon(Icons.map_outlined, size: 20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildFieldLabel('Date'),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _startDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (date != null) setState(() => _startDate = date);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color.fromRGBO(0, 0, 0, 0.06),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(DateFormat('yyyy-MM-dd').format(_startDate)),
                            const Spacer(),
                            const Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Colors.black26,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('Start Time'),
                              _buildTimePicker(
                                _startTime,
                                (t) => setState(() => _startTime = t),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('End Time'),
                              _buildTimePicker(
                                _endTime,
                                (t) => setState(() => _endTime = t),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Mission Settings Section
              _buildSectionLabel('MISSION SETTINGS'),
              EcoPulseCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('Impact Points'),
                              TextFormField(
                                controller: _pointsController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(
                                    Icons.stars_outlined,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('Capacity'),
                              TextFormField(
                                controller: _maxVolunteersController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(
                                    Icons.people_outline,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildFieldLabel('Priority Level'),
                    DropdownButtonFormField<String>(
                      initialValue: _priority,
                      decoration: const InputDecoration(),
                      items: ['Low', 'Normal', 'High', 'Critical']
                          .map(
                            (p) => DropdownMenuItem(
                              value: p,
                              child: Text('$p Priority'),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _priority = v!),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.clay,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color.fromRGBO(0, 0, 0, 0.06),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Emergency Mission',
                                  style:
                                      AppTheme.lightTheme.textTheme.bodyLarge,
                                ),
                                Text(
                                  'Mark as urgent and notify volunteers',
                                  style:
                                      AppTheme.lightTheme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isEmergency,
                            onChanged: (v) => setState(() => _isEmergency = v),
                            activeThumbColor: AppTheme.terracotta,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              EcoPulseButton(label: 'Publish Mission', onPressed: _submit),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        label,
        style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
          letterSpacing: 1,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(fontSize: 13),
      ),
    );
  }

  Widget _buildTimePicker(TimeOfDay time, Function(TimeOfDay) onSelected) {
    return InkWell(
      onTap: () async {
        final t = await showTimePicker(context: context, initialTime: time);
        if (t != null) onSelected(t);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color.fromRGBO(0, 0, 0, 0.06)),
        ),
        child: Text(time.format(context)),
      ),
    );
  }

  void _showLocationPicker() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const LocationPickerModal(),
    );

    if (result != null) {
      final latLng = result['latLng'] as ll.LatLng;
      final address = result['address'] as String?;

      setState(() {
        _selectedLocation = latLng;
        if (address != null && address.isNotEmpty) {
          _locationNameController.text = address;
        }
      });
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final startDateTime = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    final endDateTime = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    if (endDateTime.isBefore(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End time must be after start time'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a mission location on the map'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Publishing mission...'),
        backgroundColor: EcoColors.ink,
      ),
    );

    final provider = Provider.of<MissionProvider>(context, listen: false);

    try {
      await provider.createMission({
        'title': _titleController.text,
        'description': _descriptionController.text,
        'locationName': _locationNameController.text,
        'locationGps':
            '${_selectedLocation!.latitude},${_selectedLocation!.longitude}',
        'startTime': startDateTime.toUtc().toIso8601String(),
        'endTime': endDateTime.toUtc().toIso8601String(),
        'pointsValue': int.parse(_pointsController.text),
        'maxVolunteers': int.parse(_maxVolunteersController.text),
        'priority': _priority,
        'isEmergency': _isEmergency,
        'categoryIds': _selectedCategoryIds,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mission published!'),
            backgroundColor: EcoColors.forest,
          ),
        );
        // Clear form
        _titleController.clear();
        _descriptionController.clear();
        _locationNameController.clear();
        _pointsController.text = '100';
        _maxVolunteersController.text = '10';
        setState(() {
          _selectedLocation = null;
          _priority = 'Normal';
          _isEmergency = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

class LocationPickerModal extends StatefulWidget {
  const LocationPickerModal({super.key});

  @override
  State<LocationPickerModal> createState() => _LocationPickerModalState();
}

class _LocationPickerModalState extends State<LocationPickerModal> {
  // Use a default coordinate, but it will be overridden by initState
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
        // Location services are disabled.
        setState(() => _isLoading = false);
        return;
      }

      geolocator.LocationPermission permission = await geolocator
          .GeolocatorPlatform
          .instance
          .checkPermission();
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

      final position = await geolocator.GeolocatorPlatform.instance
          .getCurrentPosition();
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
      // Silently fail or minimal log
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Location not found")));
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Search failed: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: const BoxDecoration(
        color: EcoColors.clay,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Select Location',
                  style: EcoText.displayMD(context).copyWith(fontSize: 20),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.my_location),
                onPressed: _determinePosition,
                tooltip: "Current Location",
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search Bar
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Search city, street...",
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 0,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _searchLocation(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _searchLocation,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.search),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Map
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
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
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_on,
                              color: EcoColors.terracotta,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (_selectedAddress != null)
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(blurRadius: 10, color: Colors.black12),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.place, color: EcoColors.forest),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedAddress!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
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
          const SizedBox(height: 16),

          // Confirm Button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: EcoPulseButton(
                label: 'Confirm Selection',
                onPressed: () => Navigator.pop(context, {
                  'latLng': _pickedLocation,
                  'address': _selectedAddress,
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
