import 'package:flutter/material.dart';
import 'package:frontend/models/mission_model.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../../providers/mission_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/eco_pulse_widgets.dart';
import '../../widgets/location_picker_modal.dart';
import '../../widgets/mission_template_picker.dart';
import 'components/create_mission_sections.dart';

class CreateMissionScreen extends StatefulWidget {
  final Mission? template;
  const CreateMissionScreen({super.key, this.template});

  @override
  State<CreateMissionScreen> createState() => _CreateMissionScreenState();
}

class _CreateMissionScreenState extends State<CreateMissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _heroKey = GlobalKey();
  final _locationKey = GlobalKey();
  final _settingsKey = GlobalKey();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationNameController = TextEditingController();
  final _pointsController = TextEditingController(text: '100');
  final _maxVolunteersController = TextEditingController(text: '10');
  final _emergencyJustificationController = TextEditingController();

  bool _isTemplate = false;
  bool _isEmergency = false;
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 11, minute: 0);
  String _priority = 'Normal';
  final List<int> _selectedCategoryIds = [1];
  ll.LatLng? _selectedLocation;
  String? _expandedAction;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      Provider.of<MissionProvider>(context, listen: false).fetchCategories();
      
      if (widget.template != null) {
        _applyTemplate(widget.template!);
      }
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

  // --- Helpers ---

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

  Future<void> _submit({bool publish = true}) async {
    if (!_formKey.currentState!.validate()) {
      // Find the first field with an error and scroll to it
      if (_titleController.text.isEmpty ||
          _descriptionController.text.isEmpty) {
        Scrollable.ensureVisible(
          _heroKey.currentContext!,
          duration: const Duration(milliseconds: 500),
        );
      } else if (_locationNameController.text.isEmpty) {
        Scrollable.ensureVisible(
          _locationKey.currentContext!,
          duration: const Duration(milliseconds: 500),
        );
      } else if (_isEmergency &&
          _emergencyJustificationController.text.length < 20) {
        Scrollable.ensureVisible(
          _settingsKey.currentContext!,
          duration: const Duration(milliseconds: 500),
        );
      }
      return;
    }
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please lock coordinates using the map button'),
          backgroundColor: AppTheme.terracotta,
        ),
      );
      Scrollable.ensureVisible(
        _locationKey.currentContext!,
        duration: const Duration(milliseconds: 500),
      );
      return;
    }

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
        'status': publish ? null : 'Draft',
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
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
          'Create Mission',
          style: EcoText.displayMD(
            context,
          ).copyWith(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            onPressed: _showTemplatePicker,
            icon: const Icon(
              Icons.dashboard_customize_outlined,
              color: AppTheme.forest,
            ),
            tooltip: 'Templates',
          ),
          const SizedBox(width: 8),
        ],
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
                        firstDate: DateTime.now(),
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
                    emergencyJustificationController:
                        _emergencyJustificationController,
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
                      if (v) _isTemplate = false;
                    }),
                    onTemplateChanged: (v) => setState(() {
                      _isTemplate = v;
                      if (v) {
                        _isEmergency = false;
                        _expandedAction = 'save';
                      }
                    }),
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
    final String activeAction =
        _expandedAction ?? (_isTemplate ? 'save' : 'publish');

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
        constraints: const BoxConstraints(minHeight: 85), // Minimum height
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
            final int buttonCount = _isTemplate ? 3 : 2;
            final double availableWidth = totalWidth - (gap * (buttonCount - 1));

            double saveWidth = 0;
            double publishWidth = 0;

            if (_isTemplate) {
              if (activeAction == 'save') {
                saveWidth = availableWidth * 0.5;
                publishWidth = availableWidth * 0.22;
              } else if (activeAction == 'publish') {
                saveWidth = availableWidth * 0.22;
                publishWidth = availableWidth * 0.5;
              } else {
                saveWidth = availableWidth * 0.22;
                publishWidth = availableWidth * 0.22;
              }
            } else {
              if (activeAction == 'publish') {
                publishWidth = availableWidth * 0.7;
              } else {
                publishWidth = availableWidth * 0.25;
              }
            }

            return Row(
              children: [
                if (_isTemplate) ...[
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    width: _isTemplate ? saveWidth : 0,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _isTemplate ? 1.0 : 0.0,
                      child: EcoPulseButton(
                        width: saveWidth,
                        label: activeAction == 'save' ? 'Save Template' : '',
                        icon: Icons.save_outlined,
                        backgroundColor: AppTheme.violet,
                        onPressed: () {
                          if (activeAction == 'save') {
                            _submit(publish: false);
                          } else {
                            setState(() => _expandedAction = 'save');
                          }
                        },
                      ),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    width: _isTemplate ? gap : 0,
                    child: const SizedBox(width: gap),
                  ),
                ],
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  width: publishWidth,
                  child: EcoPulseButton(
                    width: publishWidth,
                    label: activeAction == 'publish' 
                      ? (_isTemplate ? 'Publish & Save' : 'Publish Mission') 
                      : '',
                    icon: Icons.rocket_launch_outlined,
                    onPressed: () {
                      if (activeAction == 'publish') {
                        _submit();
                      } else {
                        setState(() => _expandedAction = 'publish');
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

  void _showTemplatePicker() {
    MissionTemplatePicker.show(context, onTemplateSelected: _applyTemplate);
  }

  void _applyTemplate(Mission t) {
    setState(() {
      _titleController.text = t.title;
      _descriptionController.text = t.description;
      _locationNameController.text = t.locationName;
      _priority = t.priority;
      _pointsController.text = t.pointsValue.toString();
      _maxVolunteersController.text = (t.maxVolunteers ?? 10).toString();
      
      if (t.categories.isNotEmpty) {
        _selectedCategoryIds.clear();
        _selectedCategoryIds.addAll(t.categories.map((c) => c.id));
      }
    });
  }
}