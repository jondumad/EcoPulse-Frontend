import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../providers/attendance_provider.dart';
import '../../widgets/eco_pulse_widgets.dart';
import '../../widgets/eco_app_bar.dart';
import '../../theme/app_theme.dart';

class QRDisplayScreen extends StatefulWidget {
  final int missionId;
  final String missionTitle;
  final DateTime? activeUntil;

  const QRDisplayScreen({
    super.key,
    required this.missionId,
    required this.missionTitle,
    this.activeUntil,
  });

  @override
  State<QRDisplayScreen> createState() => _QRDisplayScreenState();
}

class _QRDisplayScreenState extends State<QRDisplayScreen> {
  String? _qrToken;
  Timer? _timer;
  int _secondsLeft = 60;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (_isExpired()) {
      _isLoading = false;
      _error = 'Mission has ended';
    } else {
      _fetchQR();
    }
  }

  bool _isExpired() {
    if (widget.activeUntil == null) return false;
    return DateTime.now().isAfter(widget.activeUntil!);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchQR() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final attendanceProvider = Provider.of<AttendanceProvider>(
        context,
        listen: false,
      );
      final result = await attendanceProvider.getQRCode(widget.missionId);
      if (mounted) {
        setState(() {
          _qrToken = result['qrToken'];
          _secondsLeft = 60;
          _isLoading = false;
        });
        _startTimer();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        if (mounted) {
          setState(() {
            _secondsLeft--;
          });
        }
      } else {
        _fetchQR();
      }
    });
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
              'MISSION AUTHENTICATION',
              style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.ink.withValues(alpha: 0.6),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Mission QR Code',
              style: AppTheme.lightTheme.textTheme.displayLarge,
            ),
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.missionTitle,
                style: EcoText.displayMD(context),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Scan to check in',
                textAlign: TextAlign.center,
                style: EcoText.bodyMD(context).copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 40),
              if (_isLoading)
                const CircularProgressIndicator(color: EcoColors.forest)
              else if (_isExpired())
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_clock,
                        size: 64,
                        color: AppTheme.ink.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Mission Ended',
                        style: AppTheme.lightTheme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      const Text('QR checking is no longer available'),
                    ],
                  ),
                )
              else if (_error != null)
                Column(
                  children: [
                    Text(
                      'Error: $_error',
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 10),
                    EcoPulseButton(label: 'Retry', onPressed: _fetchQR),
                  ],
                )
              else if (_qrToken != null)
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    EcoPulseCard(
                      variant: CardVariant.paper,
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          QrImageView(
                            data: _qrToken!,
                            version: QrVersions.auto,
                            size: 250.0,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: EcoColors.forest,
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: EcoColors.forest,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text('REFRESH IN', style: EcoText.monoSM(context)),
                          Text(
                            '${_secondsLeft ~/ 60}:${(_secondsLeft % 60).toString().padLeft(2, '0')}',
                            style: EcoText.displayMD(context),
                          ),
                        ],
                      ),
                    ),
                    const Positioned(
                      top: -10,
                      right: 20,
                      child: EcoPulseTag(label: 'LIVE TOKEN', isRotated: true),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}