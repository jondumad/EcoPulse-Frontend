import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:add_2_calendar/add_2_calendar.dart' as calendar;
import '../../models/mission_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mission_provider.dart';
import '../../theme/app_theme.dart';
import '../../components/grain_overlay.dart';
import 'check_in_screen.dart';
import '../coordinator/qr_display.dart';

class MissionDetailScreen extends StatefulWidget {
  final Mission mission;

  const MissionDetailScreen({super.key, required this.mission});

  @override
  State<MissionDetailScreen> createState() => _MissionDetailScreenState();
}

class _MissionDetailScreenState extends State<MissionDetailScreen>
    with SingleTickerProviderStateMixin {
  bool _isDescriptionExpanded = false;
  late AnimationController _tiltController;

  @override
  void initState() {
    super.initState();
    _tiltController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
  }

  @override
  void dispose() {
    _tiltController.dispose();
    super.dispose();
  }

  String _getCategoryIcon(String categoryName) {
    if (widget.mission.categories.isNotEmpty) {
      final category = widget.mission.categories.firstWhere(
        (cat) => cat.name == categoryName,
        orElse: () => widget.mission.categories.first,
      );
      return category.icon;
    }
    return '📋';
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final isFull =
        widget.mission.maxVolunteers != null &&
        widget.mission.currentVolunteers >= widget.mission.maxVolunteers!;

    return Scaffold(
      backgroundColor: AppTheme.clay,
      body: Stack(
        children: [
          const Positioned.fill(child: GrainOverlay()),

          SafeArea(
            child: Column(
              children: [
                // Top Navigation Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _TopButton(
                        icon: Icons.arrow_back,
                        onPressed: () => Navigator.pop(context),
                      ),
                      _TopButton(
                        icon: Icons.share,
                        onPressed: () => _shareMission(context),
                      ),
                    ],
                  ),
                ),

                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        // Main Mission Card
                        _MissionCard(
                          mission: widget.mission,
                          isDescriptionExpanded: _isDescriptionExpanded,
                          onDescriptionToggle: () {
                            setState(() {
                              _isDescriptionExpanded = !_isDescriptionExpanded;
                            });
                          },
                          categoryIcon: _getCategoryIcon(
                            widget.mission.categories.isNotEmpty
                                ? widget.mission.categories.first.name
                                : '',
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Action Buttons
                        _ActionButtons(
                          mission: widget.mission,
                          userRole: user?.role,
                          isFull: isFull,
                        ),

                        const SizedBox(height: 100), // Bottom padding
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _shareMission(BuildContext context) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Text('📤'),
            SizedBox(width: 12),
            Text('Share link copied!'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.forest,
        duration: Duration(seconds: 2),
      ),
    );
  }
}

// Top Button Widget
class _TopButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _TopButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.borderSubtle),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.ink, size: 20),
        ),
      ),
    );
  }
}

// Main Mission Card
class _MissionCard extends StatelessWidget {
  final Mission mission;
  final bool isDescriptionExpanded;
  final VoidCallback onDescriptionToggle;
  final String categoryIcon;

  const _MissionCard({
    required this.mission,
    required this.isDescriptionExpanded,
    required this.onDescriptionToggle,
    required this.categoryIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.borderSubtle),
        boxShadow: const [
          BoxShadow(
            color: AppTheme.paperShadow,
            offset: Offset(8, 8),
            blurRadius: 0,
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            children: [
              // Hero Section with Icon
              _HeroSection(icon: categoryIcon, title: mission.title),

              // Quick Stats Grid
              _QuickStatsGrid(mission: mission),

              // Info Items
              _InfoSection(mission: mission),

              // Map Quick View
              _MapQuickView(gps: mission.locationGps),

              // Expandable Description
              _ExpandableDescription(
                description: mission.description,
                isExpanded: isDescriptionExpanded,
                onToggle: onDescriptionToggle,
              ),
            ],
          ),

          // Floating Category Tags
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Wrap(
              spacing: 6,
              children: mission.categories
                  .take(2)
                  .map((cat) => _FloatingTag(category: cat))
                  .toList(),
            ),
          ),

          // Registered/Status Stamp
          if (mission.isRegistered)
            Positioned(
              top: -8,
              right: -8,
              child: _StatusStamp(
                status: mission.registrationStatus ?? 'Registered',
              ),
            ),
        ],
      ),
    );
  }
}

// Hero Section
class _HeroSection extends StatelessWidget {
  final String icon;
  final String title;

  const _HeroSection({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.forest, const Color(0xFF153827)],
        ),
      ),
      child: Stack(
        children: [
          // Purple glow
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.violet,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.violet.withValues(alpha: 0.4),
                    blurRadius: 50,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),

          // Content
          Column(
            children: [
              Text(icon, style: const TextStyle(fontSize: 72)),
              const SizedBox(height: 16),
              Text(
                title,
                style: AppTheme.lightTheme.textTheme.displayMedium?.copyWith(
                  color: Colors.white,
                  fontSize: 26,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Quick Stats Grid
class _QuickStatsGrid extends StatelessWidget {
  final Mission mission;

  const _QuickStatsGrid({required this.mission});

  @override
  Widget build(BuildContext context) {
    final isFull =
        mission.maxVolunteers != null &&
        mission.currentVolunteers >= mission.maxVolunteers!;

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderSubtle)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _StatItem(
              label: 'Points',
              value: '+${mission.pointsValue}',
              isHighlight: true,
            ),
            Container(width: 1, color: AppTheme.borderSubtle),
            _StatItem(
              label: 'Spots',
              value:
                  '${mission.currentVolunteers}/${mission.maxVolunteers ?? "∞"}',
            ),
            Container(width: 1, color: AppTheme.borderSubtle),
            _StatItem(
              label: 'Status',
              value: isFull ? 'FULL' : 'OPEN',
              isUrgent: isFull,
              isHighlight: !isFull,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;
  final bool isUrgent;

  const _StatItem({
    required this.label,
    required this.value,
    this.isHighlight = false,
    this.isUrgent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            Text(
              label,
              style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                color: AppTheme.ink.withValues(alpha: 0.5),
                fontSize: 9,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTheme.lightTheme.textTheme.displaySmall?.copyWith(
                fontSize: 20,
                color: isUrgent
                    ? AppTheme.terracotta
                    : isHighlight
                    ? AppTheme.forest
                    : AppTheme.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Info Section
class _InfoSection extends StatelessWidget {
  final Mission mission;

  const _InfoSection({required this.mission});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _InfoItem(
            icon: Icons.calendar_today_outlined,
            text: DateFormat('EEE, MMM dd • HH:mm').format(mission.startTime),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppTheme.borderSubtle),
          const SizedBox(height: 12),
          _InfoItem(
            icon: Icons.location_on_outlined,
            text: '${mission.locationName} • 2.3 mi',
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    final event = calendar.Event(
                      title: mission.title,
                      description: mission.description,
                      location: mission.locationName,
                      startDate: mission.startTime,
                      endDate: mission.endTime,
                    );
                    calendar.Add2Calendar.addEvent2Cal(event);
                  },
                  icon: const Icon(Icons.calendar_month, size: 18),
                  label: const Text('Save Date'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.ink,
                    side: const BorderSide(color: AppTheme.borderSubtle),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Reminder set for 1 hour before!'),
                        backgroundColor: AppTheme.forest,
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.notifications_active_outlined,
                    size: 18,
                  ),
                  label: const Text('Remind Me'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.ink,
                    side: const BorderSide(color: AppTheme.borderSubtle),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.ink.withValues(alpha: 0.6)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// Map Quick View
class _MapQuickView extends StatelessWidget {
  final String? gps;

  const _MapQuickView({this.gps});

  ll.LatLng? _parseGps() {
    if (gps == null) return null;
    try {
      final parts = gps!.split(',');
      if (parts.length != 2) return null;
      return ll.LatLng(
        double.parse(parts[0].trim()),
        double.parse(parts[1].trim()),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final center = _parseGps();
    if (center == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        // Open map
      },
      child: Container(
        height: 100,
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: AppTheme.borderSubtle),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: ColorFiltered(
                colorFilter: const ColorFilter.matrix(<double>[
                  0.393,
                  0.769,
                  0.189,
                  0,
                  0,
                  0.349,
                  0.686,
                  0.168,
                  0,
                  0,
                  0.272,
                  0.534,
                  0.131,
                  0,
                  0,
                  0,
                  0,
                  0,
                  0.7,
                  0,
                ]),
                child: IgnorePointer(
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: center,
                      initialZoom: 15.0,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.none,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.civic',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('📍', style: TextStyle(fontSize: 32)),
                  const SizedBox(height: 4),
                  Text(
                    'TAP FOR DIRECTIONS',
                    style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                      fontSize: 10,
                      color: AppTheme.ink.withValues(alpha: 0.6),
                    ),
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

// Expandable Description
class _ExpandableDescription extends StatelessWidget {
  final String description;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _ExpandableDescription({
    required this.description,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onToggle,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'MISSION BRIEF',
                  style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                    fontSize: 10,
                    color: AppTheme.ink.withValues(alpha: 0.5),
                  ),
                ),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: const Icon(Icons.keyboard_arrow_down, size: 16),
                ),
              ],
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                description,
                style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }
}

// Floating Tag
class _FloatingTag extends StatelessWidget {
  final Category category;

  const _FloatingTag({required this.category});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.03,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.terracotta,
          borderRadius: BorderRadius.circular(2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              offset: Offset(2, 2),
              blurRadius: 6,
            ),
          ],
        ),
        child: Text(
          category.name.toUpperCase(),
          style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
            color: Colors.white,
            fontSize: 9,
          ),
        ),
      ),
    );
  }
}

// Status Stamp (Replaced _RegisteredStamp)
class _StatusStamp extends StatelessWidget {
  final String status;
  const _StatusStamp({required this.status});

  @override
  Widget build(BuildContext context) {
    Color stampColor = AppTheme.forest;
    String displayStatus = 'REGIS-\nTERED';

    if (status == 'CheckedIn') {
      stampColor = AppTheme.violet;
      displayStatus = 'CHECKED\nIN';
    } else if (status == 'Completed') {
      stampColor = Colors.orange;
      displayStatus = 'COMPLE-\nTED';
    }

    return Transform.rotate(
      angle: 0.26, // ~15 degrees
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: stampColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              offset: Offset(0, 4),
              blurRadius: 12,
            ),
          ],
        ),
        child: Center(
          child: Text(
            displayStatus,
            textAlign: TextAlign.center,
            style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontSize: 8,
              height: 1.3,
            ),
          ),
        ),
      ),
    );
  }
}

// Action Buttons
class _ActionButtons extends StatelessWidget {
  final Mission mission;
  final String? userRole;
  final bool isFull;

  const _ActionButtons({
    required this.mission,
    required this.userRole,
    required this.isFull,
  });

  @override
  Widget build(BuildContext context) {
    if (userRole == 'Coordinator' || userRole == 'SuperAdmin') {
      return _buildCoordinatorActions(context);
    }

    if (userRole == 'Volunteer') {
      if (mission.isRegistered) {
        return _buildRegisteredActions(context);
      } else {
        return _buildRegisterAction(context);
      }
    }

    return const SizedBox.shrink();
  }

  Widget _buildCoordinatorActions(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QRDisplayScreen(
                missionId: mission.id,
                missionTitle: mission.title,
              ),
            ),
          );
        },
        icon: const Icon(Icons.qr_code, size: 20),
        label: const Text('Show QR Code'),
      ),
    );
  }

  Widget _buildRegisteredActions(BuildContext context) {
    final bool isCompleted = mission.registrationStatus == 'Completed';
    final bool isCheckedIn = mission.registrationStatus == 'CheckedIn';

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 3,
              child: SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: (isCompleted || isCheckedIn)
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CheckInScreen(
                                missionId: mission.id,
                                missionTitle: mission.title,
                                missionGps: mission.locationGps ?? '',
                              ),
                            ),
                          );
                        },
                  icon: Icon(
                    isCompleted ? Icons.verified : Icons.check_circle_outline,
                    size: 20,
                  ),
                  label: Text(
                    isCompleted
                        ? 'Mission Completed'
                        : isCheckedIn
                        ? 'Already Checked In'
                        : 'Check In',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    // Open map
                  },
                  child: const Icon(Icons.map_outlined, size: 20),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: Consumer<MissionProvider>(
            builder: (context, provider, _) {
              return OutlinedButton(
                onPressed: () => _cancelRegistration(context, provider),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.terracotta,
                  side: const BorderSide(color: AppTheme.terracotta, width: 2),
                ),
                child: const Text('Cancel Registration'),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterAction(BuildContext context) {
    return Consumer<MissionProvider>(
      builder: (context, provider, _) {
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: isFull ? null : () => _register(context, provider),
            child: Text(isFull ? 'Mission Full' : 'Register for Mission'),
          ),
        );
      },
    );
  }

  Future<void> _register(BuildContext context, MissionProvider provider) async {
    HapticFeedback.mediumImpact();
    try {
      await provider.toggleRegistration(mission.id, false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [Text('✓'), SizedBox(width: 12), Text('Registered!')],
            ),
            backgroundColor: AppTheme.forest,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.terracotta,
          ),
        );
      }
    }
  }

  Future<void> _cancelRegistration(
    BuildContext context,
    MissionProvider provider,
  ) async {
    HapticFeedback.lightImpact();
    try {
      await provider.toggleRegistration(mission.id, true);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Text('✕'),
                SizedBox(width: 12),
                Text('Registration cancelled'),
              ],
            ),
            backgroundColor: AppTheme.ink,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.terracotta,
          ),
        );
      }
    }
  }
}
