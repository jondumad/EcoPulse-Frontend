import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/eco_pulse_widgets.dart';
import '../../../models/evaluation_model.dart';
import '../../../services/evaluation_service.dart';
import '../../../providers/auth_provider.dart';
import 'evaluation_modal.dart';

class VolunteerListScreen extends StatefulWidget {
  final int? missionId;
  final String? missionTitle;

  const VolunteerListScreen({super.key, this.missionId, this.missionTitle});

  @override
  State<VolunteerListScreen> createState() => _VolunteerListScreenState();
}

class _VolunteerListScreenState extends State<VolunteerListScreen> with TickerProviderStateMixin {
  late AnimationController _listController;
  List<VolunteerSummary> _volunteers = [];
  List<VolunteerSummary> _filteredVolunteers = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _listController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fetchVolunteers();
  }

  Future<void> _fetchVolunteers() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    try {
      final volunteers = await EvaluationService.getVolunteers(token, missionId: widget.missionId);
      if (mounted) {
        setState(() {
          _volunteers = volunteers;
          _filteredVolunteers = volunteers;
          _isLoading = false;
        });
        _listController.forward();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading volunteers: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _filteredVolunteers = _volunteers
          .where((v) =>
              v.name.toLowerCase().contains(_searchQuery) ||
              v.email.toLowerCase().contains(_searchQuery))
          .toList();
    });
  }

  @override
  void dispose() {
    _listController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.clay,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.clay,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.missionTitle != null 
                        ? 'Impact: ${widget.missionTitle}'
                        : 'Impact Evaluation',
                      style: GoogleFonts.fraunces(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                        color: AppTheme.ink,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Assess the contributions of your field volunteers.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppTheme.ink.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: TextField(
                onChanged: _onSearch,
                decoration: InputDecoration(
                  hintText: 'Search by name or email...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppTheme.inkSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_filteredVolunteers.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.person_search_rounded, size: 64, color: AppTheme.inkTertiary),
                    const SizedBox(height: 16),
                    Text(
                      'No volunteers found',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.inkSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final volunteer = _filteredVolunteers[index];
                    return _VolunteerCard(
                      volunteer: volunteer,
                      index: index,
                      controller: _listController,
                      onTap: () {
                        EvaluationModal.show(context, volunteer, widget.missionId ?? 0);
                      },
                    );
                  },
                  childCount: _filteredVolunteers.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _VolunteerCard extends StatelessWidget {
  final VolunteerSummary volunteer;
  final int index;
  final AnimationController controller;
  final VoidCallback onTap;

  const _VolunteerCard({
    required this.volunteer,
    required this.index,
    required this.controller,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(
        (index * 0.05).clamp(0.0, 1.0),
        (index * 0.05 + 0.5).clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - animation.value)),
          child: Opacity(
            opacity: animation.value,
            child: child,
          ),
        );
      },
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.clay,
                  foregroundImage: NetworkImage(
                    'https://api.dicebear.com/7.x/avataaars/png?seed=${volunteer.name}',
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  volunteer.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${volunteer.totalPoints} PTS',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.forest,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.forest.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Evaluate',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.forest,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
