import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:intl/intl.dart';
import '../../models/mission_model.dart';
import '../../providers/mission_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/eco_pulse_widgets.dart';
import '../../widgets/location_picker_modal.dart';
import 'components/create_mission_sections.dart';

class EditMissionScreen extends StatefulWidget {
  final Mission mission;

  const EditMissionScreen({super.key, required this.mission});

  @override
  State<EditMissionScreen> createState() => _EditMissionScreenState();
}

class _EditMissionScreenState extends State<EditMissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _heroKey = GlobalKey();
  final _locationKey = GlobalKey();
  final _settingsKey = GlobalKey();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationNameController;
  late TextEditingController _pointsController;
  late TextEditingController _maxVolunteersController;
  late TextEditingController _emergencyJustificationController;

  bool _isSaving = false;
  bool _isTemplate = false;
  bool _isEmergency = false;
  late DateTime _startDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late String _priority;
  late List<int> _selectedCategoryIds;
  ll.LatLng? _selectedLocation;
  String? _expandedAction;

  @override
  void initState() {
    super.initState();
    final m = widget.mission;
    _titleController = TextEditingController(text: m.title);
    _descriptionController = TextEditingController(text: m.description);
    _locationNameController = TextEditingController(text: m.locationName);
    _pointsController = TextEditingController(text: m.pointsValue.toString());
    _maxVolunteersController = TextEditingController(text: m.maxVolunteers?.toString() ?? '');
    _emergencyJustificationController = TextEditingController(text: m.emergencyJustification ?? '');
    
    _isTemplate = m.isTemplate;
    _isEmergency = m.isEmergency;
    _startDate = m.startTime;
    _startTime = TimeOfDay.fromDateTime(m.startTime);
    _endTime = TimeOfDay.fromDateTime(m.endTime);
    _priority = m.priority;
    _selectedCategoryIds = m.categories.map((c) => c.id).toList();
    
    if (m.locationGps != null) {
      final parts = m.locationGps!.split(',');
      if (parts.length == 2) {
        _selectedLocation = ll.LatLng(
          double.tryParse(parts[0]) ?? 0,
          double.tryParse(parts[1]) ?? 0,
        );
      }
    }

    Future.microtask(() {
      if (!mounted) return;
      Provider.of<MissionProvider>(context, listen: false).fetchCategories();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationNameController.dispose();
    _pointsController.dispose();
    _maxVolunteersController.dispose();
    _emergencyJustificationController.dispose();
    super.dispose();
  }

  void _showLocationPicker() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const LocationPickerModal(),
    );

    if (result != null) {
      setState(() {
        _selectedLocation = result['latLng'] as ll.LatLng;
        if (result['address'] != null) {
          _locationNameController.text = result['address'];
        }
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      // Find the first field with an error and scroll to it
      if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
        Scrollable.ensureVisible(_heroKey.currentContext!, duration: const Duration(milliseconds: 500));
      } else if (_locationNameController.text.isEmpty) {
        Scrollable.ensureVisible(_locationKey.currentContext!, duration: const Duration(milliseconds: 500));
      }
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final startDateTime = DateTime(
        _startDate.year, _startDate.month, _startDate.day,
        _startTime.hour, _startTime.minute,
      );
      final endDateTime = DateTime(
        _startDate.year, _startDate.month, _startDate.day,
        _endTime.hour, _endTime.minute,
      );

      final updateData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'locationName': _locationNameController.text,
        'locationGps': _selectedLocation != null 
            ? '${_selectedLocation!.latitude},${_selectedLocation!.longitude}' 
            : widget.mission.locationGps,
        'startTime': startDateTime.toUtc().toIso8601String(),
        'endTime': endDateTime.toUtc().toIso8601String(),
        'pointsValue': int.tryParse(_pointsController.text) ?? 50,
        'maxVolunteers': int.tryParse(_maxVolunteersController.text),
        'priority': _priority,
        'isEmergency': _isEmergency,
        'emergencyJustification': _emergencyJustificationController.text,
        'isTemplate': _isTemplate,
        'categoryIds': _selectedCategoryIds,
      };

      await Provider.of<MissionProvider>(
        context,
        listen: false,
      ).updateMission(widget.mission.id, updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mission updated successfully'), backgroundColor: EcoColors.forest),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e'), backgroundColor: AppTheme.terracotta),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

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
          'Edit Mission',
          style: EcoText.displayMD(context).copyWith(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
              child: Column(
                children: [
                  HeroCard(
                    key: _heroKey,
                    titleController: _titleController,
                    descriptionController: _descriptionController,
                    isEmergency: _isEmergency,
                    isTemplate: _isTemplate,
                    selectedCategoryIds: _selectedCategoryIds,
                    labelOverride: 'EDITING MISSION',
                  ),
                  const SizedBox(height: 16),
                  CategoryPickerSection(
                    selectedCategoryIds: _selectedCategoryIds,
                    onCategoryToggled: (id, isSelected) {
                      setState(() {
                        if (isSelected && _selectedCategoryIds.length > 1) {
                          _selectedCategoryIds.remove(id);
                        } else if (!isSelected) {
                          _selectedCategoryIds.add(id);
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  LocationScheduleSection(
                    key: _locationKey,
                    locationNameController: _locationNameController,
                    selectedLocation: _selectedLocation,
                    startDate: _startDate,
                    startTime: _startTime,
                    endTime: _endTime,
                    onPickLocation: _showLocationPicker,
                    onPickDate: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _startDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 30)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (d != null) setState(() => _startDate = d);
                    },
                    onPickStartTime: (t) => setState(() => _startTime = t),
                    onPickEndTime: (t) => setState(() => _endTime = t),
                  ),
                  const SizedBox(height: 16),
                  SettingsSection(
                    key: _settingsKey,
                    pointsController: _pointsController,
                    maxVolunteersController: _maxVolunteersController,
                    emergencyJustificationController: _emergencyJustificationController,
                    priority: _priority,
                    isEmergency: _isEmergency,
                    onPriorityChanged: (v) => setState(() => _priority = v),
                  ),
                  const SizedBox(height: 16),
                  TogglesSection(
                    isEmergency: _isEmergency,
                    isTemplate: _isTemplate,
                    onEmergencyChanged: (v) => setState(() {
                      _isEmergency = v;
                    }),
                    // Template status is locked during editing
                    onTemplateChanged: null, 
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: _buildActionButtons(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final String activeAction = _expandedAction ?? 'save';

    return TweenAnimationBuilder<Offset>(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutBack,
      tween: Tween(begin: const Offset(0, 100), end: Offset.zero),
      builder: (context, offset, child) => Transform.translate(
        offset: offset,
        child: child,
      ),
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(minHeight: 85),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double totalWidth = constraints.maxWidth;
            const double gap = 12.0;
            final double availableWidth = totalWidth - gap;

            double saveWidth = 0;

            if (activeAction == 'save') {
              saveWidth = availableWidth * 0.7;
            } else {
              saveWidth = availableWidth * 0.25;
            }

            return Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  width: saveWidth,
                  child: EcoPulseButton(
                    width: saveWidth,
                    label: activeAction == 'save' ? 'Save Changes' : '',
                    icon: Icons.check_circle_outline,
                    isLoading: _isSaving,
                    onPressed: () {
                      if (activeAction == 'save') {
                        _saveChanges();
                      } else {
                        setState(() => _expandedAction = 'save');
                      }
                    },
                  ),
                ),
                const SizedBox(width: gap),
                Expanded(
                  child: EcoPulseButton(
                    width: double.infinity,
                    label: activeAction == 'cancel' ? 'Cancel' : '',
                    icon: Icons.close,
                    backgroundColor: AppTheme.terracotta,
                    onPressed: () {
                      if (activeAction == 'cancel') {
                        Navigator.pop(context);
                      } else {
                        setState(() => _expandedAction = 'cancel');
                      }
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
