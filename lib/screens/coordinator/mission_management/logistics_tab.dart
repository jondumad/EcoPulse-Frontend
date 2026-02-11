import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../models/mission_model.dart';
import '../../../../providers/attendance_provider.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/eco_pulse_widgets.dart';
import 'mission_map_preview_screen.dart';

class LogisticsTab extends StatefulWidget {
  final Mission mission;

  const LogisticsTab({super.key, required this.mission});

  @override
  State<LogisticsTab> createState() => _LogisticsTabState();
}

class _LogisticsTabState extends State<LogisticsTab> {
  String? _qrToken;
  Timer? _qrTimer;
  int _qrSecondsLeft = 60;
  bool _isLoadingQR = false;
  String? _qrError;

  @override
  void dispose() {
    _qrTimer?.cancel();
    super.dispose();
  }

  bool _isExpired() {
    return DateTime.now().isAfter(widget.mission.endTime);
  }

  Future<void> _fetchQR() async {
    if (!mounted) return;
    if (_isExpired()) {
      setState(() {
        _qrError = 'Mission has ended';
        _isLoadingQR = false;
      });
      return;
    }

    setState(() {
      _isLoadingQR = true;
      _qrError = null;
    });

    try {
      final attendanceProvider = Provider.of<AttendanceProvider>(
        context,
        listen: false,
      );
      final result = await attendanceProvider.getQRCode(widget.mission.id);
      if (mounted) {
        setState(() {
          _qrToken = result['qrToken'];
          _qrSecondsLeft = 60;
          _isLoadingQR = false;
        });
        _startQRTimer();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _qrError = e.toString();
          _isLoadingQR = false;
        });
      }
    }
  }

  void _startQRTimer() {
    _qrTimer?.cancel();
    _qrTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_qrSecondsLeft > 0) {
        setState(() => _qrSecondsLeft--);
      } else {
        timer.cancel();
        _fetchQR();
      }
    });
  }

  Future<void> _openMap() async {
    final query = Uri.encodeComponent(widget.mission.locationName);
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _showFullScreenQR() {
    if (_qrToken == null) return;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss QR',
      barrierColor: EcoColors.ink.withValues(alpha: 0.85),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            decoration: BoxDecoration(
              color: EcoColors.clay,
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pass Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: EcoColors.forest.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_user_rounded, size: 14, color: EcoColors.forest),
                        const SizedBox(width: 8),
                        Text(
                          'SECURE CHECK-IN PASS',
                          style: EcoText.monoSM(context).copyWith(
                            color: EcoColors.forest,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    widget.mission.title,
                    style: EcoText.displayMD(context).copyWith(fontSize: 24),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.mission.locationName.toUpperCase(),
                    style: EcoText.monoSM(context).copyWith(
                      color: EcoColors.ink.withValues(alpha: 0.4),
                      letterSpacing: 1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // The QR "Vault"
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: EcoColors.ink.withValues(alpha: 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: _qrToken!,
                      size: MediaQuery.of(context).size.width * 0.55,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: EcoColors.ink,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: EcoColors.ink,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Security Footer
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'TOKEN ROTATION', 
                          style: EcoText.monoSM(context).copyWith(
                            color: EcoColors.ink.withValues(alpha: 0.4),
                            fontWeight: FontWeight.w800,
                            fontSize: 8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _DialogTimer(secondsProvider: () => _qrSecondsLeft),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'TAP ANYWHERE TO DISMISS',
                      style: EcoText.monoSM(context).copyWith(
                        color: EcoColors.ink.withValues(alpha: 0.3),
                        fontSize: 9,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: FadeTransition(
            opacity: anim1,
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AttendanceProvider>(
      builder: (context, attendanceProvider, _) {
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const EcoSectionHeader(title: 'LIVE ATTENDANCE'),
            const SizedBox(height: 16),
            _buildAttendanceSnapshot(),
            
            const SizedBox(height: 40),
            const EcoSectionHeader(title: 'CHECK-IN QR CODE'),
            const SizedBox(height: 16),
            _buildQRSection(),
            
            const SizedBox(height: 40),
            const EcoSectionHeader(title: 'OPERATIONAL WINDOW'),
            const SizedBox(height: 16),
            _buildTimelineCard(),
            
            const SizedBox(height: 40),
            const EcoSectionHeader(title: 'LOGISTICS & LOCATION'),
            const SizedBox(height: 16),
            _buildLocationCard(),
            const SizedBox(height: 100),
          ],
        );
      }
    );
  }

  Widget _buildAttendanceSnapshot() {
    // Note: In a real scenario, we'd fetch these specific counts from the provider
    // For now, we'll use the mission's volunteer count as 'Registered'
    final registered = widget.mission.currentVolunteers;
    final max = widget.mission.maxVolunteers ?? 0;
    
    return EcoPulseCard(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          EcoStatItem(
            label: 'Registered', 
            value: registered.toString(),
            color: EcoColors.ink,
          ),
          Container(width: 1, height: 40, color: EcoColors.clay),
          EcoStatItem(
            label: 'Checked In', 
            value: '0', // This would come from dynamic attendance state
            color: EcoColors.forest,
          ),
          Container(width: 1, height: 40, color: EcoColors.clay),
          EcoStatItem(
            label: 'Capacity', 
            value: max > 0 ? '${((registered / max) * 100).toInt()}%' : '100%',
            color: EcoColors.violet,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard() {
    final start = widget.mission.startTime;
    final end = widget.mission.endTime;
    final duration = end.difference(start);
    final isLive = DateTime.now().isAfter(start) && DateTime.now().isBefore(end);
    
    return EcoPulseCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              _TimeBox(label: 'Starts', time: start),
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Divider(thickness: 2, color: EcoColors.clay),
                ),
              ),
              _TimeBox(label: 'Ends', time: end),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isLive ? EcoColors.forest.withValues(alpha: 0.05) : EcoColors.clay,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  isLive ? Icons.play_circle_fill_rounded : Icons.timer_outlined,
                  color: isLive ? EcoColors.forest : EcoColors.ink.withValues(alpha: 0.4),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLive ? 'MISSION IS LIVE' : 'TOTAL DURATION',
                      style: EcoText.monoSM(context).copyWith(
                        fontWeight: FontWeight.w800,
                        color: isLive ? EcoColors.forest : EcoColors.ink.withValues(alpha: 0.4),
                      ),
                    ),
                    Text(
                      '${duration.inHours}h ${duration.inMinutes % 60}m',
                      style: EcoText.bodyBoldMD(context),
                    ),
                  ],
                ),
                const Spacer(),
                if (isLive)
                  const EcoPulseTag(label: 'IN PROGRESS', color: EcoColors.forest),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRSection() {
    if (_qrToken == null && !_isLoadingQR && _qrError == null) {
      return EcoPulseButton(
        label: 'Generate Check-in QR',
        icon: Icons.qr_code_scanner_rounded,
        onPressed: _fetchQR,
        width: double.infinity,
      );
    }

    if (_isLoadingQR) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: EcoColors.ink.withValues(alpha: 0.05)),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: EcoColors.forest),
        ),
      );
    }

    if (_isExpired()) {
      return EcoPulseCard(
        child: Column(
          children: [
            Icon(
              Icons.lock_clock_rounded,
              size: 48,
              color: EcoColors.ink.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'Mission Ended',
              style: EcoText.bodyBoldMD(context),
            ),
            const SizedBox(height: 8),
            Text(
              'QR verification is only available during the mission window.',
              textAlign: TextAlign.center,
              style: EcoText.bodySM(context).copyWith(
                color: EcoColors.ink.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    if (_qrError != null) {
      return EcoPulseCard(
        child: Column(
          children: [
            const Icon(Icons.error_outline_rounded, color: EcoColors.terracotta, size: 32),
            const SizedBox(height: 12),
            Text(
              'Failed to generate token',
              style: EcoText.bodyBoldMD(context),
            ),
            const SizedBox(height: 4),
            Text(
              _qrError!,
              style: EcoText.bodySM(context).copyWith(color: EcoColors.terracotta),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            EcoPulseButton(label: 'Try Again', isSmall: true, onPressed: _fetchQR),
          ],
        ),
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        EcoPulseCard(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton.filledTonal(
                  onPressed: _showFullScreenQR,
                  style: IconButton.styleFrom(
                    backgroundColor: EcoColors.forest.withValues(alpha: 0.1),
                    foregroundColor: EcoColors.forest,
                  ),
                  icon: const Icon(Icons.fullscreen_rounded, size: 24),
                  tooltip: 'View Fullscreen',
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: EcoColors.clay),
                ),
                child: QrImageView(
                  data: _qrToken!,
                  size: 180,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: EcoColors.forest,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: EcoColors.forest,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'TOKEN REFRESH', 
                style: EcoText.monoSM(context).copyWith(
                  color: EcoColors.ink.withValues(alpha: 0.4),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_qrSecondsLeft ~/ 60}:${(_qrSecondsLeft % 60).toString().padLeft(2, '0')}',
                style: EcoText.displayMD(context).copyWith(
                  color: _qrSecondsLeft < 10 ? EcoColors.terracotta : EcoColors.forest,
                ),
              ),
            ],
          ),
        ),
        const Positioned(
          top: -12,
          left: 12,
          child: EcoPulseTag(label: 'LIVE AUTH', isRotated: true),
        ),
      ],
    );
  }

  Widget _buildLocationCard() {
    return EcoPulseCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            Icons.place_rounded, 
            'Meeting Point', 
            widget.mission.locationName,
            onTap: _openMap,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: EcoColors.clay),
          ),
          _buildInfoRow(
            Icons.gps_fixed_rounded, 
            'Coordinates', 
            widget.mission.locationGps ?? 'Automatic GPS Not Set',
          ),
          const SizedBox(height: 24),
          EcoPulseButton(
            label: 'Preview on EcoMap',
            icon: Icons.map_outlined,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MissionMapPreviewScreen(mission: widget.mission),
                ),
              );
            },
            width: double.infinity,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: EcoColors.forest.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: EcoColors.forest),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(), 
                    style: EcoText.monoSM(context).copyWith(
                      color: EcoColors.ink.withValues(alpha: 0.4),
                      fontWeight: FontWeight.w800,
                      fontSize: 9,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value, 
                    style: EcoText.bodyBoldMD(context).copyWith(
                      color: EcoColors.ink,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.arrow_outward_rounded, 
                size: 16, 
                color: EcoColors.ink.withValues(alpha: 0.2)
              ),
          ],
        ),
      ),
    );
  }
}

class _DialogTimer extends StatefulWidget {
  final int Function() secondsProvider;
  const _DialogTimer({required this.secondsProvider});

  @override
  State<_DialogTimer> createState() => _DialogTimerState();
}

class _DialogTimerState extends State<_DialogTimer> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seconds = widget.secondsProvider();
    return Text(
      '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}',
      style: EcoText.displayMD(context).copyWith(
        color: seconds < 10 ? EcoColors.terracotta : EcoColors.forest,
      ),
    );
  }
}

class _TimeBox extends StatelessWidget {
  final String label;
  final DateTime time;

  const _TimeBox({required this.label, required this.time});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: EcoText.monoSM(context).copyWith(
            fontSize: 8,
            color: EcoColors.ink.withValues(alpha: 0.4),
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          DateFormat('HH:mm').format(time),
          style: EcoText.bodyBoldMD(context).copyWith(fontSize: 18),
        ),
        Text(
          DateFormat('MMM d').format(time),
          style: EcoText.bodySM(context).copyWith(fontSize: 10),
        ),
      ],
    );
  }
}
