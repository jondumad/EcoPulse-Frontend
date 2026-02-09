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
import '../../models/mission_model.dart';

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
  final _emergencyJustificationController = TextEditingController();
  bool _isTemplate = false;

  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 11, minute: 0);

  String _priority = 'Normal';
  bool _isEmergency = false;
  final List<int> _selectedCategoryIds = [1]; // Environmental by default
  ll.LatLng? _selectedLocation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EcoColors.clay,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: EcoColors.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Create Mission',
          style: EcoText.displayMD(context).copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _showTemplatePicker,
            icon: const Icon(Icons.dashboard_customize_outlined, size: 18),
            label: const Text('Templates'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.forest,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero card for basics
              _buildHeroCard(),
              const SizedBox(height: 16),

              // Location & Schedule Card
              _buildLocationScheduleCard(),
              const SizedBox(height: 16),

              // Settings Grid
              _buildSettingsCard(),
              const SizedBox(height: 16),

              // Toggles Section
              _buildTogglesSection(),
              const SizedBox(height: 24),

              // Action Buttons
              _buildActionButtons(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.forest.withValues(alpha: 0.05),
            AppTheme.violet.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 2),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.forest.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.flag_outlined,
                  color: AppTheme.forest,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Mission Details',
                  style: EcoText.displayMD(context).copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildFieldLabel('Mission Title', Icons.title),
          TextFormField(
            controller: _titleController,
            style: AppTheme.lightTheme.textTheme.displaySmall?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'e.g., Riverside Cleanup Drive',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 20),
          _buildFieldLabel('Description', Icons.description_outlined),
          TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            style: const TextStyle(fontSize: 15, height: 1.5),
            decoration: InputDecoration(
              hintText:
                  'What needs to be done? What should volunteers bring? Any special instructions?',
              alignLabelWithHint: true,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(20),
            ),
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationScheduleCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  Icons.place_outlined,
                  color: AppTheme.terracotta,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Location & Schedule',
                style: EcoText.displayMD(context).copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildFieldLabel('Where', Icons.location_on_outlined),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _locationNameController,
                  decoration: InputDecoration(
                    hintText: 'Enter location name',
                    filled: true,
                    fillColor: AppTheme.clay,
                    prefixIcon: const Icon(Icons.edit_location_outlined, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 12),
              Material(
                color: AppTheme.forest,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: _showLocationPicker,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.map_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_selectedLocation != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.forest.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.forest.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppTheme.forest,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Location set: ${_selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.forest,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          _buildFieldLabel('When', Icons.calendar_today_outlined),
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _startDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) setState(() => _startDate = date);
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: AppTheme.clay,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event, size: 20, color: AppTheme.ink),
                  const SizedBox(width: 12),
                  Text(
                    DateFormat('EEEE, MMMM d, yyyy').format(_startDate),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_drop_down,
                    color: AppTheme.ink.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Start', Icons.access_time),
                    _buildTimePicker(
                      _startTime,
                      (t) => setState(() => _startTime = t),
                      isStart: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('End', Icons.access_time_filled),
                    _buildTimePicker(
                      _endTime,
                      (t) => setState(() => _endTime = t),
                      isStart: false,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.violet.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.tune_outlined,
                  color: AppTheme.violet,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Mission Settings',
                style: EcoText.displayMD(context).copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildCompactField(
                  label: 'Impact Points',
                  icon: Icons.stars_outlined,
                  controller: _pointsController,
                  color: AppTheme.forest,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCompactField(
                  label: 'Max Volunteers',
                  icon: Icons.people_outline,
                  controller: _maxVolunteersController,
                  color: AppTheme.forest,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildFieldLabel('Priority Level', Icons.flag_outlined),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.clay,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonFormField<String>(
              initialValue: _priority,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(Icons.arrow_drop_down),
              items: [
                _buildPriorityItem('Low', Icons.arrow_downward, Colors.blue),
                _buildPriorityItem('Normal', Icons.remove, Colors.grey),
                _buildPriorityItem('High', Icons.arrow_upward, Colors.orange),
                _buildPriorityItem(
                    'Critical', Icons.priority_high, Colors.red),
              ],
              onChanged: (v) => setState(() => _priority = v!),
            ),
          ),
          if (_isEmergency) ...[
            const SizedBox(height: 20),
            _buildFieldLabel(
              'Emergency Justification',
              Icons.warning_amber_outlined,
            ),
            TextFormField(
              controller: _emergencyJustificationController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText:
                    'Why is this mission an emergency? Provide details...',
                filled: true,
                fillColor: Colors.red.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.red.shade200),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              validator: (v) {
                if (_isEmergency) {
                  if (v == null || v.isEmpty) return 'Required for emergency';
                  if (v.length < 20) return 'Minimum 20 characters required';
                }
                return null;
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTogglesSection() {
    return Column(
      children: [
        _buildToggleCard(
          title: 'Emergency Mission',
          subtitle: 'Mark as urgent & send immediate notifications',
          icon: Icons.emergency_outlined,
          value: _isEmergency,
          color: AppTheme.terracotta,
          onChanged: (v) => setState(() => _isEmergency = v),
        ),
        const SizedBox(height: 12),
        _buildToggleCard(
          title: 'Save as Template',
          subtitle: 'Reuse this mission configuration later',
          icon: Icons.bookmark_border_outlined,
          value: _isTemplate,
          color: AppTheme.violet,
          onChanged: (v) => setState(() => _isTemplate = v),
        ),
      ],
    );
  }

  Widget _buildToggleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required Color color,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value ? color.withValues(alpha: 0.3) : Colors.transparent,
          width: 2,
        ),
        boxShadow: value
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: EcoColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: EcoColors.ink.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: color,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        EcoPulseButton(
          label: 'Publish Mission',
          onPressed: _submit,
          icon: Icons.rocket_launch_outlined,
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            side: BorderSide(color: AppTheme.ink.withValues(alpha: 0.2)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text(
            'Cancel',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: EcoColors.ink,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: EcoColors.ink.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: color.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }

  DropdownMenuItem<String> _buildPriorityItem(
      String label, IconData icon, Color color) {
    return DropdownMenuItem(
      value: label,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          Text(
            '$label Priority',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.ink.withValues(alpha: 0.6)),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              color: AppTheme.ink.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePicker(
    TimeOfDay time,
    Function(TimeOfDay) onSelected, {
    required bool isStart,
  }) {
    return InkWell(
      onTap: () async {
        final t = await showTimePicker(context: context, initialTime: time);
        if (t != null) onSelected(t);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.clay,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isStart ? Icons.login : Icons.logout,
              size: 18,
              color: AppTheme.ink.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 8),
            Text(
              time.format(context),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLocationPicker() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Text('Publishing mission...'),
          ],
        ),
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
        'emergencyJustification': _emergencyJustificationController.text,
        'isTemplate': _isTemplate,
        'categoryIds': _selectedCategoryIds,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Mission published successfully!'),
              ],
            ),
            backgroundColor: EcoColors.forest,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _showTemplatePicker() async {
    final provider = Provider.of<MissionProvider>(context, listen: false);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: AppTheme.forest),
      ),
    );

    await provider.fetchTemplates();
    if (!mounted) return;
    Navigator.pop(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: EcoColors.clay,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.violet.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.dashboard_customize_outlined,
                      color: AppTheme.violet,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Mission Templates',
                    style: EcoText.displayMD(context).copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Consumer<MissionProvider>(
                builder: (context, prov, _) {
                  if (prov.templates.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: AppTheme.ink.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No templates available',
                            style: EcoText.bodyMD(context).copyWith(
                              color: AppTheme.ink.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: prov.templates.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final template = prov.templates[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.forest.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.content_copy,
                              color: AppTheme.forest,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            template.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              template.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.ink.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () {
                            Navigator.pop(ctx);
                            _populateFormFromTemplate(template);
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _populateFormFromTemplate(Mission template) {
    setState(() {
      _titleController.text = template.title;
      _descriptionController.text = template.description;
      _locationNameController.text = template.locationName;
      _pointsController.text = template.pointsValue.toString();
      _maxVolunteersController.text = (template.maxVolunteers ?? 10).toString();
      _priority = template.priority;
      _isEmergency = false;

      if (template.locationGps != null && template.locationGps!.contains(',')) {
        final parts = template.locationGps!.split(',');
        final lat = double.tryParse(parts[0]);
        final lng = double.tryParse(parts[1]);
        if (lat != null && lng != null) {
          _selectedLocation = ll.LatLng(lat, lng);
        }
      }

      _selectedCategoryIds.clear();
      for (var c in template.categories) {
        _selectedCategoryIds.add(c.id);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Template loaded successfully'),
          ],
        ),
        backgroundColor: AppTheme.violet,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}




// LocationPickerModal remains the same as in your original code
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