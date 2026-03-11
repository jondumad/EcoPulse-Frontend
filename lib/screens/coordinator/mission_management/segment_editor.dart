import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/mission_model.dart';
import '../../../services/mission_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/atoms/eco_button.dart';
import '../../../widgets/eco_pulse_widgets.dart';

class SegmentEditor extends StatefulWidget {
  final Mission mission;
  final VoidCallback onSegmentsUpdated;

  const SegmentEditor({
    super.key,
    required this.mission,
    required this.onSegmentsUpdated,
  });

  @override
  State<SegmentEditor> createState() => _SegmentEditorState();
}

class _SegmentEditorState extends State<SegmentEditor> {
  final MissionService _missionService = MissionService();
  List<MissionSegment> _segments = [];

  @override
  void initState() {
    super.initState();
    _segments = List.from(widget.mission.segments);
    _segments.sort((a, b) => a.order.compareTo(b.order));
  }

  Future<void> _refreshSegments() async {
    try {
      final updatedMission = await _missionService.getMissionById(widget.mission.id);
      setState(() {
        _segments = updatedMission.segments;
        _segments.sort((a, b) => a.order.compareTo(b.order));
      });
      widget.onSegmentsUpdated();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error refreshing segments: $e'), backgroundColor: AppTheme.terracotta),
        );
      }
    } finally {
      // Logic for loading state removed as it was unused
    }
  }

  Future<void> _deleteSegment(int segmentId) async {
    try {
      await _missionService.deleteMissionSegment(widget.mission.id, segmentId);
      await _refreshSegments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting segment: $e'), backgroundColor: AppTheme.terracotta),
        );
      }
    }
  }

  Future<void> _reorderSegments(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final item = _segments.removeAt(oldIndex);
    setState(() {
      _segments.insert(newIndex, item);
    });

    try {
      await _missionService.reorderMissionSegments(
        widget.mission.id,
        _segments.map((s) => s.id).toList(),
      );
      widget.onSegmentsUpdated();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error reordering segments: $e'), backgroundColor: AppTheme.terracotta),
        );
      }
      _refreshSegments(); // Rollback
    }
  }

  void _showSegmentDialog({MissionSegment? segment}) {
    showDialog(
      context: context,
      builder: (context) => _SegmentDialog(
        mission: widget.mission,
        segment: segment,
        onSave: (data) async {
          try {
            if (segment == null) {
              await _missionService.createMissionSegment(widget.mission.id, data);
            } else {
              await _missionService.updateMissionSegment(widget.mission.id, segment.id, data);
            }
            if (!mounted) return;
            Navigator.pop(context);
            _refreshSegments();
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error saving segment: $e'), backgroundColor: AppTheme.terracotta),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Mission Segments',
              style: EcoText.bodyBoldMD(context).copyWith(fontSize: 18),
            ),
            EcoPulseButton(
              label: 'Add Segment',
              icon: Icons.add,
              isSmall: true,
              onPressed: () => _showSegmentDialog(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_segments.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.clay.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.ink.withValues(alpha: 0.1)),
            ),
            child: const Center(
              child: Text(
                'No segments added yet. Add segments to create a mission timeline.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.ink, fontStyle: FontStyle.italic),
              ),
            ),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _segments.length,
            onReorder: _reorderSegments,
            itemBuilder: (context, index) {
              final s = _segments[index];
              return _SegmentListItem(
                key: ValueKey(s.id),
                segment: s,
                onEdit: () => _showSegmentDialog(segment: s),
                onDelete: () => _deleteSegment(s.id),
              );
            },
          ),
      ],
    );
  }
}

class _SegmentListItem extends StatelessWidget {
  final MissionSegment segment;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SegmentListItem({
    super.key,
    required this.segment,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('h:mm a');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.ink.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: ReorderableDragStartListener(
          index: 0, // Not used by the listener itself but required by API
          child: const Icon(Icons.drag_indicator, color: AppTheme.ink),
        ),
        title: Text(segment.title, style: EcoText.bodyBoldSM(context)),
        subtitle: Text(
          '${timeFormat.format(segment.startTime)} - ${timeFormat.format(segment.endTime)}',
          style: TextStyle(color: AppTheme.forest, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: onEdit,
              color: AppTheme.ink.withValues(alpha: 0.6),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: onDelete,
              color: AppTheme.terracotta.withValues(alpha: 0.8),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentDialog extends StatefulWidget {
  final Mission mission;
  final MissionSegment? segment;
  final Function(Map<String, dynamic>) onSave;

  const _SegmentDialog({
    required this.mission,
    this.segment,
    required this.onSave,
  });

  @override
  State<_SegmentDialog> createState() => _SegmentDialogState();
}

class _SegmentDialogState extends State<_SegmentDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late DateTime _startTime;
  late DateTime _endTime;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.segment?.title ?? '');
    _descController = TextEditingController(text: widget.segment?.description ?? '');
    _startTime = widget.segment?.startTime ?? widget.mission.startTime;
    _endTime = widget.segment?.endTime ?? widget.mission.endTime;
  }

  Future<void> _pickTime(bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(isStart ? _startTime : _endTime),
    );

    if (picked != null) {
      setState(() {
        final missionDate = widget.mission.startTime;
        if (isStart) {
          _startTime = DateTime(
            missionDate.year,
            missionDate.month,
            missionDate.day,
            picked.hour,
            picked.minute,
          );
        } else {
          _endTime = DateTime(
            missionDate.year,
            missionDate.month,
            missionDate.day,
            picked.hour,
            picked.minute,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('h:mm a');
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(widget.segment == null ? 'Add Segment' : 'Edit Segment', style: EcoText.h3(context)),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title', hintText: 'e.g. Briefing'),
                validator: (v) => v == null || v.isEmpty ? 'Title required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description (Optional)'),
                maxLines: 2,
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
                          border: Border.all(color: AppTheme.ink.withValues(alpha: 0.2)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Start Time', style: TextStyle(fontSize: 12)),
                            Text(timeFormat.format(_startTime), style: const TextStyle(fontWeight: FontWeight.bold)),
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
                          border: Border.all(color: AppTheme.ink.withValues(alpha: 0.2)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('End Time', style: TextStyle(fontSize: 12)),
                            Text(timeFormat.format(_endTime), style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        EcoPulseButton(
          label: 'Save',
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              if (_startTime.isAfter(_endTime)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Start time must be before end time')),
                );
                return;
              }
              widget.onSave({
                'title': _titleController.text,
                'description': _descController.text,
                'startTime': _startTime.toIso8601String(),
                'endTime': _endTime.toIso8601String(),
              });
            }
          },
        ),
      ],
    );
  }
}
