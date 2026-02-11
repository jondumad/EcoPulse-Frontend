import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/user_service.dart';
import '../providers/mission_provider.dart';
import '../theme/app_theme.dart';
import 'eco_pulse_widgets.dart';

class UserSearchModal extends StatefulWidget {
  final int missionId;
  final int targetRoleId; // 3 for Volunteer, 2 for Coordinator
  final String title;
  final Future<void> Function(int userId)? onInvite;

  const UserSearchModal({
    super.key, 
    required this.missionId, 
    this.targetRoleId = 3,
    this.title = 'Invite Volunteers',
    this.onInvite,
  });

  static void show(
    BuildContext context, 
    int missionId, {
    int targetRoleId = 3,
    String title = 'Invite Volunteers',
    Future<void> Function(int userId)? onInvite,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UserSearchModal(
        missionId: missionId,
        targetRoleId: targetRoleId,
        title: title,
        onInvite: onInvite,
      ),
    );
  }

  @override
  State<UserSearchModal> createState() => _UserSearchModalState();
}

class _UserSearchModalState extends State<UserSearchModal> {
  final TextEditingController _searchController = TextEditingController();
  final UserService _userService = UserService();
  List<dynamic> _searchResults = [];
  bool _isLoading = false;
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final results = await _userService.getAllUsers(search: query, roleId: widget.targetRoleId);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _handleInvite(int userId) async {
    if (widget.onInvite != null) {
      await widget.onInvite!(userId);
      if (mounted) Navigator.pop(context);
      return;
    }

    try {
      await Provider.of<MissionProvider>(context, listen: false).inviteUser(widget.missionId, userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User invited successfully'), backgroundColor: EcoColors.forest),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: EcoColors.clay,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: EcoText.displayMD(context),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name or email...',
                    prefixIcon: const Icon(Icons.search, color: EcoColors.forest),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: _searchUsers,
                  onChanged: (val) {
                    if (val.length > 2) _searchUsers(val);
                  },
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: EcoColors.forest))
                : _searchResults.isEmpty
                    ? Center(
                        child: Text(
                          _searchController.text.isEmpty ? 'Search for users' : 'No users found',
                          style: EcoText.bodySM(context),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _searchResults.length,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemBuilder: (context, index) {
                          final user = _searchResults[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: EcoColors.forest.withValues(alpha: 0.1),
                                child: Text(
                                  user['name'][0].toUpperCase(),
                                  style: const TextStyle(color: EcoColors.forest, fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(user['name'], style: EcoText.bodyBoldMD(context)),
                              subtitle: Text(user['email'], style: EcoText.bodySM(context)),
                              trailing: EcoPulseButton(
                                label: 'Invite',
                                isSmall: true,
                                onPressed: () => _handleInvite(user['id']),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
