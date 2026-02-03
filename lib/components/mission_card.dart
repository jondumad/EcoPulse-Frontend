import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/mission_model.dart';
import '../theme/app_theme.dart';
import '../screens/volunteer/mission_detail_screen.dart';
import 'paper_card.dart';

class MissionCard extends StatelessWidget {
  final Mission mission;

  const MissionCard({super.key, required this.mission});

  @override
  Widget build(BuildContext context) {
    return PaperCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MissionDetailScreen(mission: mission),
          ),
        );
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      mission.title,
                      style: AppTheme.lightTheme.textTheme.displaySmall
                          ?.copyWith(fontSize: 20), // Slightly smaller for list
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                  if (mission.isEmergency)
                    Transform.rotate(
                      angle: 0.05,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.terracotta,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              offset: Offset(1, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                        child: Text(
                          'URGENT',
                          style: AppTheme.lightTheme.textTheme.labelSmall
                              ?.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: AppTheme.ink,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      mission.locationName,
                      style: AppTheme.lightTheme.textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: AppTheme.ink,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM dd, HH:mm').format(mission.startTime),
                    style: AppTheme.lightTheme.textTheme.bodyMedium,
                  ),
                ],
              ),
              if (mission.startTime.difference(DateTime.now()).inHours.abs() <
                      24 &&
                  mission.startTime.isAfter(DateTime.now()))
                _CountdownTimer(targetDate: mission.startTime),
              const SizedBox(height: 16),
              Row(
                children: [
                  ...mission.categories
                      .take(2)
                      .map((cat) => CategoryTag(category: cat)),
                  const Spacer(),
                  Text(
                    '+${mission.pointsValue} PTS',
                    style:
                        AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                          color: AppTheme.forest,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'JetBrains Mono',
                        ) ??
                        const TextStyle(
                          color: AppTheme.forest,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: mission.maxVolunteers != null
                      ? mission.currentVolunteers / mission.maxVolunteers!
                      : 0.1, // Show a bit if null
                  backgroundColor: AppTheme.ink.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    mission.isEmergency ? AppTheme.terracotta : AppTheme.forest,
                  ),
                  minHeight: 6,
                ),
              ),
            ],
          ),
          if (mission.isRegistered)
            Positioned(
              top: -8,
              right: -8,
              child: _StatusBadge(
                status: mission.registrationStatus ?? 'Registered',
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color badgeColor = AppTheme.forest;
    String label = 'REGISTERED';

    if (status == 'CheckedIn') {
      badgeColor = AppTheme.violet;
      label = 'CHECKED IN';
    } else if (status == 'Completed') {
      badgeColor = Colors.orange;
      label = 'COMPLETED';
    }

    return Transform.rotate(
      angle: -0.1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: badgeColor,
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              offset: Offset(1, 1),
              blurRadius: 2,
            ),
          ],
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
            color: Colors.white,
            fontSize: 8,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
            fontFamily: 'JetBrains Mono',
          ),
        ),
      ),
    );
  }
}

class CategoryTag extends StatelessWidget {
  final Category category;

  const CategoryTag({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.ink.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.ink.withValues(alpha: 0.1)),
      ),
      child: Text(
        category.name.toUpperCase(),
        style: const TextStyle(
          color: AppTheme.ink,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          fontFamily: 'JetBrains Mono',
        ),
      ),
    );
  }
}

class _CountdownTimer extends StatefulWidget {
  final DateTime targetDate;
  const _CountdownTimer({required this.targetDate});

  @override
  State<_CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<_CountdownTimer> {
  late Timer _timer;
  late Duration _timeLeft;

  @override
  void initState() {
    super.initState();
    _calculateTime();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _calculateTime(),
    );
  }

  void _calculateTime() {
    final now = DateTime.now();
    setState(() {
      _timeLeft = widget.targetDate.difference(now);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_timeLeft.isNegative) return const SizedBox.shrink();

    final hours = _timeLeft.inHours;
    final minutes = _timeLeft.inMinutes % 60;
    final seconds = _timeLeft.inSeconds % 60;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.terracotta.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.terracotta.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer, size: 12, color: AppTheme.terracotta),
          const SizedBox(width: 6),
          Text(
            'STARTS IN ${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppTheme.terracotta,
              fontFamily: 'JetBrains Mono',
            ),
          ),
        ],
      ),
    );
  }
}
