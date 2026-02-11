import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:provider/provider.dart';
import '../../../providers/mission_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/eco_pulse_widgets.dart';

class HeroCard extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final bool isEmergency;
  final bool isTemplate;
  final List<int> selectedCategoryIds;
  final String? labelOverride;

  const HeroCard({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.isEmergency,
    required this.isTemplate,
    required this.selectedCategoryIds,
    this.labelOverride,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MissionProvider>(context);
    String categoryIcon = '🌱';
    if (selectedCategoryIds.isNotEmpty) {
      try {
        final cat = provider.categories.firstWhere((c) => c.id == selectedCategoryIds.first);
        categoryIcon = cat.icon;
      } catch (_) {}
    }

    final accentColor = isEmergency 
        ? AppTheme.terracotta 
        : (isTemplate ? AppTheme.violet : AppTheme.forest);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.2), 
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 60,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.0),
                      accentColor.withValues(alpha: 0.08),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.1),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Text(
                          categoryIcon,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isEmergency 
                                      ? Icons.warning_amber_rounded 
                                      : (isTemplate ? Icons.copy_all_rounded : Icons.add_circle_outline),
                                  size: 14,
                                  color: accentColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isEmergency 
                                      ? 'EMERGENCY MISSION' 
                                      : (isTemplate ? 'MISSION TEMPLATE' : 'NEW MISSION'),
                                  style: EcoText.monoSM(context).copyWith(
                                    color: accentColor,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              titleController.text.isEmpty ? 'Untitled Mission' : titleController.text,
                              style: EcoText.displayMD(context).copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: isEmergency 
                                    ? AppTheme.terracotta 
                                    : (isTemplate ? AppTheme.violet : EcoColors.ink),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const _FieldLabel(label: 'Mission Title', icon: Icons.title, isRequired: true),
                  TextFormField(
                    controller: titleController,
                    style: AppTheme.lightTheme.textTheme.displaySmall?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g., Riverside Cleanup Drive',
                      filled: true,
                      fillColor: AppTheme.clay,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                    validator: (v) => v == null || v.isEmpty ? '' : null,
                  ),
                  const SizedBox(height: 20),
                  const _FieldLabel(label: 'Description', icon: Icons.description_outlined, isRequired: true),
                  TextFormField(
                    controller: descriptionController,
                    maxLines: 4,
                    style: const TextStyle(fontSize: 15, height: 1.5),
                    decoration: InputDecoration(
                      hintText:
                          'What needs to be done? What should volunteers bring?',
                      alignLabelWithHint: true,
                      filled: true,
                      fillColor: AppTheme.clay,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(20),
                    ),
                    validator: (v) => v == null || v.isEmpty ? '' : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryPickerSection extends StatelessWidget {
  final List<int> selectedCategoryIds;
  final Function(int, bool) onCategoryToggled;

  const CategoryPickerSection({
    super.key,
    required this.selectedCategoryIds,
    required this.onCategoryToggled,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MissionProvider>(context);
    return _SectionWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _FieldLabel(label: 'Mission Category', icon: Icons.category_outlined),
          const SizedBox(height: 8),
          if (provider.categories.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(strokeWidth: 2),
            ))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: provider.categories.map((cat) {
                final isSelected = selectedCategoryIds.contains(cat.id);
                return InkWell(
                  onTap: () => onCategoryToggled(cat.id, isSelected),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.forest : AppTheme.clay,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppTheme.forest : Colors.black.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(cat.icon, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 8),
                        Text(
                          cat.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : EcoColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class LocationScheduleSection extends StatelessWidget {
  final TextEditingController locationNameController;
  final ll.LatLng? selectedLocation;
  final DateTime startDate;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final VoidCallback onPickLocation;
  final VoidCallback onPickDate;
  final Function(TimeOfDay) onPickStartTime;
  final Function(TimeOfDay) onPickEndTime;

  const LocationScheduleSection({
    super.key,
    required this.locationNameController,
    required this.selectedLocation,
    required this.startDate,
    required this.startTime,
    required this.endTime,
    required this.onPickLocation,
    required this.onPickDate,
    required this.onPickStartTime,
    required this.onPickEndTime,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionWrapper(
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
          const _FieldLabel(label: 'Where', icon: Icons.location_on_outlined, isRequired: true),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: locationNameController,
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
                  validator: (v) => v == null || v.isEmpty ? '' : null,
                ),
              ),
              const SizedBox(width: 12),
              Material(
                color: AppTheme.forest,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: onPickLocation,
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
          if (selectedLocation != null) ...[
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
                  const Icon(Icons.check_circle, color: AppTheme.forest, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'GPS COORDINATES LOCKED',
                      style: EcoText.monoSM(context).copyWith(
                        color: AppTheme.forest,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          const _FieldLabel(label: 'Date', icon: Icons.calendar_today_outlined),
          InkWell(
            onTap: onPickDate,
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
                    DateFormat('EEEE, MMMM d, yyyy').format(startDate),
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
                    const _FieldLabel(label: 'Start', icon: Icons.access_time),
                    _TimePickerButton(time: startTime, onPick: onPickStartTime, isStart: true),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FieldLabel(label: 'End', icon: Icons.access_time_filled),
                    _TimePickerButton(time: endTime, onPick: onPickEndTime, isStart: false),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SettingsSection extends StatelessWidget {
  final TextEditingController pointsController;
  final TextEditingController maxVolunteersController;
  final TextEditingController emergencyJustificationController;
  final String priority;
  final bool isEmergency;
  final Function(String) onPriorityChanged;

  const SettingsSection({
    super.key,
    required this.pointsController,
    required this.maxVolunteersController,
    required this.emergencyJustificationController,
    required this.priority,
    required this.isEmergency,
    required this.onPriorityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionWrapper(
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
                child: _CompactField(
                  label: 'Impact Points',
                  icon: Icons.stars_outlined,
                  controller: pointsController,
                  color: AppTheme.forest,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CompactField(
                  label: 'Max Vol.',
                  icon: Icons.people_outline,
                  controller: maxVolunteersController,
                  color: AppTheme.forest,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _FieldLabel(label: 'Priority Level', icon: Icons.flag_outlined),
          DropdownButtonFormField<String>(
            initialValue: priority,
            borderRadius: BorderRadius.circular(16),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppTheme.clay,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            icon: const Icon(Icons.arrow_drop_down),
            items: [
              _buildPriorityItem('Low', Icons.arrow_downward, Colors.blue),
              _buildPriorityItem('Normal', Icons.remove, Colors.grey),
              _buildPriorityItem('High', Icons.arrow_upward, Colors.orange),
              _buildPriorityItem('Critical', Icons.priority_high, Colors.red),
            ],
            onChanged: (v) => onPriorityChanged(v!),
          ),
          
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: isEmergency 
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    const _FieldLabel(
                      label: 'Emergency Justification',
                      icon: Icons.warning_amber_outlined,
                    ),
                    TextFormField(
                      controller: emergencyJustificationController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Why is this mission an emergency?',
                        filled: true,
                        fillColor: AppTheme.clay,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      validator: (v) {
                        if (isEmergency) {
                          if (v == null || v.isEmpty) return 'Required for emergency';
                          if (v.length < 20) return 'Minimum 20 characters required';
                        }
                        return null;
                      },
                    ),
                  ],
                )
              : const SizedBox(width: double.infinity),
          ),
        ],
      ),
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
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class TogglesSection extends StatelessWidget {
  final bool isEmergency;
  final bool isTemplate;
  final ValueChanged<bool> onEmergencyChanged;
  final ValueChanged<bool>? onTemplateChanged;

  const TogglesSection({
    super.key,
    required this.isEmergency,
    required this.isTemplate,
    required this.onEmergencyChanged,
    this.onTemplateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ToggleCard(
          title: 'Emergency Mission',
          subtitle: 'Mark as urgent & send alerts',
          icon: Icons.emergency_outlined,
          value: isEmergency,
          color: AppTheme.terracotta,
          onChanged: onEmergencyChanged,
        ),
        if (onTemplateChanged != null) ...[
          const SizedBox(height: 12),
          _ToggleCard(
            title: 'Save as Template',
            subtitle: 'Reuse configuration later',
            icon: Icons.bookmark_border_outlined,
            value: isTemplate,
            color: AppTheme.violet,
            onChanged: onTemplateChanged!,
          ),
        ],
      ],
    );
  }
}

// --- Helper Internal Components ---

class _SectionWrapper extends StatelessWidget {
  final Widget child;
  const _SectionWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
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
      child: child,
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isRequired;
  const _FieldLabel({required this.label, required this.icon, this.isRequired = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.ink.withValues(alpha: 0.6)),
          const SizedBox(width: 8),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: AppTheme.ink.withValues(alpha: 0.5),
            ),
          ),
          if (isRequired) ...[
            const SizedBox(width: 4),
            const Icon(Icons.star, size: 8, color: AppTheme.terracotta),
          ],
        ],
      ),
    );
  }
}

class _TimePickerButton extends StatelessWidget {
  final TimeOfDay time;
  final Function(TimeOfDay) onPick;
  final bool isStart;

  const _TimePickerButton({required this.time, required this.onPick, required this.isStart});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final t = await showTimePicker(context: context, initialTime: time);
        if (t != null) onPick(t);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.clay,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isStart ? Icons.login : Icons.logout,
              size: 16,
              color: AppTheme.ink.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 8),
            Text(
              time.format(context),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactField extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final Color color;

  const _CompactField({
    required this.label,
    required this.icon,
    required this.controller,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
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
            fillColor: AppTheme.clay,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }
}

class _ToggleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final Color color;
  final ValueChanged<bool> onChanged;

  const _ToggleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
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
}
