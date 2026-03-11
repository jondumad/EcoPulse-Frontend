import 'package:flutter/material.dart';
import 'package:frontend/models/mission_model.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:intl/intl.dart';
import '../../providers/mission_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/eco_pulse_widgets.dart';
import '../../widgets/atoms/eco_button.dart';
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
  bool _isSaving = false;
  bool _isTemplate = false;
  bool _isEmergency = false;
  bool _autoPromote = true;

  // Recurrence State
  String _frequency = 'daily';
  List<int> _selectedDaysOfWeek = [];
  int _selectedDayOfMonth = 1;
  DateTime? _recurrenceEndDate;

  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 11, minute: 0);
  String _priority = 'Normal';
  final List<int> _selectedCategoryIds = [1];
  ll.LatLng? _selectedLocation;
  String? _expandedAction;

  final List<Map<String, dynamic>> _localSegments = [];

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

  void _addLocalSegment() {
    showDialog(
      context: context,
      builder: (context) => _LocalSegmentDialog(
        missionDate: _startDate,
        missionStartTime: _startTime,
        missionEndTime: _endTime,
        onSave: (data) {
          setState(() {
            _localSegments.add(data);
          });
          Navigator.pop(context);
        },
      ),
    );
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
    if (_isSaving) return;

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
    setState(() => _isSaving = true);
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
        'autoPromote': _autoPromote,
        'categoryIds': _selectedCategoryIds,
        'status': publish ? null : 'Draft',
        'segments': _localSegments, // Add nested segments
        if (_isTemplate)
          'recurringMission': {
            'frequency': _frequency,
            'dayOfWeek': _frequency == 'weekly' || _frequency == 'biweekly'
                ? _selectedDaysOfWeek.isNotEmpty
                      ? _selectedDaysOfWeek[0]
                      : null
                : null,
            'dayOfMonth': _frequency == 'monthly' ? _selectedDayOfMonth : null,
            'timeOfDay':
                '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
            'endDate': _recurrenceEndDate?.toUtc().toIso8601String(),
          },
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
                  RecurrenceSection(
                    isTemplate: _isTemplate,
                    frequency: _frequency,
                    selectedDaysOfWeek: _selectedDaysOfWeek,
                    selectedDayOfMonth: _selectedDayOfMonth,
                    endDate: _recurrenceEndDate,
                    onFrequencyChanged: (v) => setState(() => _frequency = v),
                    onDaysOfWeekChanged: (v) =>
                        setState(() => _selectedDaysOfWeek = v),
                    onDayOfMonthChanged: (v) =>
                        setState(() => _selectedDayOfMonth = v),
                    onPickEndDate: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate:
                            _recurrenceEndDate ??
                            DateTime.now().add(const Duration(days: 30)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(
                          const Duration(days: 365 * 2),
                        ),
                      );
                      if (d != null) setState(() => _recurrenceEndDate = d);
                    },
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
                    autoPromote: _autoPromote,
                    onEmergencyChanged: (v) => setState(() {
                      _isEmergency = v;
                      if (v) _isTemplate = false;
                    }),
                    onAutoPromoteChanged: (v) =>
                        setState(() => _autoPromote = v),
                    onTemplateChanged: (v) => setState(() {
                      _isTemplate = v;
                      if (v) {
                        _isEmergency = false;
                        _expandedAction = 'save';
                      }
                    }),
                  ),
                  const SizedBox(height: 24),
                  _LocalSegmentList(
                    segments: _localSegments,
                    onAdd: _addLocalSegment,
                    onRemove: (idx) => setState(() => _localSegments.removeAt(idx)),
                    onReorder: (oldIdx, newIdx) {
                      setState(() {
                        if (newIdx > oldIdx) newIdx -= 1;
                        final item = _localSegments.removeAt(oldIdx);
                        _localSegments.insert(newIdx, item);
                      });
                    },
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
      builder: (context, offset, child) =>
          Transform.translate(offset: offset, child: child),
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
            final double availableWidth =
                totalWidth - (gap * (buttonCount - 1));

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
                        isLoading: _isSaving && activeAction == 'save',
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
                    isLoading: _isSaving && activeAction == 'publish',
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

class _LocalSegmentList extends StatelessWidget {
  final List<Map<String, dynamic>> segments;
  final VoidCallback onAdd;
  final Function(int) onRemove;
  final Function(int, int) onReorder;

  const _LocalSegmentList({
    required this.segments,
    required this.onAdd,
    required this.onRemove,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('h:mm a');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Mission Timeline (Segments)', style: EcoText.bodyBoldMD(context).copyWith(fontSize: 18)),
            EcoPulseButton(
              label: 'Add',
              icon: Icons.add,
              isSmall: true,
              onPressed: onAdd,
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (segments.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.clay.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.ink.withValues(alpha: 0.05)),
            ),
            child: const Center(
              child: Text(
                'No segments added. Timeline will be empty.',
                style: TextStyle(fontStyle: FontStyle.italic, color: AppTheme.ink),
              ),
            ),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: segments.length,
            onReorder: onReorder,
            itemBuilder: (context, index) {
              final s = segments[index];
              final start = DateTime.parse(s['startTime']);
              final end = DateTime.parse(s['endTime']);
              return Container(
                key: ValueKey('local_$index'),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.ink.withValues(alpha: 0.1)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: const Icon(Icons.drag_indicator, color: AppTheme.ink),
                  title: Text(s['title'], style: EcoText.bodyBoldSM(context)),
                  subtitle: Text(
                    '${timeFormat.format(start)} - ${timeFormat.format(end)}',
                    style: TextStyle(color: AppTheme.forest, fontSize: 12),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: AppTheme.terracotta),
                    onPressed: () => onRemove(index),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _LocalSegmentDialog extends StatefulWidget {
  final DateTime missionDate;
  final TimeOfDay missionStartTime;
  final TimeOfDay missionEndTime;
  final Function(Map<String, dynamic>) onSave;

  const _LocalSegmentDialog({
    required this.missionDate,
    required this.missionStartTime,
    required this.missionEndTime,
    required this.onSave,
  });

  @override
  State<_LocalSegmentDialog> createState() => _LocalSegmentDialogState();
}

class _LocalSegmentDialogState extends State<_LocalSegmentDialog> {
  final _titleController = TextEditingController();
  late DateTime _start;
  late DateTime _end;

  @override
  void initState() {
    super.initState();
    _start = DateTime(
      widget.missionDate.year,
      widget.missionDate.month,
      widget.missionDate.day,
      widget.missionStartTime.hour,
      widget.missionStartTime.minute,
    );
    _end = DateTime(
      widget.missionDate.year,
      widget.missionDate.month,
      widget.missionDate.day,
      widget.missionEndTime.hour,
      widget.missionEndTime.minute,
    );
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(isStart ? _start : _end),
    );
    if (picked != null) {
      setState(() {
        final d = DateTime(widget.missionDate.year, widget.missionDate.month, widget.missionDate.day, picked.hour, picked.minute);
        if (isStart) {
          _start = d;
        } else {
          _end = d;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('h:mm a');
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Add Timeline Segment', style: EcoText.h3(context)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Segment Title',
              hintText: 'e.g. Introduction',
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _pickTime(true),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.ink.withValues(alpha: 0.1)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Starts at', style: TextStyle(fontSize: 10)),
                        Text(timeFormat.format(_start), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => _pickTime(false),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.ink.withValues(alpha: 0.1)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Ends at', style: TextStyle(fontSize: 10)),
                        Text(timeFormat.format(_end), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        EcoPulseButton(
          label: 'Add Segment',
          isSmall: true,
          onPressed: () {
            if (_titleController.text.isNotEmpty) {
              if (_start.isAfter(_end)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Start time must be before end time')),
                );
                return;
              }
              widget.onSave({
                'title': _titleController.text,
                'startTime': _start.toIso8601String(),
                'endTime': _end.toIso8601String(),
                'order': 0,
              });
            }
          },
        ),
      ],
    );
  }
}
