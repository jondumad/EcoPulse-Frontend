import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/formatters.dart';
import '../../providers/mission_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../models/mission_model.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/eco_pulse_widgets.dart';
import '../../widgets/atoms/eco_button.dart';
import '../../widgets/eco_info_card.dart';
// ── Componentised sub-widgets ───────────────────────────────────────────────
import '../../widgets/mission_detail/mission_detail_hero.dart';
import '../../widgets/mission_detail/mission_detail_stats.dart';
import '../../widgets/mission_detail/mission_detail_actions.dart';
import '../../widgets/mission_detail/mission_detail_map.dart';
import 'check_in_screen.dart';
import 'mission_success_summary.dart';
import '../coordinator/qr_display.dart';

class MissionDetailScreen extends StatefulWidget {
  final Mission mission;

  const MissionDetailScreen({super.key, required this.mission});

  @override
  State<MissionDetailScreen> createState() => _MissionDetailScreenState();
}

class _MissionDetailScreenState extends State<MissionDetailScreen>
    with TickerProviderStateMixin {
  bool _isDescriptionExpanded = false;
  late AnimationController _tiltController;
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  bool _isCheckingOut = false;

  @override
  void initState() {
    super.initState();
    _tiltController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final attendance = Provider.of<AttendanceProvider>(
        context,
        listen: false,
      ).currentAttendance;

      if (attendance != null &&
          attendance['missionId'] == widget.mission.id &&
          attendance['checkInTime'] != null) {
        final checkInTime = DateTime.parse(attendance['checkInTime']);
        if (mounted) {
          setState(() {
            _elapsed = DateTime.now().difference(checkInTime);
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tiltController.dispose();
    super.dispose();
  }

  String _getCategoryIcon(Mission mission, String categoryName) {
    if (mission.categories.isNotEmpty) {
      final category = mission.categories.firstWhere(
        (cat) => cat.name == categoryName,
        orElse: () => mission.categories.first,
      );
      return category.icon;
    }
    return '📋';
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final missionProvider = context.watch<MissionProvider>();

    // Always pull the freshest copy from the provider for reactive updates
    final currentMission = missionProvider.missions.firstWhere(
      (m) => m.id == widget.mission.id,
      orElse: () => widget.mission,
    );

    final attendanceProvider = context.watch<AttendanceProvider>();
    final attendance = attendanceProvider.currentAttendance;
    final isCheckedIn =
        currentMission.registrationStatus == 'CheckedIn' ||
        (attendance != null &&
            attendance['missionId'] == currentMission.id &&
            attendance['checkOutTime'] == null);

    final isCompleted = currentMission.registrationStatus == 'Completed';

    final isFull =
        currentMission.maxVolunteers != null &&
        currentMission.currentVolunteers >= currentMission.maxVolunteers!;

    final isEnded =
        currentMission.status == 'Completed' ||
        currentMission.status == 'Cancelled';

    return Scaffold(
      backgroundColor: AppTheme.clay,
      body: Stack(
        children: [
          SafeArea(
            child: Stack(
              children: [
                // ── Scrollable Content ────────────────────────────────────
                Column(
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(16, 80, 16, 60),
                            child: Column(
                              children: [
                                if (isEnded) ...[
                                  Container(
                                    width: double.infinity,
                                    margin: const EdgeInsets.only(bottom: 16),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.ink,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.info_outline,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            currentMission.status == 'Cancelled'
                                                ? 'This mission has been cancelled.'
                                                : 'This mission has ended. Actions are no longer available.',
                                            style: AppTheme
                                                .lightTheme
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else
                                  const SizedBox(height: 0),
                                _MissionCard(
                                  mission: currentMission,
                                  isDescriptionExpanded: _isDescriptionExpanded,
                                  onDescriptionToggle: () {
                                    setState(() {
                                      _isDescriptionExpanded =
                                          !_isDescriptionExpanded;
                                    });
                                  },
                                  categoryIcon: _getCategoryIcon(
                                    currentMission,
                                    currentMission.categories.isNotEmpty
                                        ? currentMission.categories.first.name
                                        : '',
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),

                          // ── Floating Action Buttons ───────────────────
                          Positioned(
                            right: 16,
                            bottom: 16,
                            child: MissionDetailActions(
                              mission: currentMission,
                              userRole: user?.role,
                              isFull: isFull,
                              isEnded: isEnded,
                              isCheckedIn: isCheckedIn,
                              isCompleted: isCompleted,
                              isCheckingOut: _isCheckingOut,
                              onCheckout: () async {
                                setState(() => _isCheckingOut = true);
                                try {
                                  final attendanceProvider =
                                      Provider.of<AttendanceProvider>(
                                        context,
                                        listen: false,
                                      );
                                  await attendanceProvider.checkOut(
                                    currentMission.id,
                                  );
                                  if (context.mounted) {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            MissionSuccessSummaryScreen(
                                              missionTitle:
                                                  currentMission.title,
                                              duration: _elapsed,
                                              pointsEarned:
                                                  currentMission.pointsValue,
                                            ),
                                      ),
                                    );
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
                                } finally {
                                  if (mounted) {
                                    setState(() => _isCheckingOut = false);
                                  }
                                }
                              },
                            ),
                          ),

                          // ── Live check-in timer badge ─────────────────
                          if (currentMission.registrationStatus == 'CheckedIn')
                            Positioned(
                              top: 96,
                              right: 24,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.violet,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.violet.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.timer_outlined,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      EcoFormatters.formatTimerDuration(
                                        _elapsed,
                                      ),
                                      style: GoogleFonts.jetBrainsMono(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                // ── Floating Top Navigation Bar ───────────────────────────
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Padding(
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

// ─────────────────────────────────────────────────────────────────────────────
// Top Navigation Button
// ─────────────────────────────────────────────────────────────────────────────

class _TopButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _TopButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return EcoPulseButton(
      label: '',
      icon: icon,
      variant: EcoButtonVariant.secondary,
      isSmall: true,
      onPressed: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mission Card (container for all sections)
// ─────────────────────────────────────────────────────────────────────────────

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
    final bool isEmergency =
        mission.isEmergency ||
        mission.priority == 'Critical' ||
        mission.priority == 'High';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color.fromRGBO(0, 0, 0, 0.06)),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.04),
                offset: Offset(0, 4),
                blurRadius: 16,
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Extracted: Hero Section ─────────────────────────────
              MissionDetailHero(icon: categoryIcon, title: mission.title),

              // ── Extracted: Quick Stats Grid ─────────────────────────
              MissionDetailStats(mission: mission),

              // Info Items
              _InfoSection(mission: mission),

              // Timeline (Segments)
              if (mission.segments.isNotEmpty)
                _TimelineSection(segments: mission.segments),

              // ── Extracted: Map Quick View ───────────────────────────
              MissionDetailMap(gps: mission.locationGps),

              // Emergency Justification (if applicable)
              if (mission.isEmergency &&
                  mission.emergencyJustification != null &&
                  mission.emergencyJustification!.isNotEmpty)
                EcoInfoCard(
                  title: 'EMERGENCY JUSTIFICATION',
                  content: mission.emergencyJustification!,
                  variant: InfoCardVariant.emergency,
                ),

              // Coordinator's Note (Manual Overrides)
              if (mission.overrideReason != null &&
                  mission.overrideReason!.isNotEmpty)
                EcoInfoCard(
                  title: "COORDINATOR'S NOTE",
                  content: mission.overrideReason!,
                  variant: InfoCardVariant.note,
                ),

              // Description
              _ExpandableDescription(
                description: mission.description,
                isExpanded: isDescriptionExpanded,
                onToggle: onDescriptionToggle,
              ),
            ],
          ),
        ),

        // Emergency left-edge indicator
        if (isEmergency)
          Positioned(
            left: 0,
            top: 40,
            bottom: 40,
            width: 5,
            child: Container(
              decoration: const BoxDecoration(
                color: AppTheme.terracotta,
                borderRadius: BorderRadius.horizontal(
                  right: Radius.circular(3),
                ),
              ),
            ),
          ),

        // Registration status stamp
        if (mission.isRegistered)
          Positioned(
            top: -20,
            right: -8,
            child: _StatusStamp(
              status: mission.registrationStatus ?? 'Registered',
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status Stamp
// ─────────────────────────────────────────────────────────────────────────────

class _StatusStamp extends StatelessWidget {
  final String status;
  const _StatusStamp({required this.status});

  @override
  Widget build(BuildContext context) {
    Color stampColor = AppTheme.forest;
    String displayStatus = 'REGIS-\nTERED';

    if (status == 'Waitlisted') {
      stampColor = AppTheme.violet;
      displayStatus = 'WAIT-\nLISTED';
    } else if (status == 'CheckedIn') {
      stampColor = AppTheme.violet;
      displayStatus = 'CHECKED\nIN';
    } else if (status == 'Completed') {
      stampColor = Colors.orange;
      displayStatus = 'COMPLE-\nTED';
    } else if (status == 'Cancelled') {
      stampColor = AppTheme.terracotta;
      displayStatus = 'CANCEL-\nLED';
    }

    return Transform.rotate(
      angle: 0.2,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: stampColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              offset: Offset(0, 4),
              blurRadius: 8,
            ),
          ],
        ),
        child: Center(
          child: Text(
            displayStatus,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Info Section
// ─────────────────────────────────────────────────────────────────────────────

class _InfoSection extends StatelessWidget {
  final Mission mission;

  const _InfoSection({required this.mission});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, MMMM d, y');
    final timeFormat = DateFormat('h:mm a');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          _buildInfoRow(
            Icons.calendar_today_outlined,
            dateFormat.format(mission.startTime.toLocal()),
            '${timeFormat.format(mission.startTime.toLocal())} - ${timeFormat.format(mission.endTime.toLocal())}',
          ),
          const SizedBox(height: 24),
          _buildInfoRow(
            Icons.location_on_outlined,
            mission.locationName,
            'Check map for exact location',
          ),
          const SizedBox(height: 24),
          _buildInfoRow(
            Icons.person_outline,
            mission.creatorName ?? 'EcoPulse Team',
            'Organizer',
            trailing: (mission.registrationStatus == 'CheckedIn')
                ? IconButton(
                    icon: const Icon(
                      Icons.email_outlined,
                      color: AppTheme.forest,
                    ),
                    onPressed: () async {
                      final uri = Uri.parse(
                        'mailto:?body=Support request for mission: ${mission.title}',
                      );
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                  )
                : null,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String title,
    String subtitle, {
    Widget? trailing,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.clay,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.forest, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppTheme.ink.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Expandable Description
// ─────────────────────────────────────────────────────────────────────────────

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
    final bool isLong =
        description.length > 150 || description.contains('\n\n');

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.clay,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: AppTheme.forest,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'About the Mission',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            description,
            maxLines: isExpanded ? null : 3,
            overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: AppTheme.ink.withValues(alpha: 0.8),
            ),
          ),
          if (isLong)
            TextButton(
              onPressed: onToggle,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
                foregroundColor: AppTheme.forest,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(isExpanded ? 'Read Less' : 'Read More'),
                  const SizedBox(width: 4),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 18,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Timeline Section (Segments)
// ─────────────────────────────────────────────────────────────────────────────

class _TimelineSection extends StatelessWidget {
  final List<MissionSegment> segments;

  const _TimelineSection({required this.segments});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.clay,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.timeline_outlined,
                  color: AppTheme.forest,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Mission Timeline',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: segments.length,
            padding: EdgeInsets.zero,
            itemBuilder: (context, index) {
              return _TimelineItem(
                segment: segments[index],
                isLast: index == segments.length - 1,
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final MissionSegment segment;
  final bool isLast;

  const _TimelineItem({required this.segment, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('h:mm a');
    final now = DateTime.now();
    final bool isLive = now.isAfter(segment.startTime) && now.isBefore(segment.endTime);
    final bool isPast = now.isAfter(segment.endTime);

    return IntrinsicHeight(
      child: Row(
        children: [
          // Timeline indicator
          Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: isLive ? 16 : 12,
                height: isLive ? 16 : 12,
                decoration: BoxDecoration(
                  color: isLive 
                    ? AppTheme.forest 
                    : (isPast ? AppTheme.forest.withValues(alpha: 0.4) : AppTheme.clay),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isLive ? Colors.white : AppTheme.forest.withValues(alpha: 0.2), 
                    width: isLive ? 3 : 2
                  ),
                  boxShadow: isLive ? [
                    BoxShadow(
                      color: AppTheme.forest.withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 2
                    )
                  ] : null,
                ),
                child: isLive ? const Center(
                  child: Icon(Icons.play_arrow, size: 8, color: Colors.white),
                ) : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isPast 
                      ? AppTheme.forest.withValues(alpha: 0.4) 
                      : AppTheme.forest.withValues(alpha: 0.1),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Opacity(
              opacity: isPast ? 0.5 : 1.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            segment.title,
                            style: TextStyle(
                              fontWeight: isLive ? FontWeight.w900 : FontWeight.bold,
                              fontSize: 15,
                              color: isLive ? AppTheme.forest : AppTheme.ink,
                            ),
                          ),
                          if (isLive) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.forest,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'LIVE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        '${timeFormat.format(segment.startTime)} - ${timeFormat.format(segment.endTime)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isLive ? FontWeight.w800 : FontWeight.w600,
                          color: isLive ? AppTheme.forest : AppTheme.forest.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                  if (segment.description != null &&
                      segment.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      segment.description!,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.ink.withValues(alpha: 0.6),
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
