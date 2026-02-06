import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/mission_model.dart';
import '../../providers/mission_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/eco_pulse_widgets.dart';
import '../../widgets/eco_app_bar.dart';

class EditMissionScreen extends StatefulWidget {
  final Mission mission;

  const EditMissionScreen({super.key, required this.mission});

  @override
  State<EditMissionScreen> createState() => _EditMissionScreenState();
}

class _EditMissionScreenState extends State<EditMissionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationNameController;
  late TextEditingController _pointsController;
  late TextEditingController _maxVolunteersController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.mission.title);
    _descriptionController = TextEditingController(
      text: widget.mission.description,
    );
    _locationNameController = TextEditingController(
      text: widget.mission.locationName,
    );
    _pointsController = TextEditingController(
      text: widget.mission.pointsValue.toString(),
    );
    _maxVolunteersController = TextEditingController(
      text: widget.mission.maxVolunteers?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationNameController.dispose();
    _pointsController.dispose();
    _maxVolunteersController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final updateData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'locationName': _locationNameController.text,
        'pointsValue': int.tryParse(_pointsController.text) ?? 50,
        'maxVolunteers': int.tryParse(_maxVolunteersController.text),
      };

      await Provider.of<MissionProvider>(
        context,
        listen: false,
      ).updateMission(widget.mission.id, updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mission updated successfully')),
        );
        Navigator.pop(context, true); // Return true to indicate refresh needed
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
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
    return EcoPulseLayout(
      appBar: EcoAppBar(
        height: 100,
        titleWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ADMINISTRATION',
              style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.ink.withValues(alpha: 0.6),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Edit Mission',
              style: AppTheme.lightTheme.textTheme.displayLarge,
            ),
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Basic Info'),
              EcoTextField(
                controller: _titleController,
                label: 'Mission Title',
                hint: 'e.g. Beach Cleanup',
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              EcoTextField(
                controller: _descriptionController,
                label: 'Description',
                hint: 'Describe the mission...',
                maxLines: 4,
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 24),

              _buildSectionHeader('Logistics'),
              EcoTextField(
                controller: _locationNameController,
                label: 'Location Name',
                hint: 'e.g. Central Park',
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: EcoTextField(
                      controller: _pointsController,
                      label: 'Points',
                      hint: '50',
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (int.tryParse(v) == null) return 'Invalid number';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: EcoTextField(
                      controller: _maxVolunteersController,
                      label: 'Max Volunteers',
                      hint: 'Optional',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: EcoPulseButton(
                  label: _isSaving ? 'SAVING...' : 'SAVE CHANGES',
                  onPressed: _isSaving ? null : _saveChanges,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title.toUpperCase(),
        style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
          color: AppTheme.forest,
        ),
      ),
    );
  }
}
