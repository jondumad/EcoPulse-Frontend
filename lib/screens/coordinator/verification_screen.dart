import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';

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
      setState(() {
        _pending = pending;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load: $e'),
            backgroundColor: Colors.red,
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
                  ? Colors.green
                  : Colors.orange,
            ),
          );
          // Refresh own profile just in case, or if coordinator gets points too
          Provider.of<AuthProvider>(context, listen: false).refreshProfile();
        }
        _loadPending();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pending.isEmpty
          ? const Center(child: Text('No pending verifications'))
          : RefreshIndicator(
              onRefresh: _loadPending,
              child: ListView.builder(
                itemCount: _pending.length,
                itemBuilder: (context, index) {
                  final item = _pending[index];
                  final user = item['user'];
                  final mission = item['mission'];
                  final hours = item['totalHours'] ?? 0.0;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      title: Text(user['name']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Mission: ${mission['title']}'),
                          Text('Hours: ${hours.toStringAsFixed(1)}'),
                          Text('Points: ${mission['pointsValue']}'),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () =>
                                _handleVerify(item['id'], 'Rejected'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () =>
                                _handleVerify(item['id'], 'Verified'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
