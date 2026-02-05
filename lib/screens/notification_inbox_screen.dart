import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../services/mission_service.dart';
import 'volunteer/mission_detail_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/eco_app_bar.dart';
import 'package:intl/intl.dart';

class NotificationInboxScreen extends StatefulWidget {
  const NotificationInboxScreen({super.key});

  @override
  State<NotificationInboxScreen> createState() =>
      _NotificationInboxScreenState();
}

class _NotificationInboxScreenState extends State<NotificationInboxScreen> {
  final NotificationService _notificationService = NotificationService();
  final MissionService _missionService = MissionService();
  late Future<List<NotificationModel>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _notificationsFuture = _notificationService.getNotifications();
  }

  void _refreshNotifications() {
    setState(() {
      _notificationsFuture = _notificationService.getNotifications();
    });
  }

  Future<void> _handleNotificationTap(NotificationModel notification) async {
    // 1. Mark as read if unread
    if (!notification.isRead) {
      try {
        await _notificationService.markAsRead(notification.id);
        _refreshNotifications();
      } catch (e) {
        debugPrint('Error marking notification as read: $e');
      }
    }

    // 2. Navigate to related mission if applicable
    if (notification.relatedId != null) {
      if (notification.type == 'points_awarded' ||
          notification.type == 'mission_reminder' ||
          notification.type == 'emergency_mission') {
        // Show loading dialog
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(color: AppTheme.forest),
          ),
        );

        try {
          final mission = await _missionService.getMissionById(
            notification.relatedId!,
          );
          if (!mounted) return;
          Navigator.pop(context); // Remove loading

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MissionDetailScreen(mission: mission),
            ),
          );
        } catch (e) {
          if (!mounted) return;
          Navigator.pop(context); // Remove loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not load mission details: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.clay,
      appBar: EcoAppBar(
        height: 100,
        titleWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ALERTS & UPDATES',
              style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.ink.withValues(alpha: 0.6),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Notifications',
              style: AppTheme.lightTheme.textTheme.displayLarge,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, color: AppTheme.ink),
            onPressed: () async {
              await _notificationService.markAllAsRead();
              _refreshNotifications();
            },
            tooltip: 'Mark all as read',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<NotificationModel>>(
        future: _notificationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.forest),
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_outlined,
                    size: 64,
                    color: const Color(0xFF94A3B8),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => _refreshNotifications(),
            color: AppTheme.forest,
            child: ListView.separated(
              itemCount: notifications.length,
              padding: const EdgeInsets.all(16),
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _buildNotificationCard(notification);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    return InkWell(
      onTap: () => _handleNotificationTap(notification),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead
              ? Colors.white.withValues(alpha: 0.5)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notification.isRead
                ? Colors.transparent
                : AppTheme.forest.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.ink.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIcon(notification.type, notification.isRead),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: AppTheme.lightTheme.textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: notification.isRead
                                    ? FontWeight.w600
                                    : FontWeight.w800,
                                color: AppTheme.ink,
                              ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.forest,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.ink.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('MMM d, h:mm a').format(notification.createdAt),
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF94A3B8),
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

  Widget _buildIcon(String type, bool isRead) {
    IconData iconData;
    Color color;

    switch (type) {
      case 'points_awarded':
        iconData = Icons.stars;
        color = Colors.amber;
        break;
      case 'mission_reminder':
        iconData = Icons.timer_outlined;
        color = AppTheme.forest;
        break;
      case 'badge_earned':
        iconData = Icons.emoji_events;
        color = Colors.orange;
        break;
      case 'emergency_mission':
        iconData = Icons.emergency_share;
        color = Colors.red;
        break;
      default:
        iconData = Icons.notifications_outlined;
        color = const Color(0xFF94A3B8);
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isRead ? 0.1 : 0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: color, size: 20),
    );
  }
}
