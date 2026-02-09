import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/eco_pulse_widgets.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  List<dynamic> _pending = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPending();
  }

  Future<void> _loadPending() async {
    setState(() => _isLoading = true);
    try {
      final pending = await Provider.of<AttendanceProvider>(
        context,
        listen: false,
      ).getPendingVerifications();
      if (mounted) {
        setState(() {
          _pending = pending;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load: $e'),
            backgroundColor: EcoColors.terracotta,
          ),
        );
      }
    }
  }

  Future<void> _handleVerify(int id, String status) async {
    try {
      final success = await Provider.of<AttendanceProvider>(
        context,
        listen: false,
      ).verifyAttendance(id, status);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Attendance $status'),
              backgroundColor: status == 'Verified'
                  ? EcoColors.forest
                  : EcoColors.terracotta,
            ),
          );
          Provider.of<AuthProvider>(context, listen: false).refreshProfile();
        }
        _loadPending();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: EcoColors.terracotta,
          ),
        );
      }
    }
  }

  Future<void> _handleVerifyAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verify All?'),
        content: Text('This will mark all ${_pending.length} items as Verified. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Verify All')),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);
      int successCount = 0;
      final provider = Provider.of<AttendanceProvider>(context, listen: false);
      
      for (var item in _pending) {
        try {
          final success = await provider.verifyAttendance(item['id'], 'Verified');
          if (success) successCount++;
        } catch (e) {
          debugPrint('Error verifying item ${item['id']}: $e');
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully verified $successCount items')),
        );
        _loadPending();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return EcoPulseLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_pending.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_pending.length} PENDING ITEMS',
                    style: EcoText.monoSM(context),
                  ),
                  TextButton.icon(
                    onPressed: _handleVerifyAll,
                    icon: const Icon(Icons.done_all, size: 18),
                    label: const Text('VERIFY ALL'),
                    style: TextButton.styleFrom(
                      foregroundColor: EcoColors.forest,
                      textStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: EcoColors.forest),
                  )
                : _pending.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.verified_outlined,
                          size: 64,
                          color: EcoColors.forest.withValues(alpha: 0.2),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'All caught up!',
                          style: EcoText.displayMD(context).copyWith(
                            color: EcoColors.forest.withValues(alpha: 0.5),
                          ),
                        ),
                        Text(
                          'No pending verifications found.',
                          style: EcoText.bodyMD(context),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    color: EcoColors.forest,
                    onRefresh: _loadPending,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      itemCount: _pending.length,
                      itemBuilder: (context, index) {
                        final item = _pending[index];
                        final user = item['user'];
                        final mission = item['mission'];
                        final hours = item['totalHours'] ?? 0.0;

                        return Padding(
                          key: ValueKey('verification_${item['id']}'),
                          padding: const EdgeInsets.only(bottom: 24.0),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              EcoPulseCard(
                                variant: CardVariant.paper,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                user['name'],
                                                style: EcoText.displayMD(
                                                  context,
                                                ),
                                              ),
                                              Text(
                                                user['email'],
                                                style: EcoText.bodyMD(context)
                                                    .copyWith(
                                                      fontSize: 12,
                                                      color: EcoColors.ink
                                                          .withValues(
                                                            alpha: 0.6,
                                                          ),
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: EcoColors.clay,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            '${hours.toStringAsFixed(1)} HRS',
                                            style: EcoText.monoSM(context),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 32),
                                    _buildInfoRow(
                                      Icons.assignment_outlined,
                                      'Mission',
                                      mission['title'],
                                    ),
                                    const SizedBox(height: 12),
                                    _buildInfoRow(
                                      Icons.stars_outlined,
                                      'Reward',
                                      '${mission['pointsValue']} Points',
                                    ),
                                    const SizedBox(height: 24),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: EcoPulseButton(
                                            label: 'REJECT',
                                            isPrimary: false,
                                            onPressed: () => _handleVerify(
                                              item['id'],
                                              'Rejected',
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: EcoPulseButton(
                                            label: 'VERIFY',
                                            icon: Icons.check,
                                            onPressed: () => _handleVerify(
                                              item['id'],
                                              'Verified',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Positioned(
                                top: -10,
                                right: -5,
                                child: EcoPulseTag(
                                  label: 'Pending Review',
                                  isRotated: true,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: EcoColors.forest.withValues(alpha: 0.6)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: EcoText.monoSM(
            context,
          ).copyWith(fontSize: 10, color: EcoColors.ink.withValues(alpha: 0.5)),
        ),
        Expanded(
          child: Text(
            value,
            style: EcoText.bodyMD(
              context,
            ).copyWith(fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
